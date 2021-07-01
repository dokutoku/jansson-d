/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.test.test_dump_callback;


private static import core.memory;
private static import core.stdc.string;
private static import jansson_d.dump;
private static import jansson_d.jansson;
private static import jansson_d.jansson_private;
private static import jansson_d.load;
private static import jansson_d.test.util;

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

	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* json = jansson_d.load.json_loads(&(str[0]), 0, null);

	assert(json != null, "json_loads failed");

	char* dumped_to_string = jansson_d.dump.json_dumps(json, 0);

	if (dumped_to_string == null) {
		jansson_d.jansson.json_decref(json);
		assert(false, "json_dumps failed");
	}

	.my_sink s = void;
	s.off = 0;
	s.cap = core.stdc.string.strlen(dumped_to_string);
	s.buf = cast(char*)(core.memory.pureMalloc(s.cap));

	if (s.buf == null) {
		jansson_d.jansson.json_decref(json);
		jansson_d.jansson_private.jsonp_free(dumped_to_string);
		assert(false, "malloc failed");
	}

	if (jansson_d.dump.json_dump_callback(json, &.my_writer, &s, 0) == -1) {
		jansson_d.jansson.json_decref(json);
		jansson_d.jansson_private.jsonp_free(dumped_to_string);
		core.memory.pureFree(s.buf);
		assert(false, "json_dump_callback failed on an exact-length sink buffer");
	}

	if (core.stdc.string.strncmp(dumped_to_string, s.buf, s.off) != 0) {
		jansson_d.jansson.json_decref(json);
		jansson_d.jansson_private.jsonp_free(dumped_to_string);
		core.memory.pureFree(s.buf);
		assert(false, "json_dump_callback and json_dumps did not produce identical output");
	}

	s.off = 1;

	if (jansson_d.dump.json_dump_callback(json, &.my_writer, &s, 0) != -1) {
		jansson_d.jansson.json_decref(json);
		jansson_d.jansson_private.jsonp_free(dumped_to_string);
		core.memory.pureFree(s.buf);
		assert(false, "json_dump_callback succeeded on a short buffer when it should have failed");
	}

	jansson_d.jansson.json_decref(json);
	jansson_d.jansson_private.jsonp_free(dumped_to_string);
	core.memory.pureFree(s.buf);
}
