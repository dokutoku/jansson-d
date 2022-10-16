/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.test_equal;


private static import jansson.jansson;
private static import jansson.load;
private static import jansson.test.util;
private static import jansson.value;

//test_equal_simple
unittest
{
	jansson.test.util.init_unittest();
	assert(!jansson.value.json_equal(null, null), "json_equal fails for two NULLs");

	{
		jansson.jansson.json_t* value1 = jansson.value.json_true();

		scope (exit) {
			jansson.jansson.json_decref(value1);
		}

		assert((!jansson.value.json_equal(value1, null)) && (!jansson.value.json_equal(null, value1)), "json_equal fails for null");

		/* this covers true, false and null as they are singletons */
		assert(jansson.value.json_equal(value1, value1), "identical objects are not equal");
	}

	{
		/* integer */

		{
			jansson.jansson.json_t* value1 = jansson.value.json_integer(1);
			jansson.jansson.json_t* value2 = jansson.value.json_integer(1);

			scope (exit) {
				jansson.jansson.json_decref(value1);
				jansson.jansson.json_decref(value2);
			}

			assert((value1 != null) && (value2 != null), "unable to create integers");

			assert(jansson.value.json_equal(value1, value2), "json_equal fails for two equal integers");
		}

		{
			jansson.jansson.json_t* value1 = jansson.value.json_integer(1);
			jansson.jansson.json_t* value2 = jansson.value.json_integer(2);

			scope (exit) {
				jansson.jansson.json_decref(value1);
				jansson.jansson.json_decref(value2);
			}

			assert((value1 != null) && (value2 != null), "unable to create an integer");

			assert(!jansson.value.json_equal(value1, value2), "json_equal fails for two inequal integers");
		}
	}

	{
		/* real */

		{
			jansson.jansson.json_t* value1 = jansson.value.json_real(1.2);
			jansson.jansson.json_t* value2 = jansson.value.json_real(1.2);

			scope (exit) {
				jansson.jansson.json_decref(value1);
				jansson.jansson.json_decref(value2);
			}

			assert((value1 != null) && (value2 != null), "unable to create reals");

			assert(jansson.value.json_equal(value1, value2), "json_equal fails for two equal reals");
		}

		{
			jansson.jansson.json_t* value1 = jansson.value.json_real(1.2);
			jansson.jansson.json_t* value2 = jansson.value.json_real(3.141592);

			scope (exit) {
				jansson.jansson.json_decref(value1);
				jansson.jansson.json_decref(value2);
			}

			assert((value1 != null) && (value2 != null), "unable to create an real");

			assert(!jansson.value.json_equal(value1, value2), "json_equal fails for two inequal reals");
		}
	}

	/* string */
	{
		{
			jansson.jansson.json_t* value1 = jansson.value.json_string("foo");
			jansson.jansson.json_t* value2 = jansson.value.json_string("foo");

			scope (exit) {
				jansson.jansson.json_decref(value1);
				jansson.jansson.json_decref(value2);
			}

			assert((value1 != null) && (value2 != null), "unable to create strings");

			assert(jansson.value.json_equal(value1, value2), "json_equal fails for two equal strings");
		}

		{
			jansson.jansson.json_t* value1 = jansson.value.json_string("foo");
			jansson.jansson.json_t* value2 = jansson.value.json_string("bar");

			scope (exit) {
				jansson.jansson.json_decref(value1);
				jansson.jansson.json_decref(value2);
			}

			assert((value1 != null) && (value2 != null), "unable to create an string");

			assert(!jansson.value.json_equal(value1, value2), "json_equal fails for two inequal strings");
		}

		{
			jansson.jansson.json_t* value1 = jansson.value.json_string("foo");
			jansson.jansson.json_t* value2 = jansson.value.json_string("bar2");

			scope (exit) {
				jansson.jansson.json_decref(value1);
				jansson.jansson.json_decref(value2);
			}

			assert(value2 != null, "unable to create an string");

			assert(!jansson.value.json_equal(value1, value2), "json_equal fails for two inequal length strings");
		}
	}
}

//test_equal_array
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* array1 = jansson.value.json_array();
	jansson.jansson.json_t* array2 = jansson.value.json_array();

	scope (exit) {
		jansson.jansson.json_decref(array1);
		jansson.jansson.json_decref(array2);
	}

	assert((array1 != null) && (array2 != null), "unable to create arrays");

	assert(jansson.value.json_equal(array1, array2), "json_equal fails for two empty arrays");

	jansson.value.json_array_append_new(array1, jansson.value.json_integer(1));
	jansson.value.json_array_append_new(array2, jansson.value.json_integer(1));
	jansson.value.json_array_append_new(array1, jansson.value.json_string("foo"));
	jansson.value.json_array_append_new(array2, jansson.value.json_string("foo"));
	jansson.value.json_array_append_new(array1, jansson.value.json_integer(2));
	jansson.value.json_array_append_new(array2, jansson.value.json_integer(2));

	assert(jansson.value.json_equal(array1, array2), "json_equal fails for two equal arrays");

	jansson.value.json_array_remove(array2, 2);

	assert(!jansson.value.json_equal(array1, array2), "json_equal fails for two inequal arrays");

	jansson.value.json_array_append_new(array2, jansson.value.json_integer(3));

	assert(!jansson.value.json_equal(array1, array2), "json_equal fails for two inequal arrays");
}

//test_equal_object
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* object1 = jansson.value.json_object();
	jansson.jansson.json_t* object2 = jansson.value.json_object();

	scope (exit) {
		jansson.jansson.json_decref(object1);
		jansson.jansson.json_decref(object2);
	}

	assert((object1 != null) && (object2 != null), "unable to create objects");

	assert(jansson.value.json_equal(object1, object2), "json_equal fails for two empty objects");

	jansson.value.json_object_set_new(object1, "a", jansson.value.json_integer(1));
	jansson.value.json_object_set_new(object2, "a", jansson.value.json_integer(1));
	jansson.value.json_object_set_new(object1, "b", jansson.value.json_string("foo"));
	jansson.value.json_object_set_new(object2, "b", jansson.value.json_string("foo"));
	jansson.value.json_object_set_new(object1, "c", jansson.value.json_integer(2));
	jansson.value.json_object_set_new(object2, "c", jansson.value.json_integer(2));

	assert(jansson.value.json_equal(object1, object2), "json_equal fails for two equal objects");

	jansson.value.json_object_del(object2, "c");

	assert(!jansson.value.json_equal(object1, object2), "json_equal fails for two inequal objects");

	jansson.value.json_object_set_new(object2, "c", jansson.value.json_integer(3));

	assert(!jansson.value.json_equal(object1, object2), "json_equal fails for two inequal objects");

	jansson.value.json_object_del(object2, "c");
	jansson.value.json_object_set_new(object2, "d", jansson.value.json_integer(2));

	assert(!jansson.value.json_equal(object1, object2), "json_equal fails for two inequal objects");
}

//test_equal_complex
unittest
{
	static immutable char* complex_json = "{    \"integer\": 1,     \"real\": 3.141592,     \"string\": \"foobar\",     \"true\": true,     \"object\": {        \"array-in-object\": [1,true,\"foo\",{}],        \"object-in-object\": {\"foo\": \"bar\"}    },    \"array\": [\"foo\", false, null, 1.234]}";

	jansson.test.util.init_unittest();
	jansson.jansson.json_t* value1 = jansson.load.json_loads(complex_json, 0, null);
	jansson.jansson.json_t* value2 = jansson.load.json_loads(complex_json, 0, null);
	jansson.jansson.json_t* value3 = jansson.load.json_loads(complex_json, 0, null);

	scope (exit) {
		jansson.jansson.json_decref(value1);
		jansson.jansson.json_decref(value2);
		jansson.jansson.json_decref(value3);
	}

	assert((value1 != null) && (value2 != null), "unable to parse JSON");

	assert(jansson.value.json_equal(value1, value2), "json_equal fails for two equal objects");

	jansson.value.json_array_set_new(jansson.value.json_object_get(jansson.value.json_object_get(value2, "object"), "array-in-object"), 1, jansson.value.json_false());

	assert(!jansson.value.json_equal(value1, value2), "json_equal fails for two inequal objects");

	jansson.value.json_object_set_new(jansson.value.json_object_get(jansson.value.json_object_get(value3, "object"), "object-in-object"), "foo", jansson.value.json_string("baz"));

	assert(!jansson.value.json_equal(value1, value3), "json_equal fails for two inequal objects");
}
