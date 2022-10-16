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
module jansson.test.test_unpack;


private static import core.stdc.string;
private static import jansson.jansson;
private static import jansson.pack_unpack;
private static import jansson.test.util;
private static import jansson.value;

//run_tests
unittest
{
	/*
	 * Simple, valid json_pack cases
	 */

	jansson.test.util.init_unittest();

	{
		/* true */
		int i1 = void;
		int rv = jansson.pack_unpack.json_unpack(jansson.value.json_true(), "b", &i1);

		assert((!rv) && (i1), "json_unpack boolean failed");
	}

	{
		/* false */
		int i1 = void;
		int rv = jansson.pack_unpack.json_unpack(jansson.value.json_false(), "b", &i1);

		assert((!rv) && (!i1), "json_unpack boolean failed");
	}

	{
		/* null */
		assert(!jansson.pack_unpack.json_unpack(jansson.value.json_null(), "n"), "json_unpack null failed");
	}

	{
		/* integer */
		jansson.jansson.json_t* j = jansson.value.json_integer(42);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		int rv = jansson.pack_unpack.json_unpack(j, "i", &i1);

		assert((!rv) && (i1 == 42), "json_unpack integer failed");
	}

	{
		/* json_int_t */
		jansson.jansson.json_t* j = jansson.value.json_integer(5555555);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_int_t I1 = void;
		int rv = jansson.pack_unpack.json_unpack(j, "I", &I1);

		assert((!rv) && (I1 == 5555555), "json_unpack json_int_t failed");
	}

	{
		/* real */
		jansson.jansson.json_t* j = jansson.value.json_real(1.7);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		double f = void;
		int rv = jansson.pack_unpack.json_unpack(j, "f", &f);

		assert((!rv) && (f == 1.7), "json_unpack real failed");
	}

	{
		/* number */
		jansson.jansson.json_t* j = jansson.value.json_integer(12345);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		double f = void;
		int rv = jansson.pack_unpack.json_unpack(j, "F", &f);

		assert((!rv) && (f == 12345.0), "json_unpack (real or) integer failed");
	}

	{
		jansson.jansson.json_t* j = jansson.value.json_real(1.7);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		double f = void;
		int rv = jansson.pack_unpack.json_unpack(j, "F", &f);

		assert((!rv) && (f == 1.7), "json_unpack real (or integer) failed");
	}

	{
		/* string */
		jansson.jansson.json_t* j = jansson.value.json_string("foo");

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		char* s = void;
		int rv = jansson.pack_unpack.json_unpack(j, "s", &s);

		assert((!rv) && (!core.stdc.string.strcmp(s, "foo")), "json_unpack string failed");
	}

	{
		/* string with length (size_t) */
		jansson.jansson.json_t* j = jansson.value.json_string("foo");

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		size_t z = void;
		char* s = void;
		int rv = jansson.pack_unpack.json_unpack(j, "s%", &s, &z);

		assert((!rv) && (!core.stdc.string.strcmp(s, "foo")) && (z == 3), "json_unpack string with length (size_t) failed");
	}

	{
		/* empty object */
		jansson.jansson.json_t* j = jansson.value.json_object();

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		assert(!jansson.pack_unpack.json_unpack(j, "{}"), "json_unpack empty object failed");
	}

	{
		/* empty list */
		jansson.jansson.json_t* j = jansson.value.json_array();

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		assert(!jansson.pack_unpack.json_unpack(j, "[]"), "json_unpack empty list failed");
	}

	{
		/* non-incref'd object */
		jansson.jansson.json_t* j = jansson.value.json_object();

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_t* j2 = void;
		int rv = jansson.pack_unpack.json_unpack(j, "o", &j2);

		assert((!rv) && (j2 == j) && (j.refcount == 1), "json_unpack object failed");
	}

	{
		/* incref'd object */
		jansson.jansson.json_t* j = jansson.value.json_object();

		scope (exit) {
			jansson.jansson.json_decref(j);
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_t* j2 = void;
		int rv = jansson.pack_unpack.json_unpack(j, "O", &j2);

		assert((!rv) && (j2 == j) && (j.refcount == 2), "json_unpack object failed");
	}

	{
		/* simple object */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{s:i}", &("foo\0"[0]), 42);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		int rv = jansson.pack_unpack.json_unpack(j, "{s:i}", &("foo\0"[0]), &i1);

		assert((!rv) && (i1 == 42), "json_unpack simple object failed");
	}

	{
		/* simple array */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[iii]", 1, 2, 3);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		int i2 = void;
		int i3 = void;
		int rv = jansson.pack_unpack.json_unpack(j, "[i,i,i]", &i1, &i2, &i3);

		assert((!rv) && (i1 == 1) && (i2 == 2) && (i3 == 3), "json_unpack simple array failed");
	}

	{
		/* object with many items & strict checking */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{s:i, s:i, s:i}", &("a\0"[0]), 1, &("b\0"[0]), 2, &("c\0"[0]), 3);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		int i2 = void;
		int i3 = void;
		int rv = jansson.pack_unpack.json_unpack(j, "{s:i, s:i, s:i}", &("a\0"[0]), &i1, &("b\0"[0]), &i2, &("c\0"[0]), &i3);

		assert((!rv) && (i1 == 1) && (i2 == 2) && (i3 == 3), "json_unpack object with many items failed");
	}

	/*
	 * Invalid cases
	 */

	{
		jansson.jansson.json_t* j = jansson.value.json_integer(42);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "z"), "json_unpack succeeded with invalid format character");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character 'z'", "<format>", 1, 1, 1);

		assert(jansson.pack_unpack.json_unpack_ex(null, &error, 0, "[i]"), "json_unpack succeeded with null root");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_null_value, "null root value", "<root>", -1, -1, 0);
	}

	{
		/* mismatched open/close array/object */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[]");

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "[}"), "json_unpack failed to catch mismatched ']'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '}'", "<format>", 1, 2, 2);
	}

	{
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{}");

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "{]"), "json_unpack failed to catch mismatched '}'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Expected format 's', got ']'", "<format>", 1, 2, 2);
	}

	{
		/* missing close array */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[]");

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "["), "json_unpack failed to catch missing ']'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected end of format string", "<format>", 1, 2, 2);
	}

	{
		/* missing close object */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{}");

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "{"), "json_unpack failed to catch missing '}'");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Unexpected end of format string", "<format>", 1, 2, 2);
	}

	{
		/* garbage after format string */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[i]", 42);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "[i]a", &i1), "json_unpack failed to catch garbage after format string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Garbage after format string", "<format>", 1, 4, 4);
	}

	{
		jansson.jansson.json_t* j = jansson.value.json_integer(12345);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "ia", &i1), "json_unpack failed to catch garbage after format string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Garbage after format string", "<format>", 1, 2, 2);
	}

	{
		/* null format string */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[]");

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, null), "json_unpack failed to catch null format string");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_argument, "null or empty format string", "<format>", -1, -1, 0);
	}

	{
		/* null string pointer */
		jansson.jansson.json_t* j = jansson.value.json_string("foobie");

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "s", null), "json_unpack failed to catch null string pointer");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_null_value, "null string argument", "<args>", 1, 1, 1);
	}

	{
		/* invalid types */
		jansson.jansson.json_t* j = jansson.value.json_integer(42);
		jansson.jansson.json_t* j2 = jansson.value.json_string("foo");

		scope (exit) {
			jansson.jansson.json_decref(j);
			jansson.jansson.json_decref(j2);
		}

		{
			jansson.jansson.json_error_t error = void;
			assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "s"), "json_unpack failed to catch invalid type");

			jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_wrong_type, "Expected string, got integer", "<validation>", 1, 1, 1);
		}

		{
			jansson.jansson.json_error_t error = void;
			assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "n"), "json_unpack failed to catch invalid type");

			jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_wrong_type, "Expected null, got integer", "<validation>", 1, 1, 1);
		}

		{
			jansson.jansson.json_error_t error = void;
			assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "b"), "json_unpack failed to catch invalid type");

			jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_wrong_type, "Expected true or false, got integer", "<validation>", 1, 1, 1);
		}

		{
			jansson.jansson.json_error_t error = void;
			assert(jansson.pack_unpack.json_unpack_ex(j2, &error, 0, "i"), "json_unpack failed to catch invalid type");

			jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_wrong_type, "Expected integer, got string", "<validation>", 1, 1, 1);
		}

		{
			jansson.jansson.json_error_t error = void;
			assert(jansson.pack_unpack.json_unpack_ex(j2, &error, 0, "I"), "json_unpack failed to catch invalid type");

			jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_wrong_type, "Expected integer, got string", "<validation>", 1, 1, 1);
		}

		{
			jansson.jansson.json_error_t error = void;
			assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "f"), "json_unpack failed to catch invalid type");

			jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_wrong_type, "Expected real, got integer", "<validation>", 1, 1, 1);
		}

		{
			jansson.jansson.json_error_t error = void;
			assert(jansson.pack_unpack.json_unpack_ex(j2, &error, 0, "F"), "json_unpack failed to catch invalid type");

			jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_wrong_type, "Expected real or integer, got string", "<validation>", 1, 1, 1);
		}

		{
			jansson.jansson.json_error_t error = void;
			assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "[i]"), "json_unpack failed to catch invalid type");

			jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_wrong_type, "Expected array, got integer", "<validation>", 1, 1, 1);
		}

		{
			jansson.jansson.json_error_t error = void;
			assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "{si}", &("foo\0"[0])), "json_unpack failed to catch invalid type");

			jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_wrong_type, "Expected object, got integer", "<validation>", 1, 1, 1);
		}
	}

	{
		/* Array index out of range */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[i]", 1);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		int i2 = void;
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "[ii]", &i1, &i2), "json_unpack failed to catch index out of array bounds");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_index_out_of_range, "Array index 1 out of range", "<validation>", 1, 3, 3);
	}

	{
		/* null object key */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{si}", &("foo\0"[0]), 42);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "{si}", null, &i1), "json_unpack failed to catch null string pointer");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_null_value, "null object key", "<args>", 1, 2, 2);
	}

	{
		/* Object key not found */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{si}", &("foo\0"[0]), 42);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "{si}", &("baz\0"[0]), &i1), "json_unpack failed to catch null string pointer");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_item_not_found, "Object item not found: baz", "<validation>", 1, 3, 3);
	}

	/*
	 * Strict validation
	 */
	{
		{
			jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[iii]", 1, 2, 3);
			int i1 = void;
			int i2 = void;
			int i3 = void;
			int rv = jansson.pack_unpack.json_unpack(j, "[iii!]", &i1, &i2, &i3);

			scope (exit) {
				jansson.jansson.json_decref(j);
			}

			assert((!rv) && (i1 == 1) && (i2 == 2) && (i3 == 3), "json_unpack array with strict validation failed");
		}
		{
			jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[iii]", 1, 2, 3);

			scope (exit) {
				jansson.jansson.json_decref(j);
			}

			int i1 = void;
			int i2 = void;
			jansson.jansson.json_error_t error = void;
			assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "[ii!]", &i1, &i2), "json_unpack array with strict validation failed");

			jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_end_of_input_expected, "1 array item(s) left unpacked", "<validation>", 1, 5, 5);
		}
	}

	{
		/* Like above, but with JSON_STRICT instead of '!' format */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[iii]", 1, 2, 3);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		int i2 = void;
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, jansson.jansson.JSON_STRICT, "[ii]", &i1, &i2), "json_unpack array with strict validation failed");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_end_of_input_expected, "1 array item(s) left unpacked", "<validation>", 1, 4, 4);
	}

	{
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{s:s, s:i}", &("foo\0"[0]), &("bar\0"[0]), &("baz\0"[0]), 42);
		char* s = void;
		int i1 = void;
		int rv = jansson.pack_unpack.json_unpack(j, "{sssi!}", &("foo\0"[0]), &s, &("baz\0"[0]), &i1);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		assert((!rv) && (core.stdc.string.strcmp(s, "bar") == 0) && (i1 == 42), "json_unpack object with strict validation failed");
	}

	{
		/* Unpack the same item twice */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{s:s, s:i, s:b}", &("foo\0"[0]), &("bar\0"[0]), &("baz\0"[0]), 42, &("quux\0"[0]), 1);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_error_t error = void;
		char* s = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "{s:s,s:s!}", &("foo\0"[0]), &s, &("foo\0"[0]), &s), "json_unpack object with strict validation failed");

		{
			static immutable string[2] possible_errors = ["2 object item(s) left unpacked: baz, quux\0", "2 object item(s) left unpacked: quux, baz\0"];
			jansson.test.util.check_errors(error, jansson.jansson.json_error_code_t.json_error_end_of_input_expected, &(possible_errors[0][0]), possible_errors.length, "<validation>", 1, 10, 10);
		}
	}

	{
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[i,{s:i,s:n},[i,i]]", 1, &("foo\0"[0]), 2, &("bar\0"[0]), 3, 4);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		assert(!jansson.pack_unpack.json_unpack_ex(j, null, jansson.jansson.JSON_STRICT | jansson.jansson.JSON_VALIDATE_ONLY, "[i{sisn}[ii]]", &("foo\0"[0]), &("bar\0"[0])), "json_unpack complex value with strict validation failed");
	}

	{
		/* ! and * must be last */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[ii]", 1, 2);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		int i2 = void;
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "[i!i]", &i1, &i2), "json_unpack failed to catch ! in the middle of an array");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Expected ']' after '!', got 'i'", "<format>", 1, 4, 4);

		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "[i*i]", &i1, &i2), "json_unpack failed to catch * in the middle of an array");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Expected ']' after '*', got 'i'", "<format>", 1, 4, 4);
	}

	{
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{sssi}", &("foo\0"[0]), &("bar\0"[0]), &("baz\0"[0]), 42);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		char* s = void;
		int i1 = void;
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "{ss!si}", &("foo\0"[0]), &s, &("baz\0"[0]), &i1), "json_unpack failed to catch ! in the middle of an object");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Expected '}' after '!', got 's'", "<format>", 1, 5, 5);

		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "{ss*si}", &("foo\0"[0]), &s, &("baz\0"[0]), &i1), "json_unpack failed to catch ! in the middle of an object");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_invalid_format, "Expected '}' after '*', got 's'", "<format>", 1, 5, 5);
	}

	{
		/* Error in nested object */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{s{snsn}}", &("foo\0"[0]), &("bar\0"[0]), &("baz\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "{s{sn!}}", &("foo\0"[0]), &("bar\0"[0])), "json_unpack nested object with strict validation failed");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_end_of_input_expected, "1 object item(s) left unpacked: baz", "<validation>", 1, 7, 7);
	}

	{
		/* Error in nested array */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("[[ii]]", 1, 2);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		jansson.jansson.json_error_t error = void;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "[[i!]]", &i1), "json_unpack nested array with strict validation failed");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_end_of_input_expected, "1 array item(s) left unpacked", "<validation>", 1, 5, 5);
	}

	{
		/* Optional values */
		jansson.jansson.json_t* j = jansson.value.json_object();

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = 0;
		assert(!jansson.pack_unpack.json_unpack(j, "{s?i}", &("foo\0"[0]), &i1), "json_unpack failed for optional key");

		assert(i1 == 0, "json_unpack unpacked an optional key");
	}

	{
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{si}", &("foo\0"[0]), 42);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = 0;
		assert(!jansson.pack_unpack.json_unpack(j, "{s?i}", &("foo\0"[0]), &i1), "json_unpack failed for an optional value");

		assert(i1 == 42, "json_unpack failed to unpack an optional value");
	}

	{
		jansson.jansson.json_t* j = jansson.value.json_object();

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i3 = 0;
		int i2 = 0;
		int i1 = 0;

		assert(!jansson.pack_unpack.json_unpack(j, "{s?[ii]s?{s{si}}}", &("foo\0"[0]), &i1, &i2, &("bar\0"[0]), &("baz\0"[0]), &("quux\0"[0]), &i3), "json_unpack failed for complex optional values");

		assert((i1 == 0) && (i2 == 0) && (i3 == 0), "json_unpack unexpectedly unpacked something");
	}

	{
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{s{si}}", &("foo\0"[0]), &("bar\0"[0]), 42);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i1 = void;
		assert(!jansson.pack_unpack.json_unpack(j, "{s?{s?i}}", &("foo\0"[0]), &("bar\0"[0]), &i1), "json_unpack failed for complex optional values");

		assert(i1 == 42, "json_unpack failed to unpack");
	}

	{
		/* Combine ? and ! */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{si}", &("foo\0"[0]), 42);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		int i2 = 0;
		int i1 = 0;

		assert(!jansson.pack_unpack.json_unpack(j, "{sis?i!}", &("foo\0"[0]), &i1, &("bar\0"[0]), &i2), "json_unpack failed for optional values with strict mode");

		assert(i1 == 42, "json_unpack failed to unpack");

		assert(i2 == 0, "json_unpack failed to unpack");
	}

	{
		/* But don't compensate a missing key with an optional one. */
		jansson.jansson.json_t* j = jansson.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 42, &("baz\0"[0]), 43);

		scope (exit) {
			jansson.jansson.json_decref(j);
		}

		jansson.jansson.json_error_t error = void;
		int i3 = 0;
		int i2 = 0;
		int i1 = 0;
		assert(jansson.pack_unpack.json_unpack_ex(j, &error, 0, "{sis?i!}", &("foo\0"[0]), &i1, &("bar\0"[0]), &i2), "json_unpack failed for optional values with strict mode and compensation");

		jansson.test.util.check_error(error, jansson.jansson.json_error_code_t.json_error_end_of_input_expected, "1 object item(s) left unpacked: baz", "<validation>", 1, 8, 8);
	}
}
