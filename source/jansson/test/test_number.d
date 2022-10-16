/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.test_number;


private static import core.stdc.math;
private static import jansson.jansson;
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
		jansson.jansson.json_t* real_ = jansson.value.json_real(core.stdc.math.INFINITY);

		assert(real_ == null, "could construct a real from Inf");
	}

	{
		jansson.jansson.json_t* real_ = jansson.value.json_real(1.0);

		scope (exit) {
			jansson.jansson.json_decref(real_);
		}

		assert(jansson.value.json_real_set(real_, core.stdc.math.INFINITY) == -1, "could set a real to Inf");

		assert(jansson.value.json_real_value(real_) == 1.0, "real value changed unexpectedly");
	}
}

//test_bad_args
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* txt = jansson.value.json_string("test");

	scope (exit) {
		jansson.jansson.json_decref(txt);
	}

	assert(jansson.value.json_integer_value(null) == 0, "json_integer_value did not return 0 for non-integer");

	assert(jansson.value.json_integer_value(txt) == 0, "json_integer_value did not return 0 for non-integer");

	assert(jansson.value.json_integer_set(null, 0), "json_integer_set did not return error for non-integer");

	assert(jansson.value.json_integer_set(txt, 0), "json_integer_set did not return error for non-integer");

	assert(jansson.value.json_real_value(null) == 0.0, "json_real_value did not return 0.0 for non-real");

	assert(jansson.value.json_real_value(txt) == 0.0, "json_real_value did not return 0.0 for non-real");

	assert(jansson.value.json_real_set(null, 0.0), "json_real_set did not return error for non-real");

	assert(jansson.value.json_real_set(txt, 0.0), "json_real_set did not return error for non-real");

	assert(jansson.value.json_number_value(null) == 0.0, "json_number_value did not return 0.0 for non-numeric");

	assert(jansson.value.json_number_value(txt) == 0.0, "json_number_value did not return 0.0 for non-numeric");

	assert(txt.refcount == 1, "unexpected reference count for txt");
}

//run_tests
unittest
{
	jansson.test.util.init_unittest();

	{
		jansson.jansson.json_t* integer = jansson.value.json_integer(5);
		jansson.jansson.json_t* real_ = jansson.value.json_real(100.1);

		scope (exit) {
			jansson.jansson.json_decref(integer);
			jansson.jansson.json_decref(real_);
		}

		{
			assert(integer != null, "unable to create integer");

			assert(real_ != null, "unable to create real");
		}

		{
			jansson.jansson.json_int_t i = jansson.value.json_integer_value(integer);

			assert(i == 5, "wrong integer value");
		}

		{
			double d = jansson.value.json_real_value(real_);

			assert(d == 100.1, "wrong real value");
		}

		{
			double d = jansson.value.json_number_value(integer);

			assert(d == 5.0, "wrong number value");
		}

		{
			double d = jansson.value.json_number_value(real_);

			assert(d == 100.1, "wrong number value");
		}
	}

	static assert(__traits(compiles, core.stdc.math.NAN));

	{
		jansson.jansson.json_t* real_ = jansson.value.json_real(core.stdc.math.NAN);

		assert(real_ == null, "could construct a real from NaN");
	}

	{
		jansson.jansson.json_t* real_ = jansson.value.json_real(1.0);

		scope (exit) {
			jansson.jansson.json_decref(real_);
		}

		assert(jansson.value.json_real_set(real_, core.stdc.math.NAN) == -1, "could set a real to NaN");

		assert(jansson.value.json_real_value(real_) == 1.0, "real value changed unexpectedly");
	}
}
