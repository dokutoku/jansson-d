/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.test.test_equal;


private static import jansson_d.jansson;
private static import jansson_d.load;
private static import jansson_d.value;

//test_equal_simple
unittest
{
	assert(!jansson_d.value.json_equal(null, null), "json_equal fails for two NULLs");

	jansson_d.jansson.json_t* value1 = jansson_d.value.json_true();

	assert((!jansson_d.value.json_equal(value1, null)) && (!jansson_d.value.json_equal(null, value1)), "json_equal fails for null");

	/* this covers true, false and null as they are singletons */
	assert(jansson_d.value.json_equal(value1, value1), "identical objects are not equal");

	jansson_d.jansson.json_decref(value1);

	/* integer */
	value1 = jansson_d.value.json_integer(1);
	jansson_d.jansson.json_t* value2 = jansson_d.value.json_integer(1);

	assert((value1 != null) && (value2 != null), "unable to create integers");

	assert(jansson_d.value.json_equal(value1, value2), "json_equal fails for two equal integers");

	jansson_d.jansson.json_decref(value2);

	value2 = jansson_d.value.json_integer(2);

	assert(value2 != null, "unable to create an integer");

	assert(!jansson_d.value.json_equal(value1, value2), "json_equal fails for two inequal integers");

	jansson_d.jansson.json_decref(value1);
	jansson_d.jansson.json_decref(value2);

	/* real */
	value1 = jansson_d.value.json_real(1.2);
	value2 = jansson_d.value.json_real(1.2);

	assert((value1 != null) && (value2 != null), "unable to create reals");

	assert(jansson_d.value.json_equal(value1, value2), "json_equal fails for two equal reals");

	jansson_d.jansson.json_decref(value2);

	value2 = jansson_d.value.json_real(3.141592);

	assert(value2 != null, "unable to create an real");

	assert(!jansson_d.value.json_equal(value1, value2), "json_equal fails for two inequal reals");

	jansson_d.jansson.json_decref(value1);
	jansson_d.jansson.json_decref(value2);

	/* string */
	value1 = jansson_d.value.json_string("foo");
	value2 = jansson_d.value.json_string("foo");

	assert((value1 != null) && (value2 != null), "unable to create strings");

	assert(jansson_d.value.json_equal(value1, value2), "json_equal fails for two equal strings");

	jansson_d.jansson.json_decref(value2);

	value2 = jansson_d.value.json_string("bar");

	assert(value2 != null, "unable to create an string");

	assert(!jansson_d.value.json_equal(value1, value2), "json_equal fails for two inequal strings");

	jansson_d.jansson.json_decref(value2);

	value2 = jansson_d.value.json_string("bar2");

	assert(value2 != null, "unable to create an string");

	assert(!jansson_d.value.json_equal(value1, value2), "json_equal fails for two inequal length strings");

	jansson_d.jansson.json_decref(value1);
	jansson_d.jansson.json_decref(value2);
}

//test_equal_array
unittest
{
	jansson_d.jansson.json_t* array1 = jansson_d.value.json_array();
	jansson_d.jansson.json_t* array2 = jansson_d.value.json_array();

	assert((array1 != null) && (array2 != null), "unable to create arrays");

	assert(jansson_d.value.json_equal(array1, array2), "json_equal fails for two empty arrays");

	jansson_d.value.json_array_append_new(array1, jansson_d.value.json_integer(1));
	jansson_d.value.json_array_append_new(array2, jansson_d.value.json_integer(1));
	jansson_d.value.json_array_append_new(array1, jansson_d.value.json_string("foo"));
	jansson_d.value.json_array_append_new(array2, jansson_d.value.json_string("foo"));
	jansson_d.value.json_array_append_new(array1, jansson_d.value.json_integer(2));
	jansson_d.value.json_array_append_new(array2, jansson_d.value.json_integer(2));

	assert(jansson_d.value.json_equal(array1, array2), "json_equal fails for two equal arrays");

	jansson_d.value.json_array_remove(array2, 2);

	assert(!jansson_d.value.json_equal(array1, array2), "json_equal fails for two inequal arrays");

	jansson_d.value.json_array_append_new(array2, jansson_d.value.json_integer(3));

	assert(!jansson_d.value.json_equal(array1, array2), "json_equal fails for two inequal arrays");

	jansson_d.jansson.json_decref(array1);
	jansson_d.jansson.json_decref(array2);
}

//test_equal_object
unittest
{
	jansson_d.jansson.json_t* object1 = jansson_d.value.json_object();
	jansson_d.jansson.json_t* object2 = jansson_d.value.json_object();

	assert((object1 != null) && (object2 != null), "unable to create objects");

	assert(jansson_d.value.json_equal(object1, object2), "json_equal fails for two empty objects");

	jansson_d.value.json_object_set_new(object1, "a", jansson_d.value.json_integer(1));
	jansson_d.value.json_object_set_new(object2, "a", jansson_d.value.json_integer(1));
	jansson_d.value.json_object_set_new(object1, "b", jansson_d.value.json_string("foo"));
	jansson_d.value.json_object_set_new(object2, "b", jansson_d.value.json_string("foo"));
	jansson_d.value.json_object_set_new(object1, "c", jansson_d.value.json_integer(2));
	jansson_d.value.json_object_set_new(object2, "c", jansson_d.value.json_integer(2));

	assert(jansson_d.value.json_equal(object1, object2), "json_equal fails for two equal objects");

	jansson_d.value.json_object_del(object2, "c");

	assert(!jansson_d.value.json_equal(object1, object2), "json_equal fails for two inequal objects");

	jansson_d.value.json_object_set_new(object2, "c", jansson_d.value.json_integer(3));

	assert(!jansson_d.value.json_equal(object1, object2), "json_equal fails for two inequal objects");

	jansson_d.value.json_object_del(object2, "c");
	jansson_d.value.json_object_set_new(object2, "d", jansson_d.value.json_integer(2));

	assert(!jansson_d.value.json_equal(object1, object2), "json_equal fails for two inequal objects");

	jansson_d.jansson.json_decref(object1);
	jansson_d.jansson.json_decref(object2);
}

//test_equal_complex
unittest
{
	static immutable char* complex_json = "{    \"integer\": 1,     \"real\": 3.141592,     \"string\": \"foobar\",     \"true\": true,     \"object\": {        \"array-in-object\": [1,true,\"foo\",{}],        \"object-in-object\": {\"foo\": \"bar\"}    },    \"array\": [\"foo\", false, null, 1.234]}";

	jansson_d.jansson.json_t* value1 = jansson_d.load.json_loads(complex_json, 0, null);
	jansson_d.jansson.json_t* value2 = jansson_d.load.json_loads(complex_json, 0, null);
	jansson_d.jansson.json_t* value3 = jansson_d.load.json_loads(complex_json, 0, null);

	assert((value1 != null) && (value2 != null), "unable to parse JSON");

	assert(jansson_d.value.json_equal(value1, value2), "json_equal fails for two equal objects");

	jansson_d.value.json_array_set_new(jansson_d.value.json_object_get(jansson_d.value.json_object_get(value2, "object"), "array-in-object"), 1, jansson_d.value.json_false());

	assert(!jansson_d.value.json_equal(value1, value2), "json_equal fails for two inequal objects");

	jansson_d.value.json_object_set_new(jansson_d.value.json_object_get(jansson_d.value.json_object_get(value3, "object"), "object-in-object"), "foo", jansson_d.value.json_string("baz"));

	assert(!jansson_d.value.json_equal(value1, value3), "json_equal fails for two inequal objects");

	jansson_d.jansson.json_decref(value1);
	jansson_d.jansson.json_decref(value2);
	jansson_d.jansson.json_decref(value3);
}
