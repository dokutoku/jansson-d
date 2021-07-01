/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.test.test_object;


private static import core.stdc.stdio;
private static import core.stdc.string;
private static import jansson_d.dump;
private static import jansson_d.jansson;
private static import jansson_d.jansson_private;
private static import jansson_d.pack_unpack;
private static import jansson_d.test.util;
private static import jansson_d.value;

//test_clear
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* object = jansson_d.value.json_object();
	jansson_d.jansson.json_t* ten = jansson_d.value.json_integer(10);

	assert(object != null, "unable to create object");

	assert(ten != null, "unable to create integer");

	assert((!jansson_d.jansson.json_object_set(object, "a", ten)) && (!jansson_d.jansson.json_object_set(object, "b", ten)) && (!jansson_d.jansson.json_object_set(object, "c", ten)) && (!jansson_d.jansson.json_object_set(object, "d", ten)) && (!jansson_d.jansson.json_object_set(object, "e", ten)), "unable to set value");

	assert(jansson_d.value.json_object_size(object) == 5, "invalid size");

	jansson_d.value.json_object_clear(object);

	assert(jansson_d.value.json_object_size(object) == 0, "invalid size after clear");

	jansson_d.jansson.json_decref(ten);
	jansson_d.jansson.json_decref(object);
}

//test_update
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* object = jansson_d.value.json_object();
	jansson_d.jansson.json_t* other = jansson_d.value.json_object();

	jansson_d.jansson.json_t* nine = jansson_d.value.json_integer(9);
	jansson_d.jansson.json_t* ten = jansson_d.value.json_integer(10);

	assert((object != null) && (other != null), "unable to create object");

	assert((nine != null) && (ten != null), "unable to create integer");

	/* update an empty object with an empty object */

	assert(!jansson_d.value.json_object_update(object, other), "unable to update an empty object with an empty object");

	assert(jansson_d.value.json_object_size(object) == 0, "invalid size after update");

	assert(jansson_d.value.json_object_size(other) == 0, "invalid size for updater after update");

	/* update an empty object with a nonempty object */

	assert((!jansson_d.jansson.json_object_set(other, "a", ten)) && (!jansson_d.jansson.json_object_set(other, "b", ten)) && (!jansson_d.jansson.json_object_set(other, "c", ten)) && (!jansson_d.jansson.json_object_set(other, "d", ten)) && (!jansson_d.jansson.json_object_set(other, "e", ten)), "unable to set value");

	assert(!jansson_d.value.json_object_update(object, other), "unable to update an empty object");

	assert(jansson_d.value.json_object_size(object) == 5, "invalid size after update");

	assert((jansson_d.value.json_object_get(object, "a") == ten) && (jansson_d.value.json_object_get(object, "b") == ten) && (jansson_d.value.json_object_get(object, "c") == ten) && (jansson_d.value.json_object_get(object, "d") == ten) && (jansson_d.value.json_object_get(object, "e") == ten), "update works incorrectly");

	/* perform the same update again */

	assert(!jansson_d.value.json_object_update(object, other), "unable to update a non-empty object");

	assert(jansson_d.value.json_object_size(object) == 5, "invalid size after update");

	assert((jansson_d.value.json_object_get(object, "a") == ten) && (jansson_d.value.json_object_get(object, "b") == ten) && (jansson_d.value.json_object_get(object, "c") == ten) && (jansson_d.value.json_object_get(object, "d") == ten) && (jansson_d.value.json_object_get(object, "e") == ten), "update works incorrectly");

	/*
	 * update a nonempty object with a nonempty object with both old
	 * and new keys
	 */

	assert(!jansson_d.value.json_object_clear(other), "clear failed");

	assert((!jansson_d.jansson.json_object_set(other, "a", nine)) && (!jansson_d.jansson.json_object_set(other, "b", nine)) && (!jansson_d.jansson.json_object_set(other, "f", nine)) && (!jansson_d.jansson.json_object_set(other, "g", nine)) && (!jansson_d.jansson.json_object_set(other, "h", nine)), "unable to set value");

	assert(!jansson_d.value.json_object_update(object, other), "unable to update a nonempty object");

	assert(jansson_d.value.json_object_size(object) == 8, "invalid size after update");

	assert((jansson_d.value.json_object_get(object, "a") == nine) && (jansson_d.value.json_object_get(object, "b") == nine) && (jansson_d.value.json_object_get(object, "f") == nine) && (jansson_d.value.json_object_get(object, "g") == nine) && (jansson_d.value.json_object_get(object, "h") == nine), "update works incorrectly");

	/* update_new check */
	assert(!jansson_d.value.json_object_clear(object), "clear failed");

	assert((!jansson_d.jansson.json_object_set(object, "a", ten)) && (!jansson_d.jansson.json_object_set(object, "b", ten)) && (!jansson_d.jansson.json_object_set(object, "c", ten)) && (!jansson_d.jansson.json_object_set(object, "d", ten)) && (!jansson_d.jansson.json_object_set(object, "e", ten)), "unable to set value");

	assert(!jansson_d.jansson.json_object_update_new(object, jansson_d.pack_unpack.json_pack("{s:O, s:O, s:O}", &("b\0"[0]), nine, &("f\0"[0]), nine, &("g\0"[0]), nine)), "unable to update_new a nonempty object");

	assert(jansson_d.value.json_object_size(object) == 7, "invalid size after update_new");

	assert((jansson_d.value.json_object_get(object, "a") == ten) && (jansson_d.value.json_object_get(object, "b") == nine) && (jansson_d.value.json_object_get(object, "c") == ten) && (jansson_d.value.json_object_get(object, "d") == ten) && (jansson_d.value.json_object_get(object, "e") == ten) && (jansson_d.value.json_object_get(object, "f") == nine) && (jansson_d.value.json_object_get(object, "g") == nine), "update_new works incorrectly");

	jansson_d.jansson.json_decref(nine);
	jansson_d.jansson.json_decref(ten);
	jansson_d.jansson.json_decref(other);
	jansson_d.jansson.json_decref(object);
}

//test_set_many_keys
unittest
{
	static immutable char* keys = "abcdefghijklmnopqrstuvwxyz";

	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* object = jansson_d.value.json_object();

	assert(object != null, "unable to create object");

	jansson_d.jansson.json_t* value = jansson_d.value.json_string("a");

	assert(value != null, "unable to create string");

	char[2] buf = void;
	buf[1] = '\0';

	for (size_t i = 0; i < core.stdc.string.strlen(keys); i++) {
		buf[0] = keys[i];

		assert(!jansson_d.jansson.json_object_set(object, &(buf[0]), value), "unable to set object key");
	}

	jansson_d.jansson.json_decref(object);
	jansson_d.jansson.json_decref(value);
}

//test_conditional_updates
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* object = jansson_d.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2);
	jansson_d.jansson.json_t* other = jansson_d.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 3, &("baz\0"[0]), 4);

	assert(!jansson_d.value.json_object_update_existing(object, other), "json_object_update_existing failed");

	assert(jansson_d.value.json_object_size(object) == 2, "json_object_update_existing added new items");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "foo")) == 3, "json_object_update_existing failed to update existing key");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "bar")) == 2, "json_object_update_existing updated wrong key");

	jansson_d.jansson.json_decref(object);

	/* json_object_update_existing_new check */
	object = jansson_d.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2);

	assert(!jansson_d.jansson.json_object_update_existing_new(object, jansson_d.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 3, &("baz\0"[0]), 4)), "json_object_update_existing_new failed");

	assert(jansson_d.value.json_object_size(object) == 2, "json_object_update_existing_new added new items");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "foo")) == 3, "json_object_update_existing_new failed to update existing key");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "bar")) == 2, "json_object_update_existing_new updated wrong key");

	jansson_d.jansson.json_decref(object);

	object = jansson_d.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2);

	assert(!jansson_d.value.json_object_update_missing(object, other), "json_object_update_missing failed");

	assert(jansson_d.value.json_object_size(object) == 3, "json_object_update_missing didn't add new items");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "foo")) == 1, "json_object_update_missing updated existing key");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "bar")) == 2, "json_object_update_missing updated wrong key");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "baz")) == 4, "json_object_update_missing didn't add new items");

	jansson_d.jansson.json_decref(object);

	/* json_object_update_missing_new check */
	object = jansson_d.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2);

	assert(!jansson_d.jansson.json_object_update_missing_new(object, jansson_d.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 3, &("baz\0"[0]), 4)), "json_object_update_missing_new failed");

	assert(jansson_d.value.json_object_size(object) == 3, "json_object_update_missing_new didn't add new items");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "foo")) == 1, "json_object_update_missing_new updated existing key");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "bar")) == 2, "json_object_update_missing_new updated wrong key");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "baz")) == 4, "json_object_update_missing_new didn't add new items");

	jansson_d.jansson.json_decref(object);
	jansson_d.jansson.json_decref(other);
}

//test_recursive_updates
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* invalid = jansson_d.value.json_integer(42);

	jansson_d.jansson.json_t* object = jansson_d.pack_unpack.json_pack("{sis{si}}", &("foo\0"[0]), 1, &("bar\0"[0]), &("baz\0"[0]), 2);
	jansson_d.jansson.json_t* other = jansson_d.pack_unpack.json_pack("{sisisi}", &("foo\0"[0]), 3, &("bar\0"[0]), 4, &("baz\0"[0]), 5);

	assert(jansson_d.value.json_object_update_recursive(invalid, other), "json_object_update_recursive accepted non-object argument");

	jansson_d.jansson.json_decref(invalid);

	assert(!jansson_d.value.json_object_update_recursive(object, other), "json_object_update_recursive failed");

	assert(jansson_d.value.json_object_size(object) == 3, "invalid size after update");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "foo")) == 3, "json_object_update_recursive failed to update existing key");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "bar")) == 4, "json_object_update_recursive failed to overwrite object");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "baz")) == 5, "json_object_update_recursive didn't add new item");

	jansson_d.jansson.json_decref(object);
	jansson_d.jansson.json_decref(other);

	object = jansson_d.pack_unpack.json_pack("{sis{si}}", &("foo\0"[0]), 1, &("bar\0"[0]), &("baz\0"[0]), 2);
	other = jansson_d.pack_unpack.json_pack("{s{si}}", &("bar\0"[0]), &("baz\0"[0]), 3);
	jansson_d.jansson.json_t* barBefore = jansson_d.value.json_object_get(object, "bar");

	assert(barBefore != null, "can't get bar object before json_object_update_recursive");

	assert(!jansson_d.value.json_object_update_recursive(object, other), "json_object_update_recursive failed");

	assert(jansson_d.value.json_object_size(object) == 2, "invalid size after update");

	assert(jansson_d.value.json_object_get(object, "foo") != null, "json_object_update_recursive removed existing key");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(jansson_d.value.json_object_get(object, "bar"), "baz")) == 3, "json_object_update_recursive failed to update nested value");

	jansson_d.jansson.json_t* barAfter = jansson_d.value.json_object_get(object, "bar");

	assert(barAfter != null, "can't get bar object after json_object_update_recursive");

	assert(barBefore == barAfter, "bar object reference changed after json_object_update_recursive");

	jansson_d.jansson.json_decref(object);
	jansson_d.jansson.json_decref(other);

	/* check circular reference */
	object = jansson_d.pack_unpack.json_pack("{s{s{s{si}}}}", &("foo\0"[0]), &("bar\0"[0]), &("baz\0"[0]), &("xxx\0"[0]), 2);
	other = jansson_d.pack_unpack.json_pack("{s{s{si}}}", &("foo\0"[0]), &("bar\0"[0]), &("baz\0"[0]), 2);
	jansson_d.jansson.json_object_set(jansson_d.value.json_object_get(jansson_d.value.json_object_get(other, "foo"), "bar"), "baz", jansson_d.value.json_object_get(other, "foo"));

	assert(jansson_d.value.json_object_update_recursive(object, other), "json_object_update_recursive update a circular reference!");

	jansson_d.value.json_object_set_new(jansson_d.value.json_object_get(jansson_d.value.json_object_get(other, "foo"), "bar"), "baz", jansson_d.value.json_integer(1));

	assert(!jansson_d.value.json_object_update_recursive(object, other), "json_object_update_recursive failed!");

	jansson_d.jansson.json_decref(object);
	jansson_d.jansson.json_decref(other);
}

//test_circular
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* object1 = jansson_d.value.json_object();
	jansson_d.jansson.json_t* object2 = jansson_d.value.json_object();

	assert((object1 != null) && (object2 != null), "unable to create object");

	/* the simple case is checked */
	assert(jansson_d.jansson.json_object_set(object1, "a", object1) != 0, "able to set self");

	/* create circular references */
	if ((jansson_d.jansson.json_object_set(object1, "a", object2)) || (jansson_d.jansson.json_object_set(object2, "a", object1))) {
		assert(false, "unable to set value");
	}

	/* circularity is detected when dumping */
	assert(jansson_d.dump.json_dumps(object1, 0) == null, "able to dump circulars");

	/* decref twice to deal with the circular references */
	jansson_d.jansson.json_decref(object1);
	jansson_d.jansson.json_decref(object2);
	jansson_d.jansson.json_decref(object1);
}

//test_set_nocheck
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* object = jansson_d.value.json_object();
	jansson_d.jansson.json_t* string_ = jansson_d.value.json_string("bar");

	assert(object != null, "unable to create object");

	assert(string_ != null, "unable to create string");

	assert(!jansson_d.jansson.json_object_set_nocheck(object, "foo", string_), "json_object_set_nocheck failed");

	assert(jansson_d.value.json_object_get(object, "foo") == string_, "json_object_get after json_object_set_nocheck failed");

	/* invalid UTF-8 in key */
	assert(!jansson_d.jansson.json_object_set_nocheck(object, "a\xefz", string_), "json_object_set_nocheck failed for invalid UTF-8");

	assert(jansson_d.value.json_object_get(object, "a\xefz") == string_, "json_object_get after json_object_set_nocheck failed");

	assert(!jansson_d.value.json_object_set_new_nocheck(object, "bax", jansson_d.value.json_integer(123)), "json_object_set_new_nocheck failed");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "bax")) == 123, "json_object_get after json_object_set_new_nocheck failed");

	/* invalid UTF-8 in key */
	assert(!jansson_d.value.json_object_set_new_nocheck(object, "asdf\xfe", jansson_d.value.json_integer(321)), "json_object_set_new_nocheck failed for invalid UTF-8");

	assert(jansson_d.value.json_integer_value(jansson_d.value.json_object_get(object, "asdf\xfe")) == 321, "json_object_get after json_object_set_new_nocheck failed");

	jansson_d.jansson.json_decref(string_);
	jansson_d.jansson.json_decref(object);
}

//test_iterators
unittest
{
	jansson_d.test.util.init_unittest();
	assert(jansson_d.value.json_object_iter(null) == null, "able to iterate over null");

	assert(jansson_d.value.json_object_iter_next(null, null) == null, "able to increment an iterator on a null object");

	jansson_d.jansson.json_t* object = jansson_d.value.json_object();
	jansson_d.jansson.json_t* foo = jansson_d.value.json_string("foo");
	jansson_d.jansson.json_t* bar = jansson_d.value.json_string("bar");
	jansson_d.jansson.json_t* baz = jansson_d.value.json_string("baz");

	assert((object != null) && (foo != null) && (bar != null) && (baz != null), "unable to create values");

	assert(jansson_d.value.json_object_iter_next(object, null) == null, "able to increment a null iterator");

	assert((!jansson_d.jansson.json_object_set(object, "a", foo)) && (!jansson_d.jansson.json_object_set(object, "b", bar)) && (!jansson_d.jansson.json_object_set(object, "c", baz)), "unable to populate object");

	void* iter = jansson_d.value.json_object_iter(object);

	assert(iter != null, "unable to get iterator");

	assert(core.stdc.string.strcmp(jansson_d.value.json_object_iter_key(iter), "a") == 0, "iterating doesn't yield keys in order");

	assert(jansson_d.value.json_object_iter_value(iter) == foo, "iterating doesn't yield values in order");

	iter = jansson_d.value.json_object_iter_next(object, iter);

	assert(iter != null, "unable to increment iterator");

	assert(core.stdc.string.strcmp(jansson_d.value.json_object_iter_key(iter), "b") == 0, "iterating doesn't yield keys in order");

	assert(jansson_d.value.json_object_iter_value(iter) == bar, "iterating doesn't yield values in order");

	iter = jansson_d.value.json_object_iter_next(object, iter);

	assert(iter != null, "unable to increment iterator");

	assert(core.stdc.string.strcmp(jansson_d.value.json_object_iter_key(iter), "c") == 0, "iterating doesn't yield keys in order");

	assert(jansson_d.value.json_object_iter_value(iter) == baz, "iterating doesn't yield values in order");

	assert(jansson_d.value.json_object_iter_next(object, iter) == null, "able to iterate over the end");

	assert(jansson_d.value.json_object_iter_at(object, "foo") == null, "json_object_iter_at() succeeds for non-existent key");

	iter = jansson_d.value.json_object_iter_at(object, "b");

	assert(iter != null, "json_object_iter_at() fails for an existing key");

	assert(!core.stdc.string.strcmp(jansson_d.value.json_object_iter_key(iter), "b"), "iterating failed: wrong key");

	assert(jansson_d.value.json_object_iter_value(iter) == bar, "iterating failed: wrong value");

	assert(!jansson_d.jansson.json_object_iter_set(object, iter, baz), "unable to set value at iterator");

	assert(!core.stdc.string.strcmp(jansson_d.value.json_object_iter_key(iter), "b"), "json_object_iter_key() fails after json_object_iter_set()");

	assert(jansson_d.value.json_object_iter_value(iter) == baz, "json_object_iter_value() fails after json_object_iter_set()");

	assert(jansson_d.value.json_object_get(object, "b") == baz, "json_object_get() fails after json_object_iter_set()");

	jansson_d.jansson.json_decref(object);
	jansson_d.jansson.json_decref(foo);
	jansson_d.jansson.json_decref(bar);
	jansson_d.jansson.json_decref(baz);
}

//test_misc
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* object = jansson_d.value.json_object();
	jansson_d.jansson.json_t* string_ = jansson_d.value.json_string("test");
	jansson_d.jansson.json_t* other_string = jansson_d.value.json_string("other");

	assert(object != null, "unable to create object");

	assert((string_ != null) && (other_string != null), "unable to create string");

	assert(jansson_d.value.json_object_get(object, "a") == null, "value for nonexisting key");

	assert(!jansson_d.jansson.json_object_set(object, "a", string_), "unable to set value");

	assert(jansson_d.jansson.json_object_set(object, null, string_), "able to set null key");

	assert(!jansson_d.value.json_object_del(object, "a"), "unable to del the only key");

	assert(!jansson_d.jansson.json_object_set(object, "a", string_), "unable to set value");

	assert(jansson_d.jansson.json_object_set(object, "a", null), "able to set null value");

	/* invalid UTF-8 in key */
	assert(jansson_d.jansson.json_object_set(object, "a\xefz", string_), "able to set invalid unicode key");

	jansson_d.jansson.json_t* value = jansson_d.value.json_object_get(object, "a");

	assert(value != null, "no value for existing key");

	assert(value == string_, "got different value than what was added");

	/* "a", "lp" and "px" collide in a five-bucket hashtable */
	assert((!jansson_d.jansson.json_object_set(object, "b", string_)) && (!jansson_d.jansson.json_object_set(object, "lp", string_)) && (!jansson_d.jansson.json_object_set(object, "px", string_)), "unable to set value");

	value = jansson_d.value.json_object_get(object, "a");

	assert(value != null, "no value for existing key");

	assert(value == string_, "got different value than what was added");

	assert(!jansson_d.jansson.json_object_set(object, "a", other_string), "unable to replace an existing key");

	value = jansson_d.value.json_object_get(object, "a");

	assert(value != null, "no value for existing key");

	assert(value == other_string, "got different value than what was set");

	assert(jansson_d.value.json_object_del(object, "nonexisting"), "able to delete a nonexisting key");

	assert(!jansson_d.value.json_object_del(object, "px"), "unable to delete an existing key");

	assert(!jansson_d.value.json_object_del(object, "a"), "unable to delete an existing key");

	assert(!jansson_d.value.json_object_del(object, "lp"), "unable to delete an existing key");

	/* add many keys to initiate rehashing */

	assert(!jansson_d.jansson.json_object_set(object, "a", string_), "unable to set value");

	assert(!jansson_d.jansson.json_object_set(object, "lp", string_), "unable to set value");

	assert(!jansson_d.jansson.json_object_set(object, "px", string_), "unable to set value");

	assert(!jansson_d.jansson.json_object_set(object, "c", string_), "unable to set value");

	assert(!jansson_d.jansson.json_object_set(object, "d", string_), "unable to set value");

	assert(!jansson_d.jansson.json_object_set(object, "e", string_), "unable to set value");

	assert(!jansson_d.value.json_object_set_new(object, "foo", jansson_d.value.json_integer(123)), "unable to set new value");

	value = jansson_d.value.json_object_get(object, "foo");

	assert((mixin (jansson_d.jansson.json_is_integer!("value"))) && (jansson_d.value.json_integer_value(value) == 123), "json_object_set_new works incorrectly");

	assert(jansson_d.value.json_object_set_new(object, null, jansson_d.value.json_integer(432)), "able to set_new null key");

	assert(jansson_d.value.json_object_set_new(object, "foo", null), "able to set_new null value");

	jansson_d.jansson.json_decref(string_);
	jansson_d.jansson.json_decref(other_string);
	jansson_d.jansson.json_decref(object);
}

//test_preserve_order
unittest
{
	static immutable char* expected = "{\"foobar\": 1, \"bazquux\": 6, \"lorem ipsum\": 3, \"sit amet\": 5, \"helicopter\": 7}";

	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* object = jansson_d.value.json_object();

	jansson_d.value.json_object_set_new(object, "foobar", jansson_d.value.json_integer(1));
	jansson_d.value.json_object_set_new(object, "bazquux", jansson_d.value.json_integer(2));
	jansson_d.value.json_object_set_new(object, "lorem ipsum", jansson_d.value.json_integer(3));
	jansson_d.value.json_object_set_new(object, "dolor", jansson_d.value.json_integer(4));
	jansson_d.value.json_object_set_new(object, "sit amet", jansson_d.value.json_integer(5));

	/* changing a value should preserve the order */
	jansson_d.value.json_object_set_new(object, "bazquux", jansson_d.value.json_integer(6));

	/* deletion shouldn't change the order of others */
	jansson_d.value.json_object_del(object, "dolor");

	/* add a new item just to make sure */
	jansson_d.value.json_object_set_new(object, "helicopter", jansson_d.value.json_integer(7));

	char* result = jansson_d.dump.json_dumps(object, jansson_d.jansson.JSON_PRESERVE_ORDER);

	if (core.stdc.string.strcmp(expected, result) != 0) {
		core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "%s != %s", expected, result);
		assert(false, "JSON_PRESERVE_ORDER doesn't work");
	}

	jansson_d.jansson_private.jsonp_free(result);
	jansson_d.jansson.json_decref(object);
}

//test_object_foreach
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* object1 = jansson_d.pack_unpack.json_pack("{sisisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2, &("baz\0"[0]), 3);
	jansson_d.jansson.json_t* object2 = jansson_d.value.json_object();

	const (char)* key = void;
	jansson_d.jansson.json_t* value = void;

	//jansson_d.jansson.json_object_foreach(object1, key, value)
	for (key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter(object1)); (key != null) && ((value = jansson_d.value.json_object_iter_value(jansson_d.value.json_object_key_to_iter(key))) != null); key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter_next(object1, jansson_d.value.json_object_key_to_iter(key)))) {
		jansson_d.jansson.json_object_set(object2, key, value);
	}

	assert(jansson_d.value.json_equal(object1, object2), "json_object_foreach failed to iterate all key-value pairs");

	jansson_d.jansson.json_decref(object1);
	jansson_d.jansson.json_decref(object2);
}

//test_object_foreach_safe
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* object = jansson_d.pack_unpack.json_pack("{sisisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2, &("baz\0"[0]), 3);

	const (char)* key = void;
	void* tmp = void;
	jansson_d.jansson.json_t* value = void;

	//jansson_d.jansson.json_object_foreach_safe(object, tmp, key, value)
	for (key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter(object)), tmp = jansson_d.value.json_object_iter_next(object, jansson_d.value.json_object_key_to_iter(key)); (key != null) && ((value = jansson_d.value.json_object_iter_value(jansson_d.value.json_object_key_to_iter(key))) != null); key = jansson_d.value.json_object_iter_key(tmp), tmp = jansson_d.value.json_object_iter_next(object, jansson_d.value.json_object_key_to_iter(key))) {
		jansson_d.value.json_object_del(object, key);
	}

	assert(jansson_d.value.json_object_size(object) == 0, "json_object_foreach_safe failed to iterate all key-value pairs");

	jansson_d.jansson.json_decref(object);
}

//test_bad_args
unittest
{
	jansson_d.test.util.init_unittest();
	jansson_d.jansson.json_t* obj = jansson_d.value.json_object();
	jansson_d.jansson.json_t* num = jansson_d.value.json_integer(1);

	assert((obj != null) && (num != null), "failed to allocate test objects");

	assert(!jansson_d.jansson.json_object_set(obj, "testkey", jansson_d.value.json_null()), "failed to set testkey on object");

	void* iter = jansson_d.value.json_object_iter(obj);

	assert(iter != null, "failed to retrieve test iterator");

	assert(jansson_d.value.json_object_size(null) == 0, "json_object_size with non-object argument returned non-zero");

	assert(jansson_d.value.json_object_size(num) == 0, "json_object_size with non-object argument returned non-zero");

	assert(jansson_d.value.json_object_get(null, "test") == null, "json_object_get with non-object argument returned non-null");

	assert(jansson_d.value.json_object_get(num, "test") == null, "json_object_get with non-object argument returned non-null");

	assert(jansson_d.value.json_object_get(obj, null) == null, "json_object_get with null key returned non-null");

	assert(jansson_d.value.json_object_set_new_nocheck(null, "test", jansson_d.value.json_null()), "json_object_set_new_nocheck with non-object argument did not return error");

	assert(jansson_d.value.json_object_set_new_nocheck(num, "test", jansson_d.value.json_null()), "json_object_set_new_nocheck with non-object argument did not return error");

	assert(jansson_d.value.json_object_set_new_nocheck(obj, "test", jansson_d.jansson.json_incref(obj)), "json_object_set_new_nocheck with object == value did not return error");

	assert(jansson_d.value.json_object_set_new_nocheck(obj, null, jansson_d.value.json_object()), "json_object_set_new_nocheck with null key did not return error");

	assert(jansson_d.value.json_object_del(null, "test"), "json_object_del with non-object argument did not return error");

	assert(jansson_d.value.json_object_del(num, "test"), "json_object_del with non-object argument did not return error");

	assert(jansson_d.value.json_object_del(obj, null), "json_object_del with null key did not return error");

	assert(jansson_d.value.json_object_clear(null), "json_object_clear with non-object argument did not return error");

	assert(jansson_d.value.json_object_clear(num), "json_object_clear with non-object argument did not return error");

	assert(jansson_d.value.json_object_update(null, obj), "json_object_update with non-object first argument did not return error");

	assert(jansson_d.value.json_object_update(num, obj), "json_object_update with non-object first argument did not return error");

	assert(jansson_d.value.json_object_update(obj, null), "json_object_update with non-object second argument did not return error");

	assert(jansson_d.value.json_object_update(obj, num), "json_object_update with non-object second argument did not return error");

	assert(jansson_d.value.json_object_update_existing(null, obj), "json_object_update_existing with non-object first argument did not return error");

	assert(jansson_d.value.json_object_update_existing(num, obj), "json_object_update_existing with non-object first argument did not return error");

	assert(jansson_d.value.json_object_update_existing(obj, null), "json_object_update_existing with non-object second argument did not return error");

	assert(jansson_d.value.json_object_update_existing(obj, num), "json_object_update_existing with non-object second argument did not return error");

	assert(jansson_d.value.json_object_update_missing(null, obj), "json_object_update_missing with non-object first argument did not return error");

	assert(jansson_d.value.json_object_update_missing(num, obj), "json_object_update_missing with non-object first argument did not return error");

	assert(jansson_d.value.json_object_update_missing(obj, null), "json_object_update_missing with non-object second argument did not return error");

	assert(jansson_d.value.json_object_update_missing(obj, num), "json_object_update_missing with non-object second argument did not return error");

	assert(jansson_d.value.json_object_iter(null) == null, "json_object_iter with non-object argument returned non-null");

	assert(jansson_d.value.json_object_iter(num) == null, "json_object_iter with non-object argument returned non-null");

	assert(jansson_d.value.json_object_iter_at(null, "test") == null, "json_object_iter_at with non-object argument returned non-null");

	assert(jansson_d.value.json_object_iter_at(num, "test") == null, "json_object_iter_at with non-object argument returned non-null");

	assert(jansson_d.value.json_object_iter_at(obj, null) == null, "json_object_iter_at with null iter returned non-null");

	assert(jansson_d.value.json_object_iter_next(obj, null) == null, "json_object_iter_next with null iter returned non-null");

	assert(jansson_d.value.json_object_iter_next(num, iter) == null, "json_object_iter_next with non-object argument returned non-null");

	assert(jansson_d.value.json_object_iter_key(null) == null, "json_object_iter_key with null iter returned non-null");

	assert(jansson_d.value.json_object_key_to_iter(null) == null, "json_object_key_to_iter with null iter returned non-null");

	assert(jansson_d.value.json_object_iter_value(null) == null, "json_object_iter_value with null iter returned non-null");

	assert(jansson_d.value.json_object_iter_set_new(null, iter, jansson_d.jansson.json_incref(num)), "json_object_iter_set_new with non-object argument did not return error");

	assert(jansson_d.value.json_object_iter_set_new(num, iter, jansson_d.jansson.json_incref(num)), "json_object_iter_set_new with non-object argument did not return error");

	assert(jansson_d.value.json_object_iter_set_new(obj, null, jansson_d.jansson.json_incref(num)), "json_object_iter_set_new with null iter did not return error");

	assert(jansson_d.value.json_object_iter_set_new(obj, iter, null), "json_object_iter_set_new with null value did not return error");

	assert(obj.refcount == 1, "unexpected reference count for obj");

	assert(num.refcount == 1, "unexpected reference count for num");

	jansson_d.jansson.json_decref(obj);
	jansson_d.jansson.json_decref(num);
}
