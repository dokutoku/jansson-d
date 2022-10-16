/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.test_dump;


private static import core.memory;
private static import core.stdc.stdio;
private static import core.stdc.string;
private static import core.sys.posix.unistd;
private static import jansson.dump;
private static import jansson.jansson;
private static import jansson.jansson_private;
private static import jansson.load;
private static import jansson.pack_unpack;
private static import jansson.test.util;
private static import jansson.value;

//#if defined(__MINGW32__)
	//#include <fcntl.h>
	//#define pipe(fds) _pipe(fds, 1024, core.stdc.stdio._O_BINARY)
//#endif

extern (C)
pure nothrow @safe @nogc @live
private int encode_null_callback(scope const char* buffer, size_t size, scope void* data)

	do
	{
		return 0;
	}

//encode_null
unittest
{
	jansson.test.util.init_unittest();
	assert(jansson.dump.json_dumps(null, jansson.jansson.JSON_ENCODE_ANY) == null, "json_dumps didn't fail for null");

	assert(jansson.dump.json_dumpb(null, null, 0, jansson.jansson.JSON_ENCODE_ANY) == 0, "json_dumpb didn't fail for null");

	assert(jansson.dump.json_dumpf(null, core.stdc.stdio.stderr, jansson.jansson.JSON_ENCODE_ANY) == -1, "json_dumpf didn't fail for null");

	static if (__traits(compiles, core.sys.posix.unistd.STDERR_FILENO)) {
		assert(jansson.dump.json_dumpfd(null, core.sys.posix.unistd.STDERR_FILENO, jansson.jansson.JSON_ENCODE_ANY) == -1, "json_dumpfd didn't fail for null");
	}

	/* Don't test json_dump_file to avoid creating a file */

	assert(jansson.dump.json_dump_callback(null, &.encode_null_callback, null, jansson.jansson.JSON_ENCODE_ANY) == -1, "json_dump_callback didn't fail for null");
}

//encode_twice
unittest
{
	/* Encode an empty object/array, add an item, encode again */

	jansson.test.util.init_unittest();

	{
		jansson.jansson.json_t* json = jansson.value.json_object();

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		{
			char* result = jansson.dump.json_dumps(json, 0);

			scope (exit) {
				jansson.jansson_private.jsonp_free(result);
			}

			assert((result != null) && (!core.stdc.string.strcmp(result, "{}")), "json_dumps failed");
		}

		jansson.value.json_object_set_new(json, "foo", jansson.value.json_integer(5));

		{
			char* result = jansson.dump.json_dumps(json, 0);

			scope (exit) {
				jansson.jansson_private.jsonp_free(result);
			}

			assert((result != null) && (!core.stdc.string.strcmp(result, "{\"foo\": 5}")), "json_dumps failed");
		}
	}

	{
		jansson.jansson.json_t* json = jansson.value.json_array();

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		{
			char* result = jansson.dump.json_dumps(json, 0);

			scope (exit) {
				jansson.jansson_private.jsonp_free(result);
			}

			assert((result != null) && (!core.stdc.string.strcmp(result, "[]")), "json_dumps failed");
		}

		jansson.value.json_array_append_new(json, jansson.value.json_integer(5));

		{
			char* result = jansson.dump.json_dumps(json, 0);

			scope (exit) {
				jansson.jansson_private.jsonp_free(result);
			}

			assert((result != null) && (!core.stdc.string.strcmp(result, "[5]")), "json_dumps failed");
		}
	}
}

//circular_references
unittest
{
	/*
	 * Construct a JSON object/array with a circular reference:
	 *
	 * object: {"a": {"b": {"c": <circular reference to $.a>}}}
	 * array: [[[<circular reference to the $[0] array>]]]
	 *
	 * Encode it, remove the circular reference and encode again.
	 */

	jansson.test.util.init_unittest();

	{
		jansson.jansson.json_t* json = jansson.value.json_object();

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		jansson.value.json_object_set_new(json, "a", jansson.value.json_object());
		jansson.value.json_object_set_new(jansson.value.json_object_get(json, "a"), "b", jansson.value.json_object());
		jansson.jansson.json_object_set(jansson.value.json_object_get(jansson.value.json_object_get(json, "a"), "b"), "c", jansson.value.json_object_get(json, "a"));

		assert(jansson.dump.json_dumps(json, 0) == null, "json_dumps encoded a circular reference!");

		jansson.value.json_object_del(jansson.value.json_object_get(jansson.value.json_object_get(json, "a"), "b"), "c");

		char* result = jansson.dump.json_dumps(json, 0);

		scope (exit) {
			jansson.jansson_private.jsonp_free(result);
		}

		assert((result != null) && (!core.stdc.string.strcmp(result, "{\"a\": {\"b\": {}}}")), "json_dumps failed!");
	}

	{
		jansson.jansson.json_t* json = jansson.value.json_array();

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		jansson.value.json_array_append_new(json, jansson.value.json_array());
		jansson.value.json_array_append_new(jansson.value.json_array_get(json, 0), jansson.value.json_array());
		jansson.jansson.json_array_append(jansson.value.json_array_get(jansson.value.json_array_get(json, 0), 0), jansson.value.json_array_get(json, 0));

		assert(jansson.dump.json_dumps(json, 0) == null, "json_dumps encoded a circular reference!");

		jansson.value.json_array_remove(jansson.value.json_array_get(jansson.value.json_array_get(json, 0), 0), 0);

		char* result = jansson.dump.json_dumps(json, 0);

		scope (exit) {
			jansson.jansson_private.jsonp_free(result);
		}

		assert((result != null) && (!core.stdc.string.strcmp(result, "[[[]]]")), "json_dumps failed!");
	}
}

//encode_other_than_array_or_object
unittest
{
	/*
	 * Encoding anything other than array or object should only
	 * succeed if the jansson.jansson.JSON_ENCODE_ANY flag is used
	 */

	jansson.test.util.init_unittest();

	{
		jansson.jansson.json_t* json = jansson.value.json_string("foo");

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		assert(jansson.dump.json_dumps(json, 0) == null, "json_dumps encoded a string!");

		assert(jansson.dump.json_dumpf(json, null, 0) != 0, "json_dumpf encoded a string!");

		assert(jansson.dump.json_dumpfd(json, -1, 0) != 0, "json_dumpfd encoded a string!");

		char* result = jansson.dump.json_dumps(json, jansson.jansson.JSON_ENCODE_ANY);

		scope (exit) {
			jansson.jansson_private.jsonp_free(result);
		}

		assert((result != null) && (core.stdc.string.strcmp(result, "\"foo\"") == 0), "json_dumps failed to encode a string with JSON_ENCODE_ANY");
	}

	{
		jansson.jansson.json_t* json = jansson.value.json_integer(42);

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		assert(jansson.dump.json_dumps(json, 0) == null, "json_dumps encoded an integer!");

		assert(jansson.dump.json_dumpf(json, null, 0) != 0, "json_dumpf encoded an integer!");

		assert(jansson.dump.json_dumpfd(json, -1, 0) != 0, "json_dumpfd encoded an integer!");

		char* result = jansson.dump.json_dumps(json, jansson.jansson.JSON_ENCODE_ANY);

		scope (exit) {
			jansson.jansson_private.jsonp_free(result);
		}

		assert((result != null) && (core.stdc.string.strcmp(result, "42") == 0), "json_dumps failed to encode an integer with JSON_ENCODE_ANY");
	}
}

//escape_slashes
unittest
{
	/* Test dump escaping slashes */

	jansson.test.util.init_unittest();
	jansson.jansson.json_t* json = jansson.value.json_object();

	scope (exit) {
		jansson.jansson.json_decref(json);
	}

	jansson.value.json_object_set_new(json, "url", jansson.value.json_string("https://github.com/akheron/jansson"));

	{
		char* result = jansson.dump.json_dumps(json, 0);

		scope (exit) {
			jansson.jansson_private.jsonp_free(result);
		}

		assert((result != null) && (!core.stdc.string.strcmp(result, "{\"url\": \"https://github.com/akheron/jansson\"}")), "json_dumps failed to not escape slashes");
	}

	{
		char* result = jansson.dump.json_dumps(json, jansson.jansson.JSON_ESCAPE_SLASH);

		scope (exit) {
			jansson.jansson_private.jsonp_free(result);
		}

		assert((result != null) && (!core.stdc.string.strcmp(result, "{\"url\": \"https:\\/\\/github.com\\/akheron\\/jansson\"}")), "json_dumps failed to escape slashes");
	}
}

//encode_nul_byte
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* json = jansson.value.json_stringn("nul byte \0 in string", 20);

	scope (exit) {
		jansson.jansson.json_decref(json);
	}

	char* result = jansson.dump.json_dumps(json, jansson.jansson.JSON_ENCODE_ANY);

	scope (exit) {
		jansson.jansson_private.jsonp_free(result);
	}

	assert((result != null) && (core.stdc.string.memcmp(result, &("\"nul byte \\u0000 in string\"\0"[0]), 27) == 0), "json_dumps failed to dump an embedded NUL byte");
}

//dump_file
unittest
{
	jansson.test.util.init_unittest();

	{
		int result = jansson.dump.json_dump_file(null, "\0", 0);

		assert(result == -1, "json_dump_file succeeded with invalid args");
	}

	{
		jansson.jansson.json_t* json = jansson.value.json_object();

		scope (exit) {
			jansson.jansson.json_decref(json);

			core.stdc.stdio.remove("json_dump_file.json");
		}

		int result = jansson.dump.json_dump_file(json, "json_dump_file.json", 0);

		assert(result == 0, "json_dump_file failed");
	}
}

//dumpb
unittest
{
	jansson.test.util.init_unittest();

	{
		jansson.jansson.json_t* obj = jansson.value.json_object();

		scope (exit) {
			jansson.jansson.json_decref(obj);
		}

		char[2] buf = void;
		size_t size = jansson.dump.json_dumpb(obj, &(buf[0]), buf.length, 0);

		assert((size == 2) && (!core.stdc.string.strncmp(&(buf[0]), "{}", 2)), "json_dumpb failed");
	}

	{
		jansson.jansson.json_t* obj = jansson.pack_unpack.json_pack("{s:s}", &("foo\0"[0]), &("bar\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(obj);
		}

		char[2] buf = void;
		size_t size = jansson.dump.json_dumpb(obj, &(buf[0]), buf.length, jansson.jansson.JSON_COMPACT);

		assert(size == 13, "json_dumpb size check failed");
	}
}

//dumpfd
unittest
{
	jansson.test.util.init_unittest();

	static if (__traits(compiles, core.sys.posix.unistd.pipe)) {
		int[2] fds = [-1, -1];

		assert(!core.sys.posix.unistd.pipe(fds), "pipe() failed");

		jansson.jansson.json_t* a = jansson.pack_unpack.json_pack("{s:s}", &("foo\0"[0]), &("bar\0"[0]));

		assert(!jansson.dump.json_dumpfd(a, fds[1], 0), "json_dumpfd() failed");

		core.sys.posix.unistd.close(fds[1]);

		jansson.jansson.json_t* b = jansson.load.json_loadfd(fds[0], 0, null);

		scope (exit) {
			jansson.jansson.json_decref(a);
			jansson.jansson.json_decref(b);
		}

		assert(b != null, "json_loadfd() failed");

		core.sys.posix.unistd.close(fds[0]);

		assert(jansson.value.json_equal(a, b), "json_equal() failed for fd test");
	}
}

//embed
unittest
{
	static immutable string[] plains = ["{\"bar\":[],\"foo\":{}}\0", "[[],{}]\0", "{}\0", "[]\0"];

	jansson.test.util.init_unittest();

	for (size_t i = 0; i < plains.length; i++) {
		immutable (char)* plain = &(plains[i][0]);

		size_t psize = core.stdc.string.strlen(plain) - 2;
		char* embed = cast(char*)(core.memory.pureCalloc(1, psize));
		assert(embed != null);

		scope (exit) {
			core.memory.pureFree(embed);
		}

		size_t esize = void;

		{
			jansson.jansson.json_t* parse = jansson.load.json_loads(plain, 0, null);

			scope (exit) {
				jansson.jansson.json_decref(parse);
			}

			esize = jansson.dump.json_dumpb(parse, embed, psize, jansson.jansson.JSON_COMPACT | jansson.jansson.JSON_SORT_KEYS | jansson.jansson.JSON_EMBED);
		}

		assert(esize == psize, "json_dumpb(JSON_EMBED) returned an invalid size");

		assert(core.stdc.string.strncmp(plain + 1, embed, esize) == 0, "json_dumps(JSON_EMBED) returned an invalid value");
	}
}
