/*
 * Copyright (c) 2009-2011 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.test_load_callback;


private static import core.stdc.string;
private static import jansson.jansson;
private static import jansson.load;
private static import jansson.test.util;

private struct my_source
{
	const (char)* buf;
	size_t off;
	size_t cap;
}

private static immutable char[] my_str = "[\"A\", {\"B\": \"C\", \"e\": false}, 1, null, \"foo\"]\0";

extern (C)
pure nothrow @trusted @nogc @live
private size_t greedy_reader(scope void* buf, size_t buflen, scope void* arg)

	do
	{
		.my_source* s = cast(.my_source*)(arg);

		if (buflen > (s.cap - s.off)) {
			buflen = s.cap - s.off;
		}

		if (buflen > 0) {
			core.stdc.string.memcpy(buf, s.buf + s.off, buflen);
			s.off += buflen;

			return buflen;
		} else {
			return 0;
		}
	}

//run_tests
unittest
{
	jansson.test.util.init_unittest();

	.my_source s =
	{
		off: 0,
		cap: core.stdc.string.strlen(&(.my_str[0])),
		buf: &(.my_str[0]),
	};

	{
		jansson.jansson.json_error_t error = void;
		jansson.jansson.json_t* json = jansson.load.json_load_callback(&.greedy_reader, &s, 0, &error);

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		assert(json != null, "json_load_callback failed on a valid callback");
	}

	s.off = 0;
	s.cap = core.stdc.string.strlen(&(.my_str[0])) - 1;
	s.buf = &(.my_str[0]);

	{
		jansson.jansson.json_error_t error = void;
		jansson.jansson.json_t* json = jansson.load.json_load_callback(&.greedy_reader, &s, 0, &error);

		scope (exit) {
			version (all) {
				jansson.jansson.json_decref(json);
			}
		}

		assert(json == null, "json_load_callback should have failed on an incomplete stream, but it didn't");

		assert(core.stdc.string.strcmp(&(error.source[0]), "<callback>") == 0, "json_load_callback returned an invalid error source");

		assert(core.stdc.string.strcmp(&(error.text[0]), "']' expected near end of file") == 0, "json_load_callback returned an invalid error message for an unclosed top-level array");
	}

	{
		jansson.jansson.json_error_t error = void;
		jansson.jansson.json_t* json = jansson.load.json_load_callback(null, null, 0, &error);

		scope (exit) {
			version (all) {
				jansson.jansson.json_decref(json);
			}
		}

		assert(json == null, "json_load_callback should have failed on null load callback, but it didn't");

		assert(core.stdc.string.strcmp(&(error.text[0]), "wrong arguments") == 0, "json_load_callback returned an invalid error message for a null load callback");
	}
}
