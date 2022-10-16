/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.test_loadb;


private static import core.stdc.string;
private static import jansson.jansson;
private static import jansson.load;
private static import jansson.test.util;

//run_tests
unittest
{
	jansson.test.util.init_unittest();

	static immutable char[] str = "[\"A\", {\"B\": \"C\"}, 1, 2, 3]garbage\0";
	size_t len = core.stdc.string.strlen(&(str[0])) - "garbage".length;

	{
		jansson.jansson.json_error_t error = void;
		jansson.jansson.json_t* json = jansson.load.json_loadb(&(str[0]), len, 0, &error);

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		assert(json != null, "json_loadb failed on a valid JSON buffer");
	}

	{
		jansson.jansson.json_error_t error = void;
		jansson.jansson.json_t* json = jansson.load.json_loadb(&(str[0]), len - 1, 0, &error);

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		assert(json == null, "json_loadb should have failed on an incomplete buffer, but it didn't");

		assert(error.line == 1, "json_loadb returned an invalid line number on fail");

		assert(core.stdc.string.strcmp(&(error.text[0]), "']' expected near end of file") == 0, "json_loadb returned an invalid error message for an unclosed top-level array");
	}
}
