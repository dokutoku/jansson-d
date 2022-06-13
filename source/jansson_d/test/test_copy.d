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

	/* true */
	jansson_d.jansson.json_t* value = void;
	jansson_d.jansson.json_t* copy = void;

	{
		value = jansson_d.value.json_true();
		copy = jansson_d.value.json_copy(value);

		assert(value == copy, "copying true failed");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}

	{
		/* false */
		value = jansson_d.value.json_false();
		copy = jansson_d.value.json_copy(value);

		assert(value == copy, "copying false failed");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}

	{
		/* null */
		value = jansson_d.value.json_null();
		copy = jansson_d.value.json_copy(value);

		assert(value == copy, "copying null failed");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}

	{
		/* string */
		value = jansson_d.value.json_string("foo");

		assert(value != null, "unable to create a string");

		copy = jansson_d.value.json_copy(value);

		assert(copy != null, "unable to copy a string");

		assert(copy != value, "copying a string doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "copying a string produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}

	{
		/* integer */
		value = jansson_d.value.json_integer(543);

		assert(value != null, "unable to create an integer");

		copy = jansson_d.value.json_copy(value);

		assert(copy != null, "unable to copy an integer");

		assert(copy != value, "copying an integer doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "copying an integer produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}

	{
		/* real */
		value = jansson_d.value.json_real(123e9);

		assert(value != null, "unable to create a real");

		copy = jansson_d.value.json_copy(value);

		assert(copy != null, "unable to copy a real");

		assert(copy != value, "copying a real doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "copying a real produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}
}

//test_deep_copy_simple
unittest
{
	jansson_d.test.util.init_unittest();
	assert(jansson_d.value.json_deep_copy(null) == null, "deep copying null doesn't return null");

	/* true */
	jansson_d.jansson.json_t* value = void;
	jansson_d.jansson.json_t* copy = void;

	{
		value = jansson_d.value.json_true();
		copy = jansson_d.value.json_deep_copy(value);

		assert(value == copy, "deep copying true failed");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}

	{
		/* false */
		value = jansson_d.value.json_false();
		copy = jansson_d.value.json_deep_copy(value);

		assert(value == copy, "deep copying false failed");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}

	{
		/* null */
		value = jansson_d.value.json_null();
		copy = jansson_d.value.json_deep_copy(value);

		assert(value == copy, "deep copying null failed");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}

	{
		/* string */
		value = jansson_d.value.json_string("foo");

		assert(value != null, "unable to create a string");

		copy = jansson_d.value.json_deep_copy(value);

		assert(copy != null, "unable to deep copy a string");

		assert(copy != value, "deep copying a string doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "deep copying a string produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}

	{
		/* integer */
		value = jansson_d.value.json_integer(543);

		assert(value != null, "unable to create an integer");

		copy = jansson_d.value.json_deep_copy(value);

		assert(copy != null, "unable to deep copy an integer");

		assert(copy != value, "deep copying an integer doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "deep copying an integer produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
	}

	{
		/* real */
		value = jansson_d.value.json_real(123e9);

		assert(value != null, "unable to create a real");

		copy = jansson_d.value.json_deep_copy(value);

		assert(copy != null, "unable to deep copy a real");

		assert(copy != value, "deep copying a real doesn't copy");

		assert(jansson_d.value.json_equal(copy, value), "deep copying a real produces an inequal copy");

		assert((value.refcount == 1) && (copy.refcount == 1), "invalid refcounts");

		jansson_d.jansson.json_decref(value);
		jansson_d.jansson.json_decref(copy);
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

	assert(copy != null, "unable to copy an array");

	assert(copy != array, "copying an array doesn't copy");

	assert(jansson_d.value.json_equal(copy, array), "copying an array produces an inequal copy");

	for (size_t i = 0; i < jansson_d.value.json_array_size(copy); i++) {
		assert(jansson_d.value.json_array_get(array, i) == jansson_d.value.json_array_get(copy, i), "copying an array modifies its elements");
	}

	jansson_d.jansson.json_decref(array);
	jansson_d.jansson.json_decref(copy);
}

//test_deep_copy_array
unittest
{
	static immutable char* json_array_text = "[1, \"foo\", 3.141592, {\"foo\": \"bar\"}]";
	jansson_d.test.util.init_unittest();

	jansson_d.jansson.json_t* array = jansson_d.load.json_loads(json_array_text, 0, null);

	assert(array != null, "unable to parse an array");

	jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(array);

	assert(copy != null, "unable to deep copy an array");

	assert(copy != array, "deep copying an array doesn't copy");

	assert(jansson_d.value.json_equal(copy, array), "deep copying an array produces an inequal copy");

	for (size_t i = 0; i < jansson_d.value.json_array_size(copy); i++) {
		assert(jansson_d.value.json_array_get(array, i) != jansson_d.value.json_array_get(copy, i), "deep copying an array doesn't copy its elements");
	}

	jansson_d.jansson.json_decref(array);
	jansson_d.jansson.json_decref(copy);
}

//test_copy_object
unittest
{
	static immutable char* json_object_text = "{\"foo\": \"bar\", \"a\": 1, \"b\": 3.141592, \"c\": [1,2,3,4]}";

	static immutable string[] keys = ["foo\0", "a\0", "b\0", "c\0"];

	jansson_d.test.util.init_unittest();

	jansson_d.jansson.json_t* object = jansson_d.load.json_loads(json_object_text, 0, null);

	assert(object != null, "unable to parse an object");

	jansson_d.jansson.json_t* copy = jansson_d.value.json_copy(object);

	assert(copy != null, "unable to copy an object");

	assert(copy != object, "copying an object doesn't copy");

	assert(jansson_d.value.json_equal(copy, object), "copying an object produces an inequal copy");

	int i = 0;
	void* iter = jansson_d.value.json_object_iter(object);

	while (iter != null) {
		const char* key = jansson_d.value.json_object_iter_key(iter);
		jansson_d.jansson.json_t* value1 = jansson_d.value.json_object_iter_value(iter);
		jansson_d.jansson.json_t* value2 = jansson_d.value.json_object_get(copy, key);

		assert(value1 == value2, "copying an object modifies its items");

		assert(core.stdc.string.strcmp(key, &(keys[i][0])) == 0, "copying an object doesn't preserve key order");

		iter = jansson_d.value.json_object_iter_next(object, iter);
		i++;
	}

	jansson_d.jansson.json_decref(object);
	jansson_d.jansson.json_decref(copy);
}

//test_deep_copy_object
unittest
{
	static immutable char* json_object_text = "{\"foo\": \"bar\", \"a\": 1, \"b\": 3.141592, \"c\": [1,2,3,4]}";

	static immutable string[] keys = ["foo\0", "a\0", "b\0", "c\0"];

	jansson_d.test.util.init_unittest();

	jansson_d.jansson.json_t* object = jansson_d.load.json_loads(json_object_text, 0, null);

	assert(object != null, "unable to parse an object");

	jansson_d.jansson.json_t* copy = jansson_d.value.json_deep_copy(object);

	assert(copy != null, "unable to deep copy an object");

	assert(copy != object, "deep copying an object doesn't copy");

	assert(jansson_d.value.json_equal(copy, object), "deep copying an object produces an inequal copy");

	int i = 0;
	void* iter = jansson_d.value.json_object_iter(object);

	while (iter != null) {
		const char* key = jansson_d.value.json_object_iter_key(iter);
		jansson_d.jansson.json_t* value1 = jansson_d.value.json_object_iter_value(iter);
		jansson_d.jansson.json_t* value2 = jansson_d.value.json_object_get(copy, key);

		assert(value1 != value2, "deep copying an object doesn't copy its items");

		assert(core.stdc.string.strcmp(key, &(keys[i][0])) == 0, "deep copying an object doesn't preserve key order");

		iter = jansson_d.value.json_object_iter_next(object, iter);
		i++;
	}

	jansson_d.jansson.json_decref(object);
	jansson_d.jansson.json_decref(copy);
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

	jansson_d.jansson.json_t* json = void;
	jansson_d.jansson.json_t* copy = void;

	{
		json = jansson_d.value.json_object();
		jansson_d.value.json_object_set_new(json, "a", jansson_d.value.json_object());
		jansson_d.value.json_object_set_new(jansson_d.value.json_object_get(json, "a"), "b", jansson_d.value.json_object());
		jansson_d.jansson.json_object_set(jansson_d.value.json_object_get(jansson_d.value.json_object_get(json, "a"), "b"), "c", jansson_d.value.json_object_get(json, "a"));

		{
			copy = jansson_d.value.json_deep_copy(json);

			assert(copy == null, "json_deep_copy copied a circular reference!");
		}

		jansson_d.value.json_object_del(jansson_d.value.json_object_get(jansson_d.value.json_object_get(json, "a"), "b"), "c");

		{
			copy = jansson_d.value.json_deep_copy(json);

			assert(copy != null, "json_deep_copy failed!");
			jansson_d.jansson.json_decref(copy);
		}

		jansson_d.jansson.json_decref(json);
	}

	{
		json = jansson_d.value.json_array();
		jansson_d.value.json_array_append_new(json, jansson_d.value.json_array());
		jansson_d.value.json_array_append_new(jansson_d.value.json_array_get(json, 0), jansson_d.value.json_array());
		jansson_d.jansson.json_array_append(jansson_d.value.json_array_get(jansson_d.value.json_array_get(json, 0), 0), jansson_d.value.json_array_get(json, 0));

		{
			copy = jansson_d.value.json_deep_copy(json);

			assert(copy == null, "json_deep_copy copied a circular reference!");
		}

		jansson_d.value.json_array_remove(jansson_d.value.json_array_get(jansson_d.value.json_array_get(json, 0), 0), 0);

		{
			copy = jansson_d.value.json_deep_copy(json);

			assert(copy != null, "json_deep_copy failed!");
		}

		jansson_d.jansson.json_decref(copy);
		jansson_d.jansson.json_decref(json);
	}
}
