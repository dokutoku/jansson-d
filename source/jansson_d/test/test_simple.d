/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.test.test_simple;


private static import core.stdc.string;
private static import jansson_d.jansson;
private static import jansson_d.test.util;
private static import jansson_d.value;

private void test_bad_args()

	do
	{
		jansson_d.jansson.json_t* num = jansson_d.value.json_integer(1);
		jansson_d.jansson.json_t* txt = jansson_d.value.json_string("test");

		scope (exit) {
			jansson_d.jansson.json_decref(num);
			jansson_d.jansson.json_decref(txt);
		}

		assert((num != null) && (txt != null), "failed to allocate test objects");

		assert(jansson_d.value.json_string_nocheck(null) == null, "json_string_nocheck with null argument did not return null");

		assert(jansson_d.value.json_stringn_nocheck(null, 0) == null, "json_stringn_nocheck with null argument did not return null");

		assert(jansson_d.value.json_string(null) == null, "json_string with null argument did not return null");

		assert(jansson_d.value.json_stringn(null, 0) == null, "json_stringn with null argument did not return null");

		assert(jansson_d.value.json_string_length(null) == 0, "json_string_length with non-string argument did not return 0");

		assert(jansson_d.value.json_string_length(num) == 0, "json_string_length with non-string argument did not return 0");

		assert(jansson_d.value.json_string_value(null) == null, "json_string_value with non-string argument did not return null");

		assert(jansson_d.value.json_string_value(num) == null, "json_string_value with non-string argument did not return null");

		assert(jansson_d.value.json_string_setn_nocheck(null, "\0", 0), "json_string_setn with non-string argument did not return error");

		assert(jansson_d.value.json_string_setn_nocheck(num, "\0", 0), "json_string_setn with non-string argument did not return error");

		assert(jansson_d.value.json_string_setn_nocheck(txt, null, 0), "json_string_setn_nocheck with null value did not return error");

		assert(jansson_d.value.json_string_set_nocheck(txt, null), "json_string_set_nocheck with null value did not return error");

		assert(jansson_d.value.json_string_set(txt, null), "json_string_set with null value did not return error");

		assert(jansson_d.value.json_string_setn(txt, null, 0), "json_string_setn with null value did not return error");

		assert(num.refcount == 1, "unexpected reference count for num");

		assert(txt.refcount == 1, "unexpected reference count for txt");
	}

/* Call the simple functions not covered by other tests of the public API */
unittest
{
	jansson_d.test.util.init_unittest();

	jansson_d.jansson.json_t* value = void;

	{
		value = mixin (jansson_d.jansson.json_boolean!("1"));

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(mixin (jansson_d.jansson.json_is_true!("value")), "json_boolean(1) failed");
	}

	{
		value = mixin (jansson_d.jansson.json_boolean!("-123"));

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(mixin (jansson_d.jansson.json_is_true!("value")), "json_boolean(-123) failed");
	}

	{
		value = mixin (jansson_d.jansson.json_boolean!("0"));

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(mixin (jansson_d.jansson.json_is_false!("value")), "json_boolean(0) failed");

		assert(mixin (jansson_d.jansson.json_boolean_value!("value")) == 0, "json_boolean_value failed");
	}

	{
		value = jansson_d.value.json_integer(1);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(mixin (jansson_d.jansson.json_typeof!("value")) == jansson_d.jansson.json_type.JSON_INTEGER, "json_typeof failed");

		assert(!mixin (jansson_d.jansson.json_is_object!("value")), "json_is_object failed");

		assert(!mixin (jansson_d.jansson.json_is_array!("value")), "json_is_array failed");

		assert(!mixin (jansson_d.jansson.json_is_string!("value")), "json_is_string failed");

		assert(mixin (jansson_d.jansson.json_is_integer!("value")), "json_is_integer failed");

		assert(!mixin (jansson_d.jansson.json_is_real!("value")), "json_is_real failed");

		assert(mixin (jansson_d.jansson.json_is_number!("value")), "json_is_number failed");

		assert(!mixin (jansson_d.jansson.json_is_true!("value")), "json_is_true failed");

		assert(!mixin (jansson_d.jansson.json_is_false!("value")), "json_is_false failed");

		assert(!mixin (jansson_d.jansson.json_is_boolean!("value")), "json_is_boolean failed");

		assert(!mixin (jansson_d.jansson.json_is_null!("value")), "json_is_null failed");
	}

	{
		value = jansson_d.value.json_string("foo");

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(value != null, "json_string failed");

		assert(!core.stdc.string.strcmp(jansson_d.value.json_string_value(value), "foo"), "invalid string value");

		assert(jansson_d.value.json_string_length(value) == 3, "invalid string length");

		assert(!jansson_d.value.json_string_set(value, "barr"), "json_string_set failed");

		assert(!core.stdc.string.strcmp(jansson_d.value.json_string_value(value), "barr"), "invalid string value");

		assert(jansson_d.value.json_string_length(value) == 4, "invalid string length");

		assert(!jansson_d.value.json_string_setn(value, "hi\0ho", 5), "json_string_set failed");

		assert(core.stdc.string.memcmp(jansson_d.value.json_string_value(value), &("hi\0ho\0"[0]), 6) == 0, "invalid string value");

		assert(jansson_d.value.json_string_length(value) == 5, "invalid string length");
	}

	{
		value = jansson_d.value.json_string(null);

		assert(value == null, "json_string(null) failed");
	}

	{
		/* invalid UTF-8 */
		value = jansson_d.value.json_string("a\xefz");

		assert(value == null, "json_string(<invalid utf-8>) failed");
	}

	{
		value = jansson_d.value.json_string_nocheck("foo");

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(value != null, "json_string_nocheck failed");

		assert(!core.stdc.string.strcmp(jansson_d.value.json_string_value(value), "foo"), "invalid string value");

		assert(jansson_d.value.json_string_length(value) == 3, "invalid string length");

		assert(!jansson_d.value.json_string_set_nocheck(value, "barr"), "json_string_set_nocheck failed");

		assert(!core.stdc.string.strcmp(jansson_d.value.json_string_value(value), "barr"), "invalid string value");

		assert(jansson_d.value.json_string_length(value) == 4, "invalid string length");

		assert(!jansson_d.value.json_string_setn_nocheck(value, "hi\0ho", 5), "json_string_set failed");

		assert(core.stdc.string.memcmp(jansson_d.value.json_string_value(value), &("hi\0ho\0"[0]), 6) == 0, "invalid string value");

		assert(jansson_d.value.json_string_length(value) == 5, "invalid string length");
	}

	{
		/* invalid UTF-8 */
		value = jansson_d.value.json_string_nocheck("qu\xff");

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(value != null, "json_string_nocheck failed");

		assert(!core.stdc.string.strcmp(jansson_d.value.json_string_value(value), "qu\xff"), "invalid string value");

		assert(jansson_d.value.json_string_length(value) == 3, "invalid string length");

		assert(!jansson_d.value.json_string_set_nocheck(value, "\xfd\xfe\xff"), "json_string_set_nocheck failed");

		assert(!core.stdc.string.strcmp(jansson_d.value.json_string_value(value), "\xfd\xfe\xff"), "invalid string value");

		assert(jansson_d.value.json_string_length(value) == 3, "invalid string length");
	}

	{
		value = jansson_d.value.json_integer(123);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(value != null, "json_integer failed");

		assert(jansson_d.value.json_integer_value(value) == 123, "invalid integer value");

		assert(jansson_d.value.json_number_value(value) == 123.0, "invalid number value");

		assert(!jansson_d.value.json_integer_set(value, 321), "json_integer_set failed");

		assert(jansson_d.value.json_integer_value(value) == 321, "invalid integer value");

		assert(jansson_d.value.json_number_value(value) == 321.0, "invalid number value");
	}

	{
		value = jansson_d.value.json_real(123.123);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(value != null, "json_real failed");

		assert(jansson_d.value.json_real_value(value) == 123.123, "invalid integer value");

		assert(jansson_d.value.json_number_value(value) == 123.123, "invalid number value");

		assert(!jansson_d.value.json_real_set(value, 321.321), "json_real_set failed");

		assert(jansson_d.value.json_real_value(value) == 321.321, "invalid real value");

		assert(jansson_d.value.json_number_value(value) == 321.321, "invalid number value");
	}

	{
		value = jansson_d.value.json_true();

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(value != null, "json_true failed");
	}

	{
		value = jansson_d.value.json_false();

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(value != null, "json_false failed");
	}

	{
		value = jansson_d.value.json_null();

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(value != null, "json_null failed");
	}

	{
		/* Test reference counting on singletons (true, false, null) */
		value = jansson_d.value.json_true();

		scope (exit) {
			jansson_d.jansson.json_decref(value);
		}

		assert(value.refcount == size_t.max, "refcounting true works incorrectly");
	}

	assert(value.refcount == size_t.max, "refcounting true works incorrectly");

	{
		{
			jansson_d.jansson.json_incref(value);
			assert(value.refcount == size_t.max, "refcounting true works incorrectly");
		}

		{
			value = jansson_d.value.json_false();
			assert(value.refcount == size_t.max, "refcounting false works incorrectly");
		}

		{
			jansson_d.jansson.json_decref(value);
			assert(value.refcount == size_t.max, "refcounting false works incorrectly");
		}
	}

	{
		{
			jansson_d.jansson.json_incref(value);
			assert(value.refcount == size_t.max, "refcounting false works incorrectly");
		}

		{
			value = jansson_d.value.json_null();
			assert(value.refcount == size_t.max, "refcounting null works incorrectly");
		}

		{
			jansson_d.jansson.json_decref(value);
			assert(value.refcount == size_t.max, "refcounting null works incorrectly");
		}
	}

	{
		{
			jansson_d.jansson.json_incref(value);

			assert(value.refcount == size_t.max, "refcounting null works incorrectly");
		}

		static if (__traits(compiles, jansson_d.jansson.json_auto_t)) {
			value = jansson_d.value.json_string("foo");

			scope (exit) {
				jansson_d.jansson.json_decref(value);
			}

			{
				jansson_d.jansson.json_auto_t* test = jansson_d.jansson.json_incref(value);

				/* Use test so GCC doesn't complain it is unused. */
				assert(mixin (jansson_d.jansson.json_is_string!("test")), "value type check failed");
			}

			assert(value.refcount == 1, "automatic decrement failed");
		}
	}

	.test_bad_args();
}
