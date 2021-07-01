/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.test.test_array;


private static import jansson_d.dump;
private static import jansson_d.jansson;
private static import jansson_d.pack_unpack;
private static import jansson_d.test.util;
private static import jansson_d.value;

//test_misc
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* array = jansson_d.value.json_array();
	jansson_d.jansson.json_t* five = jansson_d.value.json_integer(5);
	jansson_d.jansson.json_t* seven = jansson_d.value.json_integer(7);

	assert(array != null, "unable to create array");

	assert((five != null) && (seven != null), "unable to create integer");

	assert(jansson_d.value.json_array_size(array) == 0, "empty array has nonzero size");

	assert(jansson_d.jansson.json_array_append(array, null), "able to append null");

	assert(!jansson_d.jansson.json_array_append(array, five), "unable to append");

	assert(jansson_d.value.json_array_size(array) == 1, "wrong array size");

	jansson_d.jansson.json_t* value = jansson_d.value.json_array_get(array, 0);

	assert(value != null, "unable to get item");

	assert(value == five, "got wrong value");

	assert(!jansson_d.jansson.json_array_append(array, seven), "unable to append value");

	assert(jansson_d.value.json_array_size(array) == 2, "wrong array size");

	value = jansson_d.value.json_array_get(array, 1);

	assert(value != null, "unable to get item");

	assert(value == seven, "got wrong value");

	assert(!jansson_d.jansson.json_array_set(array, 0, seven), "unable to set value");

	assert(jansson_d.jansson.json_array_set(array, 0, null), "able to set null");

	assert(jansson_d.value.json_array_size(array) == 2, "wrong array size");

	value = jansson_d.value.json_array_get(array, 0);

	assert(value != null, "unable to get item");

	assert(value == seven, "got wrong value");

	assert(jansson_d.value.json_array_get(array, 2) == null, "able to get value out of bounds");

	assert(jansson_d.jansson.json_array_set(array, 2, seven), "able to set value out of bounds");

	for (size_t i = 2; i < 30; i++) {
		assert(!jansson_d.jansson.json_array_append(array, seven), "unable to append value");

		assert(jansson_d.value.json_array_size(array) == (i + 1), "wrong array size");
	}

	for (size_t i = 0; i < 30; i++) {
		value = jansson_d.value.json_array_get(array, i);

		assert(value != null, "unable to get item");

		assert(value == seven, "got wrong value");
	}

	assert(!jansson_d.value.json_array_set_new(array, 15, jansson_d.value.json_integer(123)), "unable to set new value");

	value = jansson_d.value.json_array_get(array, 15);

	assert((mixin (jansson_d.jansson.json_is_integer!("value"))) && (jansson_d.value.json_integer_value(value) == 123), "json_array_set_new works incorrectly");

	assert(jansson_d.value.json_array_set_new(array, 15, null), "able to set_new null value");

	assert(!jansson_d.value.json_array_append_new(array, jansson_d.value.json_integer(321)), "unable to append new value");

	value = jansson_d.value.json_array_get(array, jansson_d.value.json_array_size(array) - 1);

	assert((mixin (jansson_d.jansson.json_is_integer!("value"))) && (jansson_d.value.json_integer_value(value) == 321), "json_array_append_new works incorrectly");

	assert(jansson_d.value.json_array_append_new(array, null), "able to append_new null value");

	jansson_d.jansson.json_decref(five);
	jansson_d.jansson.json_decref(seven);
	jansson_d.jansson.json_decref(array);
}

//test_insert
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* array = jansson_d.value.json_array();
	jansson_d.jansson.json_t* five = jansson_d.value.json_integer(5);
	jansson_d.jansson.json_t* seven = jansson_d.value.json_integer(7);
	jansson_d.jansson.json_t* eleven = jansson_d.value.json_integer(11);

	assert(array != null, "unable to create array");

	assert((five != null) && (seven != null) && (eleven != null), "unable to create integer");

	assert(jansson_d.jansson.json_array_insert(array, 1, five), "able to insert value out of bounds");

	assert(!jansson_d.jansson.json_array_insert(array, 0, five), "unable to insert value in an empty array");

	assert(jansson_d.value.json_array_get(array, 0) == five, "json_array_insert works incorrectly");

	assert(jansson_d.value.json_array_size(array) == 1, "array size is invalid after insertion");

	assert(!jansson_d.jansson.json_array_insert(array, 1, seven), "unable to insert value at the end of an array");

	assert(jansson_d.value.json_array_get(array, 0) == five, "json_array_insert works incorrectly");

	assert(jansson_d.value.json_array_get(array, 1) == seven, "json_array_insert works incorrectly");

	assert(jansson_d.value.json_array_size(array) == 2, "array size is invalid after insertion");

	assert(!jansson_d.jansson.json_array_insert(array, 1, eleven), "unable to insert value in the middle of an array");

	assert(jansson_d.value.json_array_get(array, 0) == five, "json_array_insert works incorrectly");

	assert(jansson_d.value.json_array_get(array, 1) == eleven, "json_array_insert works incorrectly");

	assert(jansson_d.value.json_array_get(array, 2) == seven, "json_array_insert works incorrectly");

	assert(jansson_d.value.json_array_size(array) == 3, "array size is invalid after insertion");

	assert(!jansson_d.value.json_array_insert_new(array, 2, jansson_d.value.json_integer(123)), "unable to insert value in the middle of an array");

	jansson_d.jansson.json_t* value = jansson_d.value.json_array_get(array, 2);

	assert((mixin (jansson_d.jansson.json_is_integer!("value"))) && (jansson_d.value.json_integer_value(value) == 123), "json_array_insert_new works incorrectly");

	assert(jansson_d.value.json_array_size(array) == 4, "array size is invalid after insertion");

	for (size_t i = 0; i < 20; i++) {
		assert(!jansson_d.jansson.json_array_insert(array, 0, seven), "unable to insert value at the beginning of an array");
	}

	for (size_t i = 0; i < 20; i++) {
		assert(jansson_d.value.json_array_get(array, i) == seven, "json_aray_insert works incorrectly");
	}

	assert(jansson_d.value.json_array_size(array) == 24, "array size is invalid after loop insertion");

	jansson_d.jansson.json_decref(five);
	jansson_d.jansson.json_decref(seven);
	jansson_d.jansson.json_decref(eleven);
	jansson_d.jansson.json_decref(array);
}

//test_remove
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* array = jansson_d.value.json_array();
	jansson_d.jansson.json_t* five = jansson_d.value.json_integer(5);
	jansson_d.jansson.json_t* seven = jansson_d.value.json_integer(7);

	assert(array != null, "unable to create array");

	assert(five != null, "unable to create integer");

	assert(seven != null, "unable to create integer");

	assert(jansson_d.value.json_array_remove(array, 0), "able to remove an unexisting index");

	assert(!jansson_d.jansson.json_array_append(array, five), "unable to append");

	assert(jansson_d.value.json_array_remove(array, 1), "able to remove an unexisting index");

	assert(!jansson_d.value.json_array_remove(array, 0), "unable to remove");

	assert(jansson_d.value.json_array_size(array) == 0, "array size is invalid after removing");

	assert((!jansson_d.jansson.json_array_append(array, five)) && (!jansson_d.jansson.json_array_append(array, seven)) && (!jansson_d.jansson.json_array_append(array, five)) && (!jansson_d.jansson.json_array_append(array, seven)), "unable to append");

	assert(!jansson_d.value.json_array_remove(array, 2), "unable to remove");

	assert(jansson_d.value.json_array_size(array) == 3, "array size is invalid after removing");

	assert((jansson_d.value.json_array_get(array, 0) == five) && (jansson_d.value.json_array_get(array, 1) == seven) && (jansson_d.value.json_array_get(array, 2) == seven), "remove works incorrectly");

	jansson_d.jansson.json_decref(array);

	array = jansson_d.value.json_array();

	for (size_t i = 0; i < 4; i++) {
		jansson_d.jansson.json_array_append(array, five);
		jansson_d.jansson.json_array_append(array, seven);
	}

	assert(jansson_d.value.json_array_size(array) == 8, "unable to append 8 items to array");

	/* Remove an element from a "full" array. */
	jansson_d.value.json_array_remove(array, 5);

	jansson_d.jansson.json_decref(five);
	jansson_d.jansson.json_decref(seven);
	jansson_d.jansson.json_decref(array);
}

//test_clear
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* array = jansson_d.value.json_array();
	jansson_d.jansson.json_t* five = jansson_d.value.json_integer(5);
	jansson_d.jansson.json_t* seven = jansson_d.value.json_integer(7);

	assert(array != null, "unable to create array");

	assert((five != null) && (seven != null), "unable to create integer");

	for (size_t i = 0; i < 10; i++) {
		assert(!jansson_d.jansson.json_array_append(array, five), "unable to append");
	}

	for (size_t i = 0; i < 10; i++) {
		assert(!jansson_d.jansson.json_array_append(array, seven), "unable to append");
	}

	assert(jansson_d.value.json_array_size(array) == 20, "array size is invalid after appending");

	assert(!jansson_d.value.json_array_clear(array), "unable to clear");

	assert(jansson_d.value.json_array_size(array) == 0, "array size is invalid after clearing");

	jansson_d.jansson.json_decref(five);
	jansson_d.jansson.json_decref(seven);
	jansson_d.jansson.json_decref(array);
}

//test_extend
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* array1 = jansson_d.value.json_array();
	jansson_d.jansson.json_t* array2 = jansson_d.value.json_array();
	jansson_d.jansson.json_t* five = jansson_d.value.json_integer(5);
	jansson_d.jansson.json_t* seven = jansson_d.value.json_integer(7);

	assert((array1 != null) && (array2 != null), "unable to create array");

	assert((five != null) && (seven != null), "unable to create integer");

	for (size_t i = 0; i < 10; i++) {
		assert(!jansson_d.jansson.json_array_append(array1, five), "unable to append");
	}

	for (size_t i = 0; i < 10; i++) {
		assert(!jansson_d.jansson.json_array_append(array2, seven), "unable to append");
	}

	assert((jansson_d.value.json_array_size(array1) == 10) && (jansson_d.value.json_array_size(array2) == 10), "array size is invalid after appending");

	assert(!jansson_d.value.json_array_extend(array1, array2), "unable to extend");

	for (size_t i = 0; i < 10; i++) {
		assert(jansson_d.value.json_array_get(array1, i) == five, "invalid array contents after extending");
	}

	for (size_t i = 10; i < 20; i++) {
		assert(jansson_d.value.json_array_get(array1, i) == seven, "invalid array contents after extending");
	}

	jansson_d.jansson.json_decref(five);
	jansson_d.jansson.json_decref(seven);
	jansson_d.jansson.json_decref(array1);
	jansson_d.jansson.json_decref(array2);
}

//test_circular
unittest
{
	/* the simple cases are checked */

	jansson_d.test.util.init_unittest();

	jansson_d.jansson.json_t* array1 = jansson_d.value.json_array();

	assert(array1 != null, "unable to create array");

	assert(jansson_d.jansson.json_array_append(array1, array1) != 0, "able to append self");

	assert(jansson_d.jansson.json_array_insert(array1, 0, array1) != 0, "able to insert self");

	assert(!jansson_d.value.json_array_append_new(array1, jansson_d.value.json_true()), "failed to append true");

	assert(jansson_d.jansson.json_array_set(array1, 0, array1) != 0, "able to set self");

	jansson_d.jansson.json_decref(array1);

	/* create circular references */

	array1 = jansson_d.value.json_array();
	jansson_d.jansson.json_t* array2 = jansson_d.value.json_array();

	assert((array1 != null) && (array2 != null), "unable to create array");

	assert((!jansson_d.jansson.json_array_append(array1, array2)) && (!jansson_d.jansson.json_array_append(array2, array1)), "unable to append");

	/* circularity is detected when dumping */
	assert(jansson_d.dump.json_dumps(array1, 0) == null, "able to dump circulars");

	/* decref twice to deal with the circular references */
	jansson_d.jansson.json_decref(array1);
	jansson_d.jansson.json_decref(array2);
	jansson_d.jansson.json_decref(array1);
}

//test_array_foreach
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* array1 = jansson_d.pack_unpack.json_pack("[sisisi]", &("foo"[0]), 1, &("bar"[0]), 2, &("baz\0"[0]), 3);
	jansson_d.jansson.json_t* array2 = jansson_d.value.json_array();

	size_t index = void;
	jansson_d.jansson.json_t* value = void;

	//jansson_d.jansson.json_array_foreach(array1, index, value)
	for (index = 0; (index < jansson_d.value.json_array_size(array1)) && ((value = jansson_d.value.json_array_get(array1, index)) != null); index++) {
		jansson_d.jansson.json_array_append(array2, value);
	}

	assert(jansson_d.value.json_equal(array1, array2), "json_array_foreach failed to iterate all elements");

	jansson_d.jansson.json_decref(array1);
	jansson_d.jansson.json_decref(array2);
}

//test_bad_args
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* arr = jansson_d.value.json_array();
	jansson_d.jansson.json_t* num = jansson_d.value.json_integer(1);

	assert((arr != null) && (num != null), "failed to create required objects");

	assert(jansson_d.value.json_array_size(null) == 0, "null array has nonzero size");

	assert(jansson_d.value.json_array_size(num) == 0, "non-array has nonzero array size");

	assert(jansson_d.value.json_array_get(null, 0) == null, "json_array_get did not return null for non-array");

	assert(jansson_d.value.json_array_get(num, 0) == null, "json_array_get did not return null for non-array");

	assert(jansson_d.value.json_array_set_new(null, 0, jansson_d.jansson.json_incref(num)), "json_array_set_new did not return error for non-array");

	assert(jansson_d.value.json_array_set_new(num, 0, jansson_d.jansson.json_incref(num)), "json_array_set_new did not return error for non-array");

	assert(jansson_d.value.json_array_set_new(arr, 0, null), "json_array_set_new did not return error for null value");

	assert(jansson_d.value.json_array_set_new(arr, 0, jansson_d.jansson.json_incref(arr)), "json_array_set_new did not return error for value == array");

	assert(jansson_d.value.json_array_remove(null, 0), "json_array_remove did not return error for non-array");

	assert(jansson_d.value.json_array_remove(num, 0), "json_array_remove did not return error for non-array");

	assert(jansson_d.value.json_array_clear(null), "json_array_clear did not return error for non-array");

	assert(jansson_d.value.json_array_clear(num), "json_array_clear did not return error for non-array");

	assert(jansson_d.value.json_array_append_new(null, jansson_d.jansson.json_incref(num)), "json_array_append_new did not return error for non-array");

	assert(jansson_d.value.json_array_append_new(num, jansson_d.jansson.json_incref(num)), "json_array_append_new did not return error for non-array");

	assert(jansson_d.value.json_array_append_new(arr, null), "json_array_append_new did not return error for null value");

	assert(jansson_d.value.json_array_append_new(arr, jansson_d.jansson.json_incref(arr)), "json_array_append_new did not return error for value == array");

	assert(jansson_d.value.json_array_insert_new(null, 0, jansson_d.jansson.json_incref(num)), "json_array_insert_new did not return error for non-array");

	assert(jansson_d.value.json_array_insert_new(num, 0, jansson_d.jansson.json_incref(num)), "json_array_insert_new did not return error for non-array");

	assert(jansson_d.value.json_array_insert_new(arr, 0, null), "json_array_insert_new did not return error for null value");

	assert(jansson_d.value.json_array_insert_new(arr, 0, jansson_d.jansson.json_incref(arr)), "json_array_insert_new did not return error for value == array");

	assert(jansson_d.value.json_array_extend(null, arr), "json_array_extend did not return error for first argument non-array");

	assert(jansson_d.value.json_array_extend(num, arr), "json_array_extend did not return error for first argument non-array");

	assert(jansson_d.value.json_array_extend(arr, null), "json_array_extend did not return error for second argument non-array");

	assert(jansson_d.value.json_array_extend(arr, num), "json_array_extend did not return error for second argument non-array");

	assert(num.refcount == 1, "unexpected reference count on num");

	assert(arr.refcount == 1, "unexpected reference count on arr");

	jansson_d.jansson.json_decref(num);
	jansson_d.jansson.json_decref(arr);
}
