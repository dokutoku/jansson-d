/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.test_dump_callback;


private static import core.memory;
private static import core.stdc.string;
private static import jansson.dump;
private static import jansson.jansson;
private static import jansson.jansson_private;
private static import jansson.load;
private static import jansson.test.util;

private struct my_sink
{
	char* buf;
	size_t off;
	size_t cap;
}

extern (C)
pure nothrow @trusted @nogc @live
private int my_writer(scope const char* buffer, size_t len, scope void* data)

	in
	{
		assert(data != null);
	}

	do
	{
		.my_sink* s = cast(.my_sink*)(data);

		if (len > (s.cap - s.off)) {
			return -1;
		}

		core.stdc.string.memcpy(s.buf + s.off, buffer, len);
		s.off += len;

		return 0;
	}

//run_tests
unittest
{
	static immutable char[] str = "[\"A\", {\"B\": \"C\", \"e\": false}, 1, null, \"foo\"]\0";

	jansson.test.util.init_unittest();
	jansson.jansson.json_t* json = jansson.load.json_loads(&(str[0]), 0, null);

	scope (exit) {
		jansson.jansson.json_decref(json);
	}

	assert(json != null, "json_loads failed");

	char* dumped_to_string = jansson.dump.json_dumps(json, 0);

	scope (exit) {
		jansson.jansson_private.jsonp_free(dumped_to_string);
	}

	assert(dumped_to_string != null, "json_dumps failed");

	.my_sink s = void;
	s.off = 0;
	s.cap = core.stdc.string.strlen(dumped_to_string);
	s.buf = cast(char*)(core.memory.pureMalloc(s.cap));

	assert(s.buf != null, "malloc failed");

	scope (exit) {
		core.memory.pureFree(s.buf);
	}

	assert(jansson.dump.json_dump_callback(json, &.my_writer, &s, 0) != -1, "json_dump_callback failed on an exact-length sink buffer");
	assert(core.stdc.string.strncmp(dumped_to_string, s.buf, s.off) == 0, "json_dump_callback and json_dumps did not produce identical output");

	s.off = 1;

	assert(jansson.dump.json_dump_callback(json, &.my_writer, &s, 0) == -1, "json_dump_callback succeeded on a short buffer when it should have failed");
}
