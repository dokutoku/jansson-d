/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.test.test_dump;


private static import core.memory;
private static import core.stdc.stdio;
private static import core.stdc.string;
private static import core.sys.posix.unistd;
private static import jansson_d.dump;
private static import jansson_d.jansson;
private static import jansson_d.jansson_private;
private static import jansson_d.load;
private static import jansson_d.pack_unpack;
private static import jansson_d.test.util;
private static import jansson_d.value;

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
	jansson_d.test.util.init_unittest();
	assert(jansson_d.dump.json_dumps(null, jansson_d.jansson.JSON_ENCODE_ANY) == null, "json_dumps didn't fail for null");

	assert(jansson_d.dump.json_dumpb(null, null, 0, jansson_d.jansson.JSON_ENCODE_ANY) == 0, "json_dumpb didn't fail for null");

	assert(jansson_d.dump.json_dumpf(null, core.stdc.stdio.stderr, jansson_d.jansson.JSON_ENCODE_ANY) == -1, "json_dumpf didn't fail for null");

	static if (__traits(compiles, core.sys.posix.unistd.STDERR_FILENO)) {
		assert(jansson_d.dump.json_dumpfd(null, core.sys.posix.unistd.STDERR_FILENO, jansson_d.jansson.JSON_ENCODE_ANY) == -1, "json_dumpfd didn't fail for null");
	}

	/* Don't test json_dump_file to avoid creating a file */

	assert(jansson_d.dump.json_dump_callback(null, &.encode_null_callback, null, jansson_d.jansson.JSON_ENCODE_ANY) == -1, "json_dump_callback didn't fail for null");
}

//encode_twice
unittest
{
	/* Encode an empty object/array, add an item, encode again */

	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* json = jansson_d.value.json_object();
	char* result = jansson_d.dump.json_dumps(json, 0);

	assert((result != null) && (!core.stdc.string.strcmp(result, "{}")), "json_dumps failed");

	jansson_d.jansson_private.jsonp_free(result);

	jansson_d.value.json_object_set_new(json, "foo", jansson_d.value.json_integer(5));
	result = jansson_d.dump.json_dumps(json, 0);

	assert((result != null) && (!core.stdc.string.strcmp(result, "{\"foo\": 5}")), "json_dumps failed");

	jansson_d.jansson_private.jsonp_free(result);

	jansson_d.jansson.json_decref(json);

	json = jansson_d.value.json_array();
	result = jansson_d.dump.json_dumps(json, 0);

	assert((result != null) && (!core.stdc.string.strcmp(result, "[]")), "json_dumps failed");

	jansson_d.jansson_private.jsonp_free(result);

	jansson_d.value.json_array_append_new(json, jansson_d.value.json_integer(5));
	result = jansson_d.dump.json_dumps(json, 0);

	assert((result != null) && (!core.stdc.string.strcmp(result, "[5]")), "json_dumps failed");

	jansson_d.jansson_private.jsonp_free(result);

	jansson_d.jansson.json_decref(json);
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

	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* json = jansson_d.value.json_object();
	jansson_d.value.json_object_set_new(json, "a", jansson_d.value.json_object());
	jansson_d.value.json_object_set_new(jansson_d.value.json_object_get(json, "a"), "b", jansson_d.value.json_object());
	jansson_d.jansson.json_object_set(jansson_d.value.json_object_get(jansson_d.value.json_object_get(json, "a"), "b"), "c", jansson_d.value.json_object_get(json, "a"));

	assert(jansson_d.dump.json_dumps(json, 0) == null, "json_dumps encoded a circular reference!");

	jansson_d.value.json_object_del(jansson_d.value.json_object_get(jansson_d.value.json_object_get(json, "a"), "b"), "c");

	char* result = jansson_d.dump.json_dumps(json, 0);

	assert((result != null) && (!core.stdc.string.strcmp(result, "{\"a\": {\"b\": {}}}")), "json_dumps failed!");

	jansson_d.jansson_private.jsonp_free(result);

	jansson_d.jansson.json_decref(json);

	json = jansson_d.value.json_array();
	jansson_d.value.json_array_append_new(json, jansson_d.value.json_array());
	jansson_d.value.json_array_append_new(jansson_d.value.json_array_get(json, 0), jansson_d.value.json_array());
	jansson_d.jansson.json_array_append(jansson_d.value.json_array_get(jansson_d.value.json_array_get(json, 0), 0), jansson_d.value.json_array_get(json, 0));

	assert(jansson_d.dump.json_dumps(json, 0) == null, "json_dumps encoded a circular reference!");

	jansson_d.value.json_array_remove(jansson_d.value.json_array_get(jansson_d.value.json_array_get(json, 0), 0), 0);

	result = jansson_d.dump.json_dumps(json, 0);

	assert((result != null) && (!core.stdc.string.strcmp(result, "[[[]]]")), "json_dumps failed!");

	jansson_d.jansson_private.jsonp_free(result);

	jansson_d.jansson.json_decref(json);
}

//encode_other_than_array_or_object
unittest
{
	/*
	 * Encoding anything other than array or object should only
	 * succeed if the jansson_d.jansson.JSON_ENCODE_ANY flag is used
	 */

	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* json = jansson_d.value.json_string("foo");

	assert(jansson_d.dump.json_dumps(json, 0) == null, "json_dumps encoded a string!");

	assert(jansson_d.dump.json_dumpf(json, null, 0) != 0, "json_dumpf encoded a string!");

	assert(jansson_d.dump.json_dumpfd(json, -1, 0) != 0, "json_dumpfd encoded a string!");

	char* result = jansson_d.dump.json_dumps(json, jansson_d.jansson.JSON_ENCODE_ANY);

	assert((result != null) && (core.stdc.string.strcmp(result, "\"foo\"") == 0), "json_dumps failed to encode a string with JSON_ENCODE_ANY");

	jansson_d.jansson_private.jsonp_free(result);
	jansson_d.jansson.json_decref(json);

	json = jansson_d.value.json_integer(42);

	assert(jansson_d.dump.json_dumps(json, 0) == null, "json_dumps encoded an integer!");

	assert(jansson_d.dump.json_dumpf(json, null, 0) != 0, "json_dumpf encoded an integer!");

	assert(jansson_d.dump.json_dumpfd(json, -1, 0) != 0, "json_dumpfd encoded an integer!");

	result = jansson_d.dump.json_dumps(json, jansson_d.jansson.JSON_ENCODE_ANY);

	assert((result != null) && (core.stdc.string.strcmp(result, "42") == 0), "json_dumps failed to encode an integer with JSON_ENCODE_ANY");

	jansson_d.jansson_private.jsonp_free(result);
	jansson_d.jansson.json_decref(json);
}

//escape_slashes
unittest
{
	/* Test dump escaping slashes */

	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* json = jansson_d.value.json_object();
	jansson_d.value.json_object_set_new(json, "url", jansson_d.value.json_string("https://github.com/akheron/jansson"));

	char* result = jansson_d.dump.json_dumps(json, 0);

	assert((result != null) && (!core.stdc.string.strcmp(result, "{\"url\": \"https://github.com/akheron/jansson\"}")), "json_dumps failed to not escape slashes");

	jansson_d.jansson_private.jsonp_free(result);

	result = jansson_d.dump.json_dumps(json, jansson_d.jansson.JSON_ESCAPE_SLASH);

	assert((result != null) && (!core.stdc.string.strcmp(result, "{\"url\": \"https:\\/\\/github.com\\/akheron\\/jansson\"}")), "json_dumps failed to escape slashes");

	jansson_d.jansson_private.jsonp_free(result);
	jansson_d.jansson.json_decref(json);
}

//encode_nul_byte
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* json = jansson_d.value.json_stringn("nul byte \0 in string", 20);
	char* result = jansson_d.dump.json_dumps(json, jansson_d.jansson.JSON_ENCODE_ANY);

	assert((result != null) && (core.stdc.string.memcmp(result, &("\"nul byte \\u0000 in string\"\0"[0]), 27) == 0), "json_dumps failed to dump an embedded NUL byte");

	jansson_d.jansson_private.jsonp_free(result);
	jansson_d.jansson.json_decref(json);
}

//dump_file
unittest
{
	jansson_d.test.util.init_unittest();
	int result = jansson_d.dump.json_dump_file(null, "\0", 0);

	assert(result == -1, "json_dump_file succeeded with invalid args");

	jansson_d.jansson.json_t* json = jansson_d.value.json_object();
	result = jansson_d.dump.json_dump_file(json, "json_dump_file.json", 0);

	assert(result == 0, "json_dump_file failed");

	jansson_d.jansson.json_decref(json);
	core.stdc.stdio.remove("json_dump_file.json");
}

//dumpb
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* obj = jansson_d.value.json_object();

	char[2] buf = void;
	size_t size = jansson_d.dump.json_dumpb(obj, &(buf[0]), buf.length, 0);

	assert((size == 2) && (!core.stdc.string.strncmp(&(buf[0]), "{}", 2)), "json_dumpb failed");

	jansson_d.jansson.json_decref(obj);
	obj = jansson_d.pack_unpack.json_pack("{s:s}", &("foo\0"[0]), &("bar\0"[0]));

	size = jansson_d.dump.json_dumpb(obj, &(buf[0]), buf.length, jansson_d.jansson.JSON_COMPACT);

	assert(size == 13, "json_dumpb size check failed");

	jansson_d.jansson.json_decref(obj);
}

//dumpfd
unittest
{
	jansson_d.test.util.init_unittest();

	static if (__traits(compiles, core.sys.posix.unistd.pipe)) {
		int[2] fds = [-1, -1];

		assert(!core.sys.posix.unistd.pipe(fds), "pipe() failed");

		jansson_d.jansson.json_t* a = jansson_d.pack_unpack.json_pack("{s:s}", &("foo\0"[0]), &("bar\0"[0]));

		assert(!jansson_d.dump.json_dumpfd(a, fds[1], 0), "json_dumpfd() failed");

		core.sys.posix.unistd.close(fds[1]);

		jansson_d.jansson.json_t* b = jansson_d.load.json_loadfd(fds[0], 0, null);

		assert(b != null, "json_loadfd() failed");

		core.sys.posix.unistd.close(fds[0]);

		assert(jansson_d.value.json_equal(a, b), "json_equal() failed for fd test");

		jansson_d.jansson.json_decref(a);
		jansson_d.jansson.json_decref(b);
	}
}

//embed
unittest
{
	static immutable string[] plains = ["{\"bar\":[],\"foo\":{}}\0", "[[],{}]\0", "{}\0", "[]\0"];

	jansson_d.test.util.init_unittest();

	for (size_t i = 0; i < plains.length; i++) {
		immutable (char)* plain = &(plains[i][0]);

		size_t psize = core.stdc.string.strlen(plain) - 2;
		char* embed = cast(char*)(core.memory.pureCalloc(1, psize));
		jansson_d.jansson.json_t* parse = jansson_d.load.json_loads(plain, 0, null);
		size_t esize = jansson_d.dump.json_dumpb(parse, embed, psize, jansson_d.jansson.JSON_COMPACT | jansson_d.jansson.JSON_SORT_KEYS | jansson_d.jansson.JSON_EMBED);
		jansson_d.jansson.json_decref(parse);

		assert(esize == psize, "json_dumpb(JSON_EMBED) returned an invalid size");

		assert(core.stdc.string.strncmp(plain + 1, embed, esize) == 0, "json_dumps(JSON_EMBED) returned an invalid value");

		core.memory.pureFree(embed);
	}
}
