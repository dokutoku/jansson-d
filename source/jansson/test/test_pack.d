/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 * Copyright (c) 2010-2012 Graeme Smecher <graeme.smecher@mail.mcgill.ca>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.test_pack;


private static import core.stdc.math;
private static import core.stdc.string;
private static import jansson.jansson;
private static import jansson.pack_unpack;
private static import jansson.test.util;
private static import jansson.test.util;
private static import jansson.value;

// This test triggers "warning C4756: overflow in constant arithmetic"
// in Visual Studio. This warning is triggered here by design, so disable it.
// (This can only be done on function level so we keep these tests separate)
static if (__traits(compiles, core.stdcpp.xutility._MSC_VER)) {
	//#pragma warning(disable : 4756)
}

//test_inifity
unittest
{
	static assert(__traits(compiles, core.stdc.math.INFINITY));

	jansson.test.util.init_unittest();

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "f", core.stdc.math.INFINITY) == null, "json_pack infinity incorrectly succeeded");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_numeric_overflow, "Invalid floating point value", "<args>", 1, 1, 1);
	}

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "[f]", core.stdc.math.INFINITY) == null, "json_pack infinity array element incorrectly succeeded");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_numeric_overflow, "Invalid floating point value", "<args>", 1, 2, 2);
	}

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:f}", &("key\0"[0]), core.stdc.math.INFINITY) == null, "json_pack infinity object value incorrectly succeeded");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_numeric_overflow, "Invalid floating point value", "<args>", 1, 4, 4);
	}
}

//run_tests
unittest
{
	/*
	 * Simple, valid json_pack cases
	 */
	/* true */
	jansson.test.util.init_unittest();

	{
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("b", 1);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert(mixin (jansson.jansson.json_is_true!("value")), "json_pack boolean failed");

		assert(value.refcount == size_t.max, "json_pack boolean refcount failed");
	}

	{
		/* false */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("b", 0);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert(mixin (jansson.jansson.json_is_false!("value")), "json_pack boolean failed");

		assert(value.refcount == size_t.max, "json_pack boolean refcount failed");
	}

	{
		/* null */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("n");

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert(mixin (jansson.jansson.json_is_null!("value")), "json_pack null failed");

		assert(value.refcount == size_t.max, "json_pack null refcount failed");
	}

	{
		/* integer */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("i", 1);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_integer!("value"))) && (jansson.value.json_integer_value(value) == 1), "json_pack integer failed");

		assert(value.refcount == cast(size_t)(1), "json_pack integer refcount failed");
	}

	{
		/* integer from json_int_t */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("I", cast(jansson.jansson.json_int_t)(555555));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_integer!("value"))) && (jansson.value.json_integer_value(value) == 555555), "json_pack jansson.jansson.json_int_t failed");

		assert(value.refcount == cast(size_t)(1), "json_pack integer refcount failed");
	}

	{
		/* real */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("f", 1.0);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_real!("value"))) && (jansson.value.json_real_value(value) == 1.0), "json_pack real failed");

		assert(value.refcount == cast(size_t)(1), "json_pack real refcount failed");
	}

	{
		/* string */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("s", &("test\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_string!("value"))) && (core.stdc.string.strcmp("test", jansson.value.json_string_value(value)) == 0), "json_pack string failed");

		assert(value.refcount == cast(size_t)(1), "json_pack string refcount failed");
	}

	{
		/* nullable string (defined case) */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("s?", &("test\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_string!("value"))) && (core.stdc.string.strcmp("test", jansson.value.json_string_value(value)) == 0), "json_pack nullable string (defined case) failed");

		assert(value.refcount == cast(size_t)(1), "json_pack nullable string (defined case) refcount failed");
	}

	{
		/* nullable string (null case) */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("s?", null);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert(mixin (jansson.jansson.json_is_null!("value")), "json_pack nullable string (null case) failed");

		assert(value.refcount == size_t.max, "json_pack nullable string (null case) refcount failed");
	}

	{
		/* nullable string concatenation */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "s?+", &("test\0"[0]), &("ing\0"[0])) == null, "json_pack failed to catch invalid format 's?+'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Cannot use '+' on optional strings", "<format>", 1, 2, 2);
	}

	{
		/* nullable string with integer length */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "s?#", &("test\0"[0]), 4) == null, "json_pack failed to catch invalid format 's?#'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Cannot use '#' on optional strings", "<format>", 1, 2, 2);
	}

	{
		/* string and length (int) */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("s#", &("test asdf\0"[0]), 4);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_string!("value"))) && (core.stdc.string.strcmp("test", jansson.value.json_string_value(value)) == 0), "json_pack string and length failed");

		assert(value.refcount == cast(size_t)(1), "json_pack string and length refcount failed");
	}

	{
		/* string and length (size_t) */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("s%", &("test asdf\0"[0]), cast(size_t)(4));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_string!("value"))) && (core.stdc.string.strcmp("test", jansson.value.json_string_value(value)) == 0), "json_pack string and length failed");

		assert(value.refcount == cast(size_t)(1), "json_pack string and length refcount failed");
	}

	{
		/* string and length (int), non-NUL terminated string */
		char[4] buffer = ['t', 'e', 's', 't'];
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("s#", &(buffer[0]), buffer.length);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_string!("value"))) && (core.stdc.string.strcmp("test", jansson.value.json_string_value(value)) == 0), "json_pack string and length (int) failed");

		assert(value.refcount == cast(size_t)(1), "json_pack string and length (int) refcount failed");
	}

	{
		/* string and length (size_t), non-NUL terminated string */
		char[4] buffer = ['t', 'e', 's', 't'];
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("s%", &(buffer[0]), buffer.length);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_string!("value"))) && (core.stdc.string.strcmp("test", jansson.value.json_string_value(value)) == 0), "json_pack string and length (size_t) failed");

		assert(value.refcount == cast(size_t)(1), "json_pack string and length (size_t) refcount failed");
	}

	{
		/* string concatenation */
		assert(jansson.pack_unpack.json_pack("s+", &("test\0"[0]), null) == null, "json_pack string concatenation succeeded with null string");
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("s++", &("te\0"[0]), &("st\0"[0]), &("ing\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_string!("value"))) && (core.stdc.string.strcmp("testing", jansson.value.json_string_value(value)) == 0), "json_pack string concatenation failed");

		assert(value.refcount == cast(size_t)(1), "json_pack string concatenation refcount failed");
	}

	{
		/* string concatenation and length (int) */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("s#+#+", &("test\0"[0]), 1, &("test\0"[0]), 2, &("test\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_string!("value"))) && (core.stdc.string.strcmp("ttetest", jansson.value.json_string_value(value)) == 0), "json_pack string concatenation and length (int) failed");

		assert(value.refcount == cast(size_t)(1), "json_pack string concatenation and length (int) refcount failed");
	}

	{
		/* string concatenation and length (size_t) */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("s%+%+", &("test\0"[0]), cast(size_t)(1), &("test\0"[0]), cast(size_t)(2), &("test\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_string!("value"))) && (core.stdc.string.strcmp("ttetest", jansson.value.json_string_value(value)) == 0), "json_pack string concatenation and length (size_t) failed");

		assert(value.refcount == cast(size_t)(1), "json_pack string concatenation and length (size_t) refcount failed");
	}

	{
		/* empty object */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("{}", 1.0);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_object!("value"))) && (jansson.value.json_object_size(value) == 0), "json_pack empty object failed");

		assert(value.refcount == cast(size_t)(1), "json_pack empty object refcount failed");
	}

	{
		/* empty list */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("[]", 1.0);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_array!("value"))) && (jansson.value.json_array_size(value) == 0), "json_pack empty list failed");

		assert(value.refcount == cast(size_t)(1), "json_pack empty list failed");
	}

	{
		/* non-incref'd object */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("o", jansson.value.json_integer(1));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_integer!("value"))) && (jansson.value.json_integer_value(value) == 1), "json_pack object failed");

		assert(value.refcount == cast(size_t)(1), "json_pack integer refcount failed");
	}

	{
		/* non-incref'd nullable object (defined case) */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("o?", jansson.value.json_integer(1));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_integer!("value"))) && (jansson.value.json_integer_value(value) == 1), "json_pack nullable object (defined case) failed");

		assert(value.refcount == cast(size_t)(1), "json_pack nullable object (defined case) refcount failed");
	}

	{
		/* non-incref'd nullable object (null case) */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("o?", null);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert(mixin (jansson.jansson.json_is_null!("value")), "json_pack nullable object (null case) failed");

		assert(value.refcount == size_t.max, "json_pack nullable object (null case) refcount failed");
	}

	{
		/* incref'd object */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("O", jansson.value.json_integer(1));

		scope (exit) {
			jansson.jansson.json_decref(value);
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_integer!("value"))) && (jansson.value.json_integer_value(value) == 1), "json_pack object failed");

		assert(value.refcount == cast(size_t)(2), "json_pack integer refcount failed");
	}

	{
		/* incref'd nullable object (defined case) */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("O?", jansson.value.json_integer(1));

		scope (exit) {
			jansson.jansson.json_decref(value);
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_integer!("value"))) && (jansson.value.json_integer_value(value) == 1), "json_pack incref'd nullable object (defined case) failed");

		assert(value.refcount == cast(size_t)(2), "json_pack incref'd nullable object (defined case) refcount failed");
	}

	{
		/* incref'd nullable object (null case) */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("O?", null);

		assert(mixin (jansson.jansson.json_is_null!("value")), "json_pack incref'd nullable object (null case) failed");

		assert(value.refcount == size_t.max, "json_pack incref'd nullable object (null case) refcount failed");
	}

	{
		/* simple object */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("{s:[]}", &("foo\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_object!("value"))) && (jansson.value.json_object_size(value) == 1), "json_pack array failed");

		assert(mixin (jansson.jansson.json_is_array!("jansson.value.json_object_get(value, `foo`)")), "json_pack array failed");

		assert(jansson.value.json_object_get(value, "foo").refcount == cast(size_t)(1), "json_pack object refcount failed");
	}

	{
		/* object with complex key */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("{s+#+: []}", &("foo\0"[0]), &("barbar\0"[0]), 3, &("baz\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_object!("value"))) && (jansson.value.json_object_size(value) == 1), "json_pack array failed");

		assert(mixin (jansson.jansson.json_is_array!("jansson.value.json_object_get(value, `foobarbaz`)")), "json_pack array failed");

		assert(jansson.value.json_object_get(value, "foobarbaz").refcount == cast(size_t)(1), "json_pack object refcount failed");
	}

	{
		/* object with optional members */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("{s:s,s:o,s:O}", &("a\0"[0]), null, &("b\0"[0]), null, &("c\0"[0]), null);

		assert(value == null, "json_pack object optional incorrectly succeeded");
	}

	{
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("{s:**}", &("a\0"[0]), null);

		assert(value == null, "json_pack object optional invalid incorrectly succeeded");

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:i*}", &("a\0"[0]), 1) == null, "json_pack object optional invalid incorrectly succeeded");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Expected format 's', got '*'", "<format>", 1, 5, 5);
	}

	{
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("{s:s*,s:o*,s:O*}", &("a\0"[0]), null, &("b\0"[0]), null, &("c\0"[0]), null);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_object!("value"))) && (jansson.value.json_object_size(value) == 0), "json_pack object optional failed");
	}

	{
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("{s:s*}", &("key\0"[0]), &("\xff\xff\0"[0]));

		assert(value == null, "json_pack object optional with invalid UTF-8 incorrectly succeeded");

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s: s*#}", &("key\0"[0]), &("test\0"[0]), 1) == null, "json_pack failed to catch invalid format 's*#'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Cannot use '#' on optional strings", "<format>", 1, 6, 6);

		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s: s*+}", &("key\0"[0]), &("test\0"[0]), &("ing\0"[0])) == null, "json_pack failed to catch invalid format 's*+'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Cannot use '+' on optional strings", "<format>", 1, 6, 6);
	}

	{
		/* simple array */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("[i,i,i]", 0, 1, 2);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_array!("value"))) && (jansson.value.json_array_size(value) == 3), "json_pack object failed");

		for (size_t i = 0; i < 3; i++) {
			assert((mixin (jansson.jansson.json_is_integer!("jansson.value.json_array_get(value, i)"))) && (jansson.value.json_integer_value(jansson.value.json_array_get(value, i)) == i), "json_pack integer array failed");
		}
	}

	{
		/* simple array with optional members */
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("[s,o,O]", null, null, null);

		assert(value == null, "json_pack array optional incorrectly succeeded");

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "[i*]", 1) == null, "json_pack array optional invalid incorrectly succeeded");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '*'", "<format>", 1, 3, 3);
	}

	{
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("[**]", null);

		assert(value == null, "json_pack array optional invalid incorrectly succeeded");
	}

	{
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("[s*,o*,O*]", null, null, null);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_array!("value"))) && (jansson.value.json_array_size(value) == 0), "json_pack array optional failed");
	}

	{
		static assert(__traits(compiles, core.stdc.math.NAN));
		/* Invalid float values */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "f", core.stdc.math.NAN) == null, "json_pack NAN incorrectly succeeded");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_numeric_overflow, "Invalid floating point value", "<args>", 1, 1, 1);

		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "[f]", core.stdc.math.NAN) == null, "json_pack NAN array element incorrectly succeeded");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_numeric_overflow, "Invalid floating point value", "<args>", 1, 2, 2);

		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:f}", &("key\0"[0]), core.stdc.math.NAN) == null, "json_pack NAN object value incorrectly succeeded");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_numeric_overflow, "Invalid floating point value", "<args>", 1, 4, 4);
	}

	/* Whitespace; regular string */
	{
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack(" s\t ", &("test\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_string!("value"))) && (core.stdc.string.strcmp("test", jansson.value.json_string_value(value)) == 0), "json_pack string (with whitespace) failed");
	}

	/* Whitespace; empty array */
	{
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("[ ]");

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_array!("value"))) && (jansson.value.json_array_size(value) == 0), "json_pack empty array (with whitespace) failed");
	}

	/* Whitespace; array */
	{
		jansson.jansson.json_t* value = jansson.pack_unpack.json_pack("[ i , i,  i ] ", 1, 2, 3);

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		assert((mixin (jansson.jansson.json_is_array!("value"))) && (jansson.value.json_array_size(value) == 3), "json_pack array (with whitespace) failed");
	}

	/*
	 * Invalid cases
	 */

	{
		/* newline in format string */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{\n\n1") == null, "json_pack failed to catch invalid format '1'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Expected format 's', got '1'", "<format>", 3, 1, 4);
	}

	{
		/* mismatched open/close array/object */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "[}") == null, "json_pack failed to catch mismatched '}'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '}'", "<format>", 1, 2, 2);
	}

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{]") == null, "json_pack failed to catch mismatched ']'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Expected format 's', got ']'", "<format>", 1, 2, 2);
	}

	{
		/* missing close array */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "[") == null, "json_pack failed to catch missing ']'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected end of format string", "<format>", 1, 2, 2);
	}

	{
		/* missing close object */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{") == null, "json_pack failed to catch missing '}'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected end of format string", "<format>", 1, 2, 2);
	}

	{
		/* garbage after format string */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "[i]a", 42) == null, "json_pack failed to catch garbage after format string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Garbage after format string", "<format>", 1, 4, 4);
	}

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "ia", 42) == null, "json_pack failed to catch garbage after format string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Garbage after format string", "<format>", 1, 2, 2);
	}

	{
		/* null string */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "s", null) == null, "json_pack failed to catch null argument string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_null_value, "null string", "<args>", 1, 1, 1);
	}

	{
		/* + on its own */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "+", null) == null, "json_pack failed to a lone +");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '+'", "<format>", 1, 1, 1);
	}

	{
		/* Empty format */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "\0") == null, "json_pack failed to catch empty format string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_argument, "null or empty format string", "<format>", -1, -1, 0);
	}

	{
		/* null format */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, null) == null, "json_pack failed to catch null format string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_argument, "null or empty format string", "<format>", -1, -1, 0);
	}

	{
		/* null key */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:i}", null, 1) == null, "json_pack failed to catch null key");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_null_value, "null object key", "<args>", 1, 2, 2);
	}

	{
		/* null value followed by object still steals the object's ref */
		jansson.jansson.json_t* value = jansson.jansson.json_incref(jansson.value.json_object());

		scope (exit) {
			jansson.jansson.json_decref(value);
		}

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:s,s:o}", &("badnull\0"[0]), null, &("dontleak\0"[0]), value) == null, "json_pack failed to catch null value");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_null_value, "null string", "<args>", 1, 4, 4);

		assert(value.refcount == cast(size_t)(1), "json_pack failed to steal reference after error.");
	}

	{
		/* More complicated checks for row/columns */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{ {}: s }", &("foo\0"[0])) == null, "json_pack failed to catch object as key");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Expected format 's', got '{'", "<format>", 1, 3, 3);
	}

	{
		/* Complex object */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{ s: {},  s:[ii{} }", &("foo\0"[0]), &("bar\0"[0]), 12, 13) == null, "json_pack failed to catch missing ]");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '}'", "<format>", 1, 19, 19);
	}

	{
		/* Complex array */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "[[[[[   [[[[[  [[[[ }]]]] ]]]] ]]]]]") == null, "json_pack failed to catch extra }");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '}'", "<format>", 1, 21, 21);
	}

	{
		/* Invalid UTF-8 in object key */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:i}", &("\xff\xff\0"[0]), 42) == null, "json_pack failed to catch invalid UTF-8 in an object key");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_utf8, "Invalid UTF-8 object key", "<args>", 1, 2, 2);
	}

	{
		/* Invalid UTF-8 in a string */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:s}", &("foo\0"[0]), &("\xff\xff\0"[0])) == null, "json_pack failed to catch invalid UTF-8 in a string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_utf8, "Invalid UTF-8 string", "<args>", 1, 4, 4);
	}

	{
		/* Invalid UTF-8 in an optional '?' string */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:s?}", &("foo\0"[0]), &("\xff\xff\0"[0])) == null, "json_pack failed to catch invalid UTF-8 in an optional '?' string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_utf8, "Invalid UTF-8 string", "<args>", 1, 5, 5);
	}

	{
		/* Invalid UTF-8 in an optional '*' string */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:s*}", &("foo\0"[0]), &("\xff\xff\0"[0])) == null, "json_pack failed to catch invalid UTF-8 in an optional '*' string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_utf8, "Invalid UTF-8 string", "<args>", 1, 5, 5);
	}

	{
		/* Invalid UTF-8 in a concatenated key */
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s+:i}", &("\xff\xff\0"[0]), &("concat\0"[0]), 42) == null, "json_pack failed to catch invalid UTF-8 in an object key");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_utf8, "Invalid UTF-8 object key", "<args>", 1, 3, 3);
	}

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:o}", &("foo\0"[0]), null) == null, "json_pack failed to catch nullable object");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_null_value, "null object", "<args>", 1, 4, 4);
	}

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s:O}", &("foo\0"[0]), null) == null, "json_pack failed to catch nullable incref object");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_null_value, "null object", "<args>", 1, 4, 4);
	}

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "{s+:o}", &("foo\0"[0]), &("bar\0"[0]), null) == null, "json_pack failed to catch non-nullable object value");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_null_value, "null object", "<args>", 1, 5, 5);
	}

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "[1s", &("Hi\0"[0])) == null, "json_pack failed to catch invalid format");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '1'", "<format>", 1, 2, 2);
	}

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "[1s+", &("Hi\0"[0]), &("ya\0"[0])) == null, "json_pack failed to catch invalid format");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '1'", "<format>", 1, 2, 2);
	}

	{
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_pack_ex(&error, 0, "[so]", null, jansson.value.json_object()) == null, "json_pack failed to catch null value");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_null_value, "null string", "<args>", 1, 2, 2);
	}
}
