/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.test.test_load;


private static import core.stdc.string;
private static import jansson_d.jansson;
private static import jansson_d.jansson_config;
private static import jansson_d.load;
private static import jansson_d.test.util;
private static import jansson_d.value;

//file_not_found
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_error_t error = void;

	jansson_d.jansson.json_t* json = jansson_d.load.json_load_file("/path/to/nonexistent/file.json", 0, &error);

	assert(json == null, "json_load_file returned non-null for a nonexistent file");

	assert(error.line == -1, "json_load_file returned an invalid line number");

	/*
	 * The error message is locale specific, only check the beginning
	 * of the error message.
	 */

	char* pos = core.stdc.string.strchr(&(error.text[0]), ':');

	assert(pos != null, "json_load_file returne an invalid error message");

	*pos = '\0';

	assert(core.stdc.string.strcmp(&(error.text[0]), "unable to open /path/to/nonexistent/file.json") == 0, "json_load_file returned an invalid error message");

	assert(jansson_d.jansson.json_error_code(&error) == jansson_d.jansson.json_error_code_t.json_error_cannot_open_file, "json_load_file returned an invalid error code");
}

//very_long_file_name
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_error_t error = void;

	jansson_d.jansson.json_t* json = jansson_d.load.json_load_file("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 0, &error);

	assert(json == null, "json_load_file returned non-null for a nonexistent file");

	assert(error.line == -1, "json_load_file returned an invalid line number");

	assert(core.stdc.string.strncmp(&(error.source[0]), "...aaa", 6) == 0, "error source was set incorrectly");

	assert(jansson_d.jansson.json_error_code(&error) == jansson_d.jansson.json_error_code_t.json_error_cannot_open_file, "error code was set incorrectly");
}

//reject_duplicates
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_error_t error = void;

	assert(jansson_d.load.json_loads("{\"foo\": 1, \"foo\": 2}", jansson_d.jansson.JSON_REJECT_DUPLICATES, &error) == null, "json_loads did not detect a duplicate key");

	jansson_d.test.util.check_error(error, jansson_d.jansson.json_error_code_t.json_error_duplicate_key, "duplicate object key near '\"foo\"'", "<string>", 1, 16, 16);
}

//disable_eof_check
unittest
{
	static immutable char* text = "{\"foo\": 1} garbage";
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_error_t error = void;

	assert(jansson_d.load.json_loads(text, 0, &error) == null, "json_loads did not detect garbage after JSON text");

	jansson_d.test.util.check_error(error, jansson_d.jansson.json_error_code_t.json_error_end_of_input_expected, "end of file expected near 'garbage'", "<string>", 1, 18, 18);

	jansson_d.jansson.json_t* json = jansson_d.load.json_loads(text, jansson_d.jansson.JSON_DISABLE_EOF_CHECK, &error);

	scope (exit) {
		jansson_d.jansson.json_decref(json);
	}

	assert(json != null, "json_loads failed with JSON_DISABLE_EOF_CHECK");
}

//decode_any
unittest
{
	jansson_d.test.util.init_unittest();

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads("\"foo\"", jansson_d.jansson.JSON_DECODE_ANY, &error);

		scope (exit) {
			jansson_d.jansson.json_decref(json);
		}

		assert((json != null) && (mixin (jansson_d.jansson.json_is_string!("json"))), "json_load decoded any failed - string");
	}

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads("42", jansson_d.jansson.JSON_DECODE_ANY, &error);

		scope (exit) {
			jansson_d.jansson.json_decref(json);
		}

		assert((json != null) && (mixin (jansson_d.jansson.json_is_integer!("json"))), "json_load decoded any failed - integer");
	}

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads("true", jansson_d.jansson.JSON_DECODE_ANY, &error);

		scope (exit) {
			jansson_d.jansson.json_decref(json);
		}

		assert((json != null) && (mixin (jansson_d.jansson.json_is_true!("json"))), "json_load decoded any failed - boolean");
	}

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads("null", jansson_d.jansson.JSON_DECODE_ANY, &error);

		scope (exit) {
			jansson_d.jansson.json_decref(json);
		}

		assert((json != null) && (mixin (jansson_d.jansson.json_is_null!("json"))), "json_load decoded any failed - null");
	}
}

//decode_int_as_real
unittest
{
	jansson_d.test.util.init_unittest();

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads("42", jansson_d.jansson.JSON_DECODE_INT_AS_REAL | jansson_d.jansson.JSON_DECODE_ANY, &error);

		scope (exit) {
			jansson_d.jansson.json_decref(json);
		}

		assert((json != null) && (mixin (jansson_d.jansson.json_is_real!("json"))) && (jansson_d.value.json_real_value(json) == 42.0), "json_load decode int as real failed - int");
	}

	{
		static if (jansson_d.jansson_config.JSON_INTEGER_IS_LONG_LONG) {
			/* This number cannot be represented exactly by a double */
			static immutable char* imprecise = "9007199254740993";
			jansson_d.jansson.json_int_t expected = 9007199254740992L;

			jansson_d.jansson.json_error_t error = void;
			jansson_d.jansson.json_t* json = jansson_d.load.json_loads(imprecise, jansson_d.jansson.JSON_DECODE_INT_AS_REAL | jansson_d.jansson.JSON_DECODE_ANY, &error);

			scope (exit) {
				jansson_d.jansson.json_decref(json);
			}

			assert((json != null) && (mixin (jansson_d.jansson.json_is_real!("json"))) && (expected == cast(jansson_d.jansson.json_int_t)(jansson_d.value.json_real_value(json))), "json_load decode int as real failed - expected imprecision");
		}
	}

	{
		/*
		 * 1E309 overflows. Here we create 1E309 as a decimal number, i.e.
		 * 1000...(309 zeroes)...0.
		 */
		char[311] big = void;
		big[0] = '1';
		core.stdc.string.memset(&(big[0]) + 1, '0', 309);
		big[310] = '\0';

		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads(&(big[0]), jansson_d.jansson.JSON_DECODE_INT_AS_REAL | jansson_d.jansson.JSON_DECODE_ANY, &error);

		scope (exit) {
			jansson_d.jansson.json_decref(json);
		}

		assert((json == null) && (core.stdc.string.strcmp(&(error.text[0]), "real number overflow") == 0) && (jansson_d.jansson.json_error_code(&error) == jansson_d.jansson.json_error_code_t.json_error_numeric_overflow), "json_load decode int as real failed - expected overflow");
	}
}

//allow_nul
unittest
{
	static immutable char* text = "\"nul byte \\u0000 in string\"";
	immutable char* expected = "nul byte \0 in string";
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* json = jansson_d.load.json_loads(text, jansson_d.jansson.JSON_ALLOW_NUL | jansson_d.jansson.JSON_DECODE_ANY, null);

	scope (exit) {
		jansson_d.jansson.json_decref(json);
	}

	assert((json != null) && (mixin (jansson_d.jansson.json_is_string!("json"))), "unable to decode embedded NUL byte");

	size_t len = 20;
	assert(jansson_d.value.json_string_length(json) == len, "decoder returned wrong string length");

	assert(core.stdc.string.memcmp(jansson_d.value.json_string_value(json), expected, len + 1) == 0, "decoder returned wrong string content");
}

//load_wrong_args
unittest
{
	jansson_d.test.util.init_unittest();

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads(null, 0, &error);

		assert(json == null, "json_loads should return null if the first argument is null");
	}

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loadb(null, 0, 0, &error);

		assert(json == null, "json_loadb should return null if the first argument is null");
	}

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loadf(null, 0, &error);

		assert(json == null, "json_loadf should return null if the first argument is null");
	}

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loadfd(-1, 0, &error);

		assert(json == null, "json_loadfd should return null if the first argument is < 0");
	}

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_load_file(null, 0, &error);

		assert(json == null, "json_load_file should return null if the first argument is null");
	}
}

//position
unittest
{
	jansson_d.test.util.init_unittest();
	size_t flags = jansson_d.jansson.JSON_DISABLE_EOF_CHECK;

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads("{\"foo\": \"bar\"}", 0, &error);

		scope (exit) {
			jansson_d.jansson.json_decref(json);
		}

		assert(error.position == 14, "json_loads returned a wrong position");
	}

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads("{\"foo\": \"bar\"} baz quux", flags, &error);

		scope (exit) {
			jansson_d.jansson.json_decref(json);
		}

		assert(error.position == 14, "json_loads returned a wrong position");
	}
}

//error_code
unittest
{
	jansson_d.test.util.init_unittest();

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads("[123] garbage", 0, &error);

		assert(json == null, "json_loads returned not null");

		assert(core.stdc.string.strlen(&(error.text[0])) < error.text.length, "error.text longer than expected");

		assert(jansson_d.jansson.json_error_code(&error) == jansson_d.jansson.json_error_code_t.json_error_end_of_input_expected, "json_loads returned incorrect error code");
	}

	{
		jansson_d.jansson.json_error_t error = void;
		jansson_d.jansson.json_t* json = jansson_d.load.json_loads("{\"foo\": ", 0, &error);

		assert(json == null, "json_loads returned not null");

		assert(core.stdc.string.strlen(&(error.text[0])) < error.text.length, "error.text longer than expected");

		assert(jansson_d.jansson.json_error_code(&error) == jansson_d.jansson.json_error_code_t.json_error_premature_end_of_input, "json_loads returned incorrect error code");
	}
}
