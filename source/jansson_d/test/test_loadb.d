/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.test.test_loadb;


private static import core.stdc.string;
private static import jansson_d.jansson;
private static import jansson_d.load;
private static import jansson_d.test.util;

//run_tests
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_error_t error = void;

	static immutable char[] str = "[\"A\", {\"B\": \"C\"}, 1, 2, 3]garbage\0";
	size_t len = core.stdc.string.strlen(&(str[0])) - "garbage".length;

	jansson_d.jansson.json_t* json = void;

	{
		json = jansson_d.load.json_loadb(&(str[0]), len, 0, &error);

		assert(json != null, "json_loadb failed on a valid JSON buffer");

		jansson_d.jansson.json_decref(json);
	}

	{
		json = jansson_d.load.json_loadb(&(str[0]), len - 1, 0, &error);

		if (json != null) {
			jansson_d.jansson.json_decref(json);
			assert(false, "json_loadb should have failed on an incomplete buffer, but it didn't");
		}
	}

	assert(error.line == 1, "json_loadb returned an invalid line number on fail");

	assert(core.stdc.string.strcmp(&(error.text[0]), "']' expected near end of file") == 0, "json_loadb returned an invalid error message for an unclosed top-level array");
}
