/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.test.test_copy;


private static import core.stdc.string;
private static import jansson_d.jansson;
private static import jansson_d.load;
private static import jansson_d.test.util;
private static import jansson_d.value;

//test_copy_simple
unittest
{
	jansson_d.test.util.init_unittest();
	assert(!jansson_d.value.json_copy(null), "copying null doesn't return null");

	{
		/* true */
		jansson_d.jansson.json_t* value = jansson_d.value.json_true();
		jansson_d.jansson.json_t* copy = jansson_d.value.json_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(value == copy, "copying true failed");
	}

	{
		/* false */
		jansson_d.jansson.json_t* value = jansson_d.value.json_false();
		jansson_d.jansson.json_t* copy = jansson_d.value.json_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(value == copy, "copying false failed");
	}

	{
		/* null */
		jansson_d.jansson.json_t* value = jansson_d.value.json_null();
		jansson_d.jansson.json_t* copy = jansson_d.value.json_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(value == copy, "copying null failed");
	}

	{
		/* string */
		jansson_d.jansson.json_t* value = jansson_d.value.json_string("foo");

		assert(value != null, "unable to create a string");

		jansson_d.jansson.json_t* copy = jansson_d.value.json_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(copy != null, "unable to copy a string");

		assert(copy != value, "copying a string doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "copying a string produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");
	}

	{
		/* integer */
		jansson_d.jansson.json_t* value = jansson_d.value.json_integer(543);

		assert(value != null, "unable to create an integer");

		jansson_d.jansson.json_t* copy = jansson_d.value.json_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(copy != null, "unable to copy an integer");

		assert(copy != value, "copying an integer doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "copying an integer produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");
	}

	{
		/* real */
		jansson_d.jansson.json_t* value = jansson_d.value.json_real(123e9);

		assert(value != null, "unable to create a real");

		jansson_d.jansson.json_t* copy = jansson_d.value.json_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(copy != null, "unable to copy a real");

		assert(copy != value, "copying a real doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "copying a real produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");
	}
}

//test_deep_copy_simple
unittest
{
	jansson_d.test.util.init_unittest();
	assert(jansson_d.value.json_deep_copy(null) == null, "deep copying null doesn't return null");

	{
		/* true */
		jansson_d.jansson.json_t* value = jansson_d.value.json_true();
		jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(value == copy, "deep copying true failed");
	}

	{
		/* false */
		jansson_d.jansson.json_t* value = jansson_d.value.json_false();
		jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(value == copy, "deep copying false failed");
	}

	{
		/* null */
		jansson_d.jansson.json_t* value = jansson_d.value.json_null();
		jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(value == copy, "deep copying null failed");
	}

	{
		/* string */
		jansson_d.jansson.json_t* value = jansson_d.value.json_string("foo");

		assert(value != null, "unable to create a string");

		jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(copy != null, "unable to deep copy a string");

		assert(copy != value, "deep copying a string doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "deep copying a string produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");
	}

	{
		/* integer */
		jansson_d.jansson.json_t* value = jansson_d.value.json_integer(543);

		assert(value != null, "unable to create an integer");

		jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(copy != null, "unable to deep copy an integer");

		assert(copy != value, "deep copying an integer doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "deep copying an integer produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");
	}

	{
		/* real */
		jansson_d.jansson.json_t* value = jansson_d.value.json_real(123e9);

		assert(value != null, "unable to create a real");

		jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(value);

		scope (exit) {
			jansson_d.jansson.json_decref(value);
			jansson_d.jansson.json_decref(copy);
		}

		assert(copy != null, "unable to deep copy a real");

		assert(copy != value, "deep copying a real doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "deep copying a real produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");
	}
}

//test_copy_array
unittest
{
	static immutable char* json_array_text = "[1, \"foo\", 3.141592, {\"foo\": \"bar\"}]";
	jansson_d.test.util.init_unittest();

	jansson_d.jansson.json_t* array = jansson_d.load.json_loads(json_array_text, 0, null);

	assert(array != null, "unable to parse an array");

	jansson_d.jansson.json_t* copy = jansson_d.value.json_copy(array);

	scope (exit) {
		jansson_d.jansson.json_decref(array);
		jansson_d.jansson.json_decref(copy);
	}

	assert(copy != null, "unable to copy an array");

	assert(copy != array, "copying an array doesn't copy");

	assert(jansson_d.value.json_equal(copy, array), "copying an array produces an inequal copy");

	for (size_t i = 0; i < jansson_d.value.json_array_size(copy); i++) {
		assert(jansson_d.value.json_array_get(array, i) == jansson_d.value.json_array_get(copy, i), "copying an array modifies its elements");
	}
}

//test_deep_copy_array
unittest
{
	static immutable char* json_array_text = "[1, \"foo\", 3.141592, {\"foo\": \"bar\"}]";
	jansson_d.test.util.init_unittest();

	jansson_d.jansson.json_t* array = jansson_d.load.json_loads(json_array_text, 0, null);

	assert(array != null, "unable to parse an array");

	jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(array);

	scope (exit) {
		jansson_d.jansson.json_decref(array);
		jansson_d.jansson.json_decref(copy);
	}

	assert(copy != null, "unable to deep copy an array");

	assert(copy != array, "deep copying an array doesn't copy");

	assert(jansson_d.value.json_equal(copy, array), "deep copying an array produces an inequal copy");

	for (size_t i = 0; i < jansson_d.value.json_array_size(copy); i++) {
		assert(jansson_d.value.json_array_get(array, i) != jansson_d.value.json_array_get(copy, i), "deep copying an array doesn't copy its elements");
	}
}

//test_copy_object
unittest
{
	static immutable char* json_object_text = "{\"foo\": \"bar\", \"a\": 1, \"b\": 3.141592, \"c\": [1,2,3,4]}";

	static immutable string[] keys = ["foo\0", "a\0", "b\0", "c\0"];

	jansson_d.test.util.init_unittest();

	jansson_d.jansson.json_t* object_ = jansson_d.load.json_loads(json_object_text, 0, null);

	assert(object_ != null, "unable to parse an object");

	jansson_d.jansson.json_t* copy = jansson_d.value.json_copy(object_);

	scope (exit) {
		jansson_d.jansson.json_decref(object_);
		jansson_d.jansson.json_decref(copy);
	}

	assert(copy != null, "unable to copy an object");

	assert(copy != object_, "copying an object doesn't copy");

	assert(jansson_d.value.json_equal(copy, object_), "copying an object produces an inequal copy");

	size_t i = 0;

	for (void* iter = jansson_d.value.json_object_iter(object_); iter != null; iter = jansson_d.value.json_object_iter_next(object_, iter), i++) {
		const char* key = jansson_d.value.json_object_iter_key(iter);
		jansson_d.jansson.json_t* value1 = jansson_d.value.json_object_iter_value(iter);
		jansson_d.jansson.json_t* value2 = jansson_d.value.json_object_get(copy, key);

		assert(value1 == value2, "copying an object modifies its items");

		assert(core.stdc.string.strcmp(key, &(keys[i][0])) == 0, "copying an object doesn't preserve key order");
	}
}

//test_deep_copy_object
unittest
{
	static immutable char* json_object_text = "{\"foo\": \"bar\", \"a\": 1, \"b\": 3.141592, \"c\": [1,2,3,4]}";

	static immutable string[] keys = ["foo\0", "a\0", "b\0", "c\0"];

	jansson_d.test.util.init_unittest();

	jansson_d.jansson.json_t* object_ = jansson_d.load.json_loads(json_object_text, 0, null);

	assert(object_ != null, "unable to parse an object");

	jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(object_);

	scope (exit) {
		jansson_d.jansson.json_decref(object_);
		jansson_d.jansson.json_decref(copy);
	}

	assert(copy != null, "unable to deep copy an object");

	assert(copy != object_, "deep copying an object doesn't copy");

	assert(jansson_d.value.json_equal(copy, object_), "deep copying an object produces an inequal copy");

	size_t i = 0;

	for (void* iter = jansson_d.value.json_object_iter(object_); iter != null; iter = jansson_d.value.json_object_iter_next(object_, iter), i++) {
		const char* key = jansson_d.value.json_object_iter_key(iter);
		jansson_d.jansson.json_t* value1 = jansson_d.value.json_object_iter_value(iter);
		jansson_d.jansson.json_t* value2 = jansson_d.value.json_object_get(copy, key);

		assert(value1 != value2, "deep copying an object doesn't copy its items");

		assert(core.stdc.string.strcmp(key, &(keys[i][0])) == 0, "deep copying an object doesn't preserve key order");
	}
}

//test_deep_copy_circular_references
unittest
{
	/*
	 * Construct a JSON object/array with a circular reference:
	 *
	 * object: {"a": {"b": {"c": <circular reference to $.a>}}}
	 * array: [[[<circular reference to the $[0] array>]]]
	 *
	 * Deep copy it, remove the circular reference and deep copy again.
	 */

	jansson_d.test.util.init_unittest();

	{
		jansson_d.jansson.json_t* json = jansson_d.value.json_object();

		scope (exit) {
			jansson_d.jansson.json_decref(json);
		}

		jansson_d.value.json_object_set_new(json, "a", jansson_d.value.json_object());
		jansson_d.value.json_object_set_new(jansson_d.value.json_object_get(json, "a"), "b", jansson_d.value.json_object());
		jansson_d.jansson.json_object_set(jansson_d.value.json_object_get(jansson_d.value.json_object_get(json, "a"), "b"), "c", jansson_d.value.json_object_get(json, "a"));

		{
			jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(json);

			assert(copy == null, "json_deep_copy copied a circular reference!");
		}

		jansson_d.value.json_object_del(jansson_d.value.json_object_get(jansson_d.value.json_object_get(json, "a"), "b"), "c");

		{
			jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(json);

			assert(copy != null, "json_deep_copy failed!");
			jansson_d.jansson.json_decref(copy);
		}
	}

	{
		jansson_d.jansson.json_t* json = jansson_d.value.json_array();
		jansson_d.value.json_array_append_new(json, jansson_d.value.json_array());
		jansson_d.value.json_array_append_new(jansson_d.value.json_array_get(json, 0), jansson_d.value.json_array());
		jansson_d.jansson.json_array_append(jansson_d.value.json_array_get(jansson_d.value.json_array_get(json, 0), 0), jansson_d.value.json_array_get(json, 0));

		scope (exit) {
			jansson_d.jansson.json_decref(json);
		}

		{
			jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(json);

			assert(copy == null, "json_deep_copy copied a circular reference!");
		}

		jansson_d.value.json_array_remove(jansson_d.value.json_array_get(jansson_d.value.json_array_get(json, 0), 0), 0);

		{
			jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(json);

			assert(copy != null, "json_deep_copy failed!");

			scope (exit) {
				jansson_d.jansson.json_decref(copy);
			}
		}
	}
}
