/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.test_object;


private static import core.stdc.stdio;
private static import core.stdc.string;
private static import jansson.dump;
private static import jansson.jansson;
private static import jansson.jansson_private;
private static import jansson.pack_unpack;
private static import jansson.test.util;
private static import jansson.value;

//test_clear
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* object_ = jansson.value.json_object();
	jansson.jansson.json_t* ten = jansson.value.json_integer(10);

	scope (exit) {
		jansson.jansson.json_decref(ten);
		jansson.jansson.json_decref(object_);
	}

	assert(object_ != null, "unable to create object");

	assert(ten != null, "unable to create integer");

	assert((!jansson.jansson.json_object_set(object_, "a", ten)) && (!jansson.jansson.json_object_set(object_, "b", ten)) && (!jansson.jansson.json_object_set(object_, "c", ten)) && (!jansson.jansson.json_object_set(object_, "d", ten)) && (!jansson.jansson.json_object_set(object_, "e", ten)), "unable to set value");

	assert(jansson.value.json_object_size(object_) == 5, "invalid size");

	jansson.value.json_object_clear(object_);

	assert(jansson.value.json_object_size(object_) == 0, "invalid size after clear");
}

//test_update
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* object_ = jansson.value.json_object();
	jansson.jansson.json_t* other = jansson.value.json_object();

	jansson.jansson.json_t* nine = jansson.value.json_integer(9);
	jansson.jansson.json_t* ten = jansson.value.json_integer(10);

	scope (exit) {
		jansson.jansson.json_decref(nine);
		jansson.jansson.json_decref(ten);
		jansson.jansson.json_decref(other);
		jansson.jansson.json_decref(object_);
	}

	assert((object_ != null) && (other != null), "unable to create object");

	assert((nine != null) && (ten != null), "unable to create integer");

	/* update an empty object with an empty object */

	assert(!jansson.value.json_object_update(object_, other), "unable to update an empty object with an empty object");

	assert(jansson.value.json_object_size(object_) == 0, "invalid size after update");

	assert(jansson.value.json_object_size(other) == 0, "invalid size for updater after update");

	/* update an empty object with a nonempty object */

	assert((!jansson.jansson.json_object_set(other, "a", ten)) && (!jansson.jansson.json_object_set(other, "b", ten)) && (!jansson.jansson.json_object_set(other, "c", ten)) && (!jansson.jansson.json_object_set(other, "d", ten)) && (!jansson.jansson.json_object_set(other, "e", ten)), "unable to set value");

	assert(!jansson.value.json_object_update(object_, other), "unable to update an empty object");

	assert(jansson.value.json_object_size(object_) == 5, "invalid size after update");

	assert((jansson.value.json_object_get(object_, "a") == ten) && (jansson.value.json_object_get(object_, "b") == ten) && (jansson.value.json_object_get(object_, "c") == ten) && (jansson.value.json_object_get(object_, "d") == ten) && (jansson.value.json_object_get(object_, "e") == ten), "update works incorrectly");

	/* perform the same update again */

	assert(!jansson.value.json_object_update(object_, other), "unable to update a non-empty object");

	assert(jansson.value.json_object_size(object_) == 5, "invalid size after update");

	assert((jansson.value.json_object_get(object_, "a") == ten) && (jansson.value.json_object_get(object_, "b") == ten) && (jansson.value.json_object_get(object_, "c") == ten) && (jansson.value.json_object_get(object_, "d") == ten) && (jansson.value.json_object_get(object_, "e") == ten), "update works incorrectly");

	/*
	 * update a nonempty object with a nonempty object with both old
	 * and new keys
	 */

	assert(!jansson.value.json_object_clear(other), "clear failed");

	assert((!jansson.jansson.json_object_set(other, "a", nine)) && (!jansson.jansson.json_object_set(other, "b", nine)) && (!jansson.jansson.json_object_set(other, "f", nine)) && (!jansson.jansson.json_object_set(other, "g", nine)) && (!jansson.jansson.json_object_set(other, "h", nine)), "unable to set value");

	assert(!jansson.value.json_object_update(object_, other), "unable to update a nonempty object");

	assert(jansson.value.json_object_size(object_) == 8, "invalid size after update");

	assert((jansson.value.json_object_get(object_, "a") == nine) && (jansson.value.json_object_get(object_, "b") == nine) && (jansson.value.json_object_get(object_, "f") == nine) && (jansson.value.json_object_get(object_, "g") == nine) && (jansson.value.json_object_get(object_, "h") == nine), "update works incorrectly");

	/* update_new check */
	assert(!jansson.value.json_object_clear(object_), "clear failed");

	assert((!jansson.jansson.json_object_set(object_, "a", ten)) && (!jansson.jansson.json_object_set(object_, "b", ten)) && (!jansson.jansson.json_object_set(object_, "c", ten)) && (!jansson.jansson.json_object_set(object_, "d", ten)) && (!jansson.jansson.json_object_set(object_, "e", ten)), "unable to set value");

	assert(!jansson.jansson.json_object_update_new(object_, jansson.pack_unpack.json_pack("{s:O, s:O, s:O}", &("b\0"[0]), nine, &("f\0"[0]), nine, &("g\0"[0]), nine)), "unable to update_new a nonempty object");

	assert(jansson.value.json_object_size(object_) == 7, "invalid size after update_new");

	assert((jansson.value.json_object_get(object_, "a") == ten) && (jansson.value.json_object_get(object_, "b") == nine) && (jansson.value.json_object_get(object_, "c") == ten) && (jansson.value.json_object_get(object_, "d") == ten) && (jansson.value.json_object_get(object_, "e") == ten) && (jansson.value.json_object_get(object_, "f") == nine) && (jansson.value.json_object_get(object_, "g") == nine), "update_new works incorrectly");
}

//test_set_many_keys
unittest
{
	static immutable char* keys = "abcdefghijklmnopqrstuvwxyz";

	jansson.test.util.init_unittest();
	jansson.jansson.json_t* object_ = jansson.value.json_object();
	jansson.jansson.json_t* value = jansson.value.json_string("a");

	scope (exit) {
		jansson.jansson.json_decref(object_);
		jansson.jansson.json_decref(value);
	}

	assert(object_ != null, "unable to create object");
	assert(value != null, "unable to create string");

	char[2] buf = void;
	buf[1] = '\0';

	for (size_t i = 0; i < core.stdc.string.strlen(keys); i++) {
		buf[0] = keys[i];

		assert(!jansson.jansson.json_object_set(object_, &(buf[0]), value), "unable to set object key");
	}
}

//test_conditional_updates
unittest
{
	jansson.test.util.init_unittest();

	{
		jansson.jansson.json_t* other = jansson.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 3, &("baz\0"[0]), 4);

		scope (exit) {
			jansson.jansson.json_decref(other);
		}

		{
			jansson.jansson.json_t* object_ = jansson.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2);

			scope (exit) {
				jansson.jansson.json_decref(object_);
			}

			assert(!jansson.value.json_object_update_existing(object_, other), "json_object_update_existing failed");

			assert(jansson.value.json_object_size(object_) == 2, "json_object_update_existing added new items");

			assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "foo")) == 3, "json_object_update_existing failed to update existing key");

			assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "bar")) == 2, "json_object_update_existing updated wrong key");
		}

		{
			/* json_object_update_existing_new check */
			jansson.jansson.json_t* object_ = jansson.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2);

			scope (exit) {
				jansson.jansson.json_decref(object_);
			}

			assert(!jansson.jansson.json_object_update_existing_new(object_, jansson.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 3, &("baz\0"[0]), 4)), "json_object_update_existing_new failed");

			assert(jansson.value.json_object_size(object_) == 2, "json_object_update_existing_new added new items");

			assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "foo")) == 3, "json_object_update_existing_new failed to update existing key");

			assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "bar")) == 2, "json_object_update_existing_new updated wrong key");
		}

		{
			jansson.jansson.json_t* object_ = jansson.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2);

			scope (exit) {
				jansson.jansson.json_decref(object_);
			}

			assert(!jansson.value.json_object_update_missing(object_, other), "json_object_update_missing failed");

			assert(jansson.value.json_object_size(object_) == 3, "json_object_update_missing didn't add new items");

			assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "foo")) == 1, "json_object_update_missing updated existing key");

			assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "bar")) == 2, "json_object_update_missing updated wrong key");

			assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "baz")) == 4, "json_object_update_missing didn't add new items");
		}
	}

	{
		/* json_object_update_missing_new check */
		jansson.jansson.json_t* object_ = jansson.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2);

		scope (exit) {
			jansson.jansson.json_decref(object_);
		}

		assert(!jansson.jansson.json_object_update_missing_new(object_, jansson.pack_unpack.json_pack("{sisi}", &("foo\0"[0]), 3, &("baz\0"[0]), 4)), "json_object_update_missing_new failed");

		assert(jansson.value.json_object_size(object_) == 3, "json_object_update_missing_new didn't add new items");

		assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "foo")) == 1, "json_object_update_missing_new updated existing key");

		assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "bar")) == 2, "json_object_update_missing_new updated wrong key");

		assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "baz")) == 4, "json_object_update_missing_new didn't add new items");
	}
}

//test_recursive_updates
unittest
{
	jansson.test.util.init_unittest();

	{
		jansson.jansson.json_t* invalid = jansson.value.json_integer(42);
		jansson.jansson.json_t* object_ = jansson.pack_unpack.json_pack("{sis{si}}", &("foo\0"[0]), 1, &("bar\0"[0]), &("baz\0"[0]), 2);
		jansson.jansson.json_t* other = jansson.pack_unpack.json_pack("{sisisi}", &("foo\0"[0]), 3, &("bar\0"[0]), 4, &("baz\0"[0]), 5);

		scope (exit) {
			jansson.jansson.json_decref(invalid);
			jansson.jansson.json_decref(object_);
			jansson.jansson.json_decref(other);
		}

		assert(jansson.value.json_object_update_recursive(invalid, other), "json_object_update_recursive accepted non-object argument");

		assert(!jansson.value.json_object_update_recursive(object_, other), "json_object_update_recursive failed");

		assert(jansson.value.json_object_size(object_) == 3, "invalid size after update");

		assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "foo")) == 3, "json_object_update_recursive failed to update existing key");

		assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "bar")) == 4, "json_object_update_recursive failed to overwrite object");

		assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "baz")) == 5, "json_object_update_recursive didn't add new item");
	}

	{
		jansson.jansson.json_t* object_ = jansson.pack_unpack.json_pack("{sis{si}}", &("foo\0"[0]), 1, &("bar\0"[0]), &("baz\0"[0]), 2);
		jansson.jansson.json_t* other = jansson.pack_unpack.json_pack("{s{si}}", &("bar\0"[0]), &("baz\0"[0]), 3);
		jansson.jansson.json_t* barBefore = jansson.value.json_object_get(object_, "bar");

		scope (exit) {
			jansson.jansson.json_decref(object_);
			jansson.jansson.json_decref(other);
		}

		assert(barBefore != null, "can't get bar object before json_object_update_recursive");

		assert(!jansson.value.json_object_update_recursive(object_, other), "json_object_update_recursive failed");

		assert(jansson.value.json_object_size(object_) == 2, "invalid size after update");

		assert(jansson.value.json_object_get(object_, "foo") != null, "json_object_update_recursive removed existing key");

		assert(jansson.value.json_integer_value(jansson.value.json_object_get(jansson.value.json_object_get(object_, "bar"), "baz")) == 3, "json_object_update_recursive failed to update nested value");

		jansson.jansson.json_t* barAfter = jansson.value.json_object_get(object_, "bar");

		assert(barAfter != null, "can't get bar object after json_object_update_recursive");

		assert(barBefore == barAfter, "bar object reference changed after json_object_update_recursive");
	}

	{
		/* check circular reference */
		jansson.jansson.json_t* object_ = jansson.pack_unpack.json_pack("{s{s{s{si}}}}", &("foo\0"[0]), &("bar\0"[0]), &("baz\0"[0]), &("xxx\0"[0]), 2);
		jansson.jansson.json_t* other = jansson.pack_unpack.json_pack("{s{s{si}}}", &("foo\0"[0]), &("bar\0"[0]), &("baz\0"[0]), 2);

		scope (exit) {
			jansson.jansson.json_decref(object_);
			jansson.jansson.json_decref(other);
		}

		jansson.jansson.json_object_set(jansson.value.json_object_get(jansson.value.json_object_get(other, "foo"), "bar"), "baz", jansson.value.json_object_get(other, "foo"));

		assert(jansson.value.json_object_update_recursive(object_, other), "json_object_update_recursive update a circular reference!");

		jansson.value.json_object_set_new(jansson.value.json_object_get(jansson.value.json_object_get(other, "foo"), "bar"), "baz", jansson.value.json_integer(1));

		assert(!jansson.value.json_object_update_recursive(object_, other), "json_object_update_recursive failed!");
	}
}

//test_circular
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* object1 = jansson.value.json_object();
	jansson.jansson.json_t* object2 = jansson.value.json_object();

	scope (exit) {
		/* decref twice to deal with the circular references */
		jansson.jansson.json_decref(object1);
		jansson.jansson.json_decref(object2);
		jansson.jansson.json_decref(object1);
	}

	assert((object1 != null) && (object2 != null), "unable to create object");

	/* the simple case is checked */
	assert(jansson.jansson.json_object_set(object1, "a", object1) != 0, "able to set self");

	/* create circular references */
	assert((jansson.jansson.json_object_set(object1, "a", object2) == 0) && (jansson.jansson.json_object_set(object2, "a", object1) == 0), "unable to set value");

	/* circularity is detected when dumping */
	assert(jansson.dump.json_dumps(object1, 0) == null, "able to dump circulars");
}

//test_set_nocheck
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* object_ = jansson.value.json_object();
	jansson.jansson.json_t* string_ = jansson.value.json_string("bar");

	scope (exit) {
		jansson.jansson.json_decref(string_);
		jansson.jansson.json_decref(object_);
	}

	assert(object_ != null, "unable to create object");

	assert(string_ != null, "unable to create string");

	assert(!jansson.jansson.json_object_set_nocheck(object_, "foo", string_), "json_object_set_nocheck failed");

	assert(jansson.value.json_object_get(object_, "foo") == string_, "json_object_get after json_object_set_nocheck failed");

	/* invalid UTF-8 in key */
	assert(!jansson.jansson.json_object_set_nocheck(object_, "a\xefz", string_), "json_object_set_nocheck failed for invalid UTF-8");

	assert(jansson.value.json_object_get(object_, "a\xefz") == string_, "json_object_get after json_object_set_nocheck failed");

	assert(!jansson.value.json_object_set_new_nocheck(object_, "bax", jansson.value.json_integer(123)), "json_object_set_new_nocheck failed");

	assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "bax")) == 123, "json_object_get after json_object_set_new_nocheck failed");

	/* invalid UTF-8 in key */
	assert(!jansson.value.json_object_set_new_nocheck(object_, "asdf\xfe", jansson.value.json_integer(321)), "json_object_set_new_nocheck failed for invalid UTF-8");

	assert(jansson.value.json_integer_value(jansson.value.json_object_get(object_, "asdf\xfe")) == 321, "json_object_get after json_object_set_new_nocheck failed");
}

//test_iterators
unittest
{
	jansson.test.util.init_unittest();
	assert(jansson.value.json_object_iter(null) == null, "able to iterate over null");

	assert(jansson.value.json_object_iter_next(null, null) == null, "able to increment an iterator on a null object");

	jansson.jansson.json_t* object_ = jansson.value.json_object();
	jansson.jansson.json_t* foo = jansson.value.json_string("foo");
	jansson.jansson.json_t* bar = jansson.value.json_string("bar");
	jansson.jansson.json_t* baz = jansson.value.json_string("baz");

	scope (exit) {
		jansson.jansson.json_decref(object_);
		jansson.jansson.json_decref(foo);
		jansson.jansson.json_decref(bar);
		jansson.jansson.json_decref(baz);
	}

	assert((object_ != null) && (foo != null) && (bar != null) && (baz != null), "unable to create values");

	assert(jansson.value.json_object_iter_next(object_, null) == null, "able to increment a null iterator");

	assert((!jansson.jansson.json_object_set(object_, "a", foo)) && (!jansson.jansson.json_object_set(object_, "b", bar)) && (!jansson.jansson.json_object_set(object_, "c", baz)), "unable to populate object");

	{
		void* iter = jansson.value.json_object_iter(object_);

		assert(iter != null, "unable to get iterator");

		assert(core.stdc.string.strcmp(jansson.value.json_object_iter_key(iter), "a") == 0, "iterating doesn't yield keys in order");

		assert(jansson.value.json_object_iter_value(iter) == foo, "iterating doesn't yield values in order");

		iter = jansson.value.json_object_iter_next(object_, iter);

		assert(iter != null, "unable to increment iterator");

		assert(core.stdc.string.strcmp(jansson.value.json_object_iter_key(iter), "b") == 0, "iterating doesn't yield keys in order");

		assert(jansson.value.json_object_iter_value(iter) == bar, "iterating doesn't yield values in order");

		iter = jansson.value.json_object_iter_next(object_, iter);

		assert(iter != null, "unable to increment iterator");

		assert(core.stdc.string.strcmp(jansson.value.json_object_iter_key(iter), "c") == 0, "iterating doesn't yield keys in order");

		assert(jansson.value.json_object_iter_value(iter) == baz, "iterating doesn't yield values in order");

		assert(jansson.value.json_object_iter_next(object_, iter) == null, "able to iterate over the end");
	}

	assert(jansson.value.json_object_iter_at(object_, "foo") == null, "json_object_iter_at() succeeds for non-existent key");

	{
		void* iter = jansson.value.json_object_iter_at(object_, "b");

		assert(iter != null, "json_object_iter_at() fails for an existing key");

		assert(!core.stdc.string.strcmp(jansson.value.json_object_iter_key(iter), "b"), "iterating failed: wrong key");

		assert(jansson.value.json_object_iter_value(iter) == bar, "iterating failed: wrong value");

		assert(!jansson.jansson.json_object_iter_set(object_, iter, baz), "unable to set value at iterator");

		assert(!core.stdc.string.strcmp(jansson.value.json_object_iter_key(iter), "b"), "json_object_iter_key() fails after json_object_iter_set()");

		assert(jansson.value.json_object_iter_value(iter) == baz, "json_object_iter_value() fails after json_object_iter_set()");
	}

	assert(jansson.value.json_object_get(object_, "b") == baz, "json_object_get() fails after json_object_iter_set()");
}

//test_misc
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* object_ = jansson.value.json_object();
	jansson.jansson.json_t* string_ = jansson.value.json_string("test");
	jansson.jansson.json_t* other_string = jansson.value.json_string("other");

	scope (exit) {
		jansson.jansson.json_decref(string_);
		jansson.jansson.json_decref(other_string);
		jansson.jansson.json_decref(object_);
	}

	assert(object_ != null, "unable to create object");

	assert((string_ != null) && (other_string != null), "unable to create string");

	assert(jansson.value.json_object_get(object_, "a") == null, "value for nonexisting key");

	assert(!jansson.jansson.json_object_set(object_, "a", string_), "unable to set value");

	assert(jansson.jansson.json_object_set(object_, null, string_), "able to set null key");

	assert(!jansson.value.json_object_del(object_, "a"), "unable to del the only key");

	assert(!jansson.jansson.json_object_set(object_, "a", string_), "unable to set value");

	assert(jansson.jansson.json_object_set(object_, "a", null), "able to set null value");

	/* invalid UTF-8 in key */
	assert(jansson.jansson.json_object_set(object_, "a\xefz", string_), "able to set invalid unicode key");

	{
		jansson.jansson.json_t* value = jansson.value.json_object_get(object_, "a");

		assert(value != null, "no value for existing key");

		assert(value == string_, "got different value than what was added");
	}

	/* "a", "lp" and "px" collide in a five-bucket hashtable */
	assert((!jansson.jansson.json_object_set(object_, "b", string_)) && (!jansson.jansson.json_object_set(object_, "lp", string_)) && (!jansson.jansson.json_object_set(object_, "px", string_)), "unable to set value");

	{
		jansson.jansson.json_t* value = jansson.value.json_object_get(object_, "a");

		assert(value != null, "no value for existing key");

		assert(value == string_, "got different value than what was added");
	}

	assert(!jansson.jansson.json_object_set(object_, "a", other_string), "unable to replace an existing key");

	{
		jansson.jansson.json_t* value = jansson.value.json_object_get(object_, "a");

		assert(value != null, "no value for existing key");

		assert(value == other_string, "got different value than what was set");
	}

	assert(jansson.value.json_object_del(object_, "nonexisting"), "able to delete a nonexisting key");

	assert(!jansson.value.json_object_del(object_, "px"), "unable to delete an existing key");

	assert(!jansson.value.json_object_del(object_, "a"), "unable to delete an existing key");

	assert(!jansson.value.json_object_del(object_, "lp"), "unable to delete an existing key");

	/* add many keys to initiate rehashing */

	assert(!jansson.jansson.json_object_set(object_, "a", string_), "unable to set value");

	assert(!jansson.jansson.json_object_set(object_, "lp", string_), "unable to set value");

	assert(!jansson.jansson.json_object_set(object_, "px", string_), "unable to set value");

	assert(!jansson.jansson.json_object_set(object_, "c", string_), "unable to set value");

	assert(!jansson.jansson.json_object_set(object_, "d", string_), "unable to set value");

	assert(!jansson.jansson.json_object_set(object_, "e", string_), "unable to set value");

	assert(!jansson.value.json_object_set_new(object_, "foo", jansson.value.json_integer(123)), "unable to set new value");

	{
		jansson.jansson.json_t* value = jansson.value.json_object_get(object_, "foo");

		assert((mixin (jansson.jansson.json_is_integer!("value"))) && (jansson.value.json_integer_value(value) == 123), "json_object_set_new works incorrectly");
	}

	assert(jansson.value.json_object_set_new(object_, null, jansson.value.json_integer(432)), "able to set_new null key");

	assert(jansson.value.json_object_set_new(object_, "foo", null), "able to set_new null value");
}

//test_preserve_order
unittest
{
	static immutable char* expected = "{\"foobar\": 1, \"bazquux\": 6, \"lorem ipsum\": 3, \"sit amet\": 5, \"helicopter\": 7}";

	jansson.test.util.init_unittest();
	jansson.jansson.json_t* object_ = jansson.value.json_object();

	scope (exit) {
		jansson.jansson.json_decref(object_);
	}

	jansson.value.json_object_set_new(object_, "foobar", jansson.value.json_integer(1));
	jansson.value.json_object_set_new(object_, "bazquux", jansson.value.json_integer(2));
	jansson.value.json_object_set_new(object_, "lorem ipsum", jansson.value.json_integer(3));
	jansson.value.json_object_set_new(object_, "dolor", jansson.value.json_integer(4));
	jansson.value.json_object_set_new(object_, "sit amet", jansson.value.json_integer(5));

	/* changing a value should preserve the order */
	jansson.value.json_object_set_new(object_, "bazquux", jansson.value.json_integer(6));

	/* deletion shouldn't change the order of others */
	jansson.value.json_object_del(object_, "dolor");

	/* add a new item just to make sure */
	jansson.value.json_object_set_new(object_, "helicopter", jansson.value.json_integer(7));

	char* result = jansson.dump.json_dumps(object_, jansson.jansson.JSON_PRESERVE_ORDER);

	scope (exit) {
		jansson.jansson_private.jsonp_free(result);
	}

	if (core.stdc.string.strcmp(expected, result) != 0) {
		core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "%s != %s", expected, result);
		assert(false, "JSON_PRESERVE_ORDER doesn't work");
	}
}

//test_object_foreach
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* object1 = jansson.pack_unpack.json_pack("{sisisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2, &("baz\0"[0]), 3);
	jansson.jansson.json_t* object2 = jansson.value.json_object();

	scope (exit) {
		jansson.jansson.json_decref(object1);
		jansson.jansson.json_decref(object2);
	}

	foreach (child_obj; jansson.jansson.json_object_foreach(object1)) {
		jansson.jansson.json_object_set(object2, child_obj.key, child_obj.value);
	}

	assert(jansson.value.json_equal(object1, object2), "json_object_foreach failed to iterate all key-value pairs");
}

//test_object_foreach_safe
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* object_ = jansson.pack_unpack.json_pack("{sisisi}", &("foo\0"[0]), 1, &("bar\0"[0]), 2, &("baz\0"[0]), 3);

	scope (exit) {
		jansson.jansson.json_decref(object_);
	}

	foreach (child_obj; jansson.jansson.json_object_foreach_safe(object_)) {
		jansson.value.json_object_del(object_, child_obj.key);
	}

	assert(jansson.value.json_object_size(object_) == 0, "json_object_foreach_safe failed to iterate all key-value pairs");
}

//test_bad_args
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* obj = jansson.value.json_object();
	jansson.jansson.json_t* num = jansson.value.json_integer(1);

	scope (exit) {
		jansson.jansson.json_decref(obj);
		jansson.jansson.json_decref(num);
	}

	assert((obj != null) && (num != null), "failed to allocate test objects");

	assert(!jansson.jansson.json_object_set(obj, "testkey", jansson.value.json_null()), "failed to set testkey on object");

	void* iter = jansson.value.json_object_iter(obj);

	assert(iter != null, "failed to retrieve test iterator");

	assert(jansson.value.json_object_size(null) == 0, "json_object_size with non-object argument returned non-zero");

	assert(jansson.value.json_object_size(num) == 0, "json_object_size with non-object argument returned non-zero");

	assert(jansson.value.json_object_get(null, "test") == null, "json_object_get with non-object argument returned non-null");

	assert(jansson.value.json_object_get(num, "test") == null, "json_object_get with non-object argument returned non-null");

	assert(jansson.value.json_object_get(obj, null) == null, "json_object_get with null key returned non-null");

	assert(jansson.value.json_object_set_new_nocheck(null, "test", jansson.value.json_null()), "json_object_set_new_nocheck with non-object argument did not return error");

	assert(jansson.value.json_object_set_new_nocheck(num, "test", jansson.value.json_null()), "json_object_set_new_nocheck with non-object argument did not return error");

	assert(jansson.value.json_object_set_new_nocheck(obj, "test", jansson.jansson.json_incref(obj)), "json_object_set_new_nocheck with object == value did not return error");

	assert(jansson.value.json_object_set_new_nocheck(obj, null, jansson.value.json_object()), "json_object_set_new_nocheck with null key did not return error");

	assert(jansson.value.json_object_del(null, "test"), "json_object_del with non-object argument did not return error");

	assert(jansson.value.json_object_del(num, "test"), "json_object_del with non-object argument did not return error");

	assert(jansson.value.json_object_del(obj, null), "json_object_del with null key did not return error");

	assert(jansson.value.json_object_clear(null), "json_object_clear with non-object argument did not return error");

	assert(jansson.value.json_object_clear(num), "json_object_clear with non-object argument did not return error");

	assert(jansson.value.json_object_update(null, obj), "json_object_update with non-object first argument did not return error");

	assert(jansson.value.json_object_update(num, obj), "json_object_update with non-object first argument did not return error");

	assert(jansson.value.json_object_update(obj, null), "json_object_update with non-object second argument did not return error");

	assert(jansson.value.json_object_update(obj, num), "json_object_update with non-object second argument did not return error");

	assert(jansson.value.json_object_update_existing(null, obj), "json_object_update_existing with non-object first argument did not return error");

	assert(jansson.value.json_object_update_existing(num, obj), "json_object_update_existing with non-object first argument did not return error");

	assert(jansson.value.json_object_update_existing(obj, null), "json_object_update_existing with non-object second argument did not return error");

	assert(jansson.value.json_object_update_existing(obj, num), "json_object_update_existing with non-object second argument did not return error");

	assert(jansson.value.json_object_update_missing(null, obj), "json_object_update_missing with non-object first argument did not return error");

	assert(jansson.value.json_object_update_missing(num, obj), "json_object_update_missing with non-object first argument did not return error");

	assert(jansson.value.json_object_update_missing(obj, null), "json_object_update_missing with non-object second argument did not return error");

	assert(jansson.value.json_object_update_missing(obj, num), "json_object_update_missing with non-object second argument did not return error");

	assert(jansson.value.json_object_iter(null) == null, "json_object_iter with non-object argument returned non-null");

	assert(jansson.value.json_object_iter(num) == null, "json_object_iter with non-object argument returned non-null");

	assert(jansson.value.json_object_iter_at(null, "test") == null, "json_object_iter_at with non-object argument returned non-null");

	assert(jansson.value.json_object_iter_at(num, "test") == null, "json_object_iter_at with non-object argument returned non-null");

	assert(jansson.value.json_object_iter_at(obj, null) == null, "json_object_iter_at with null iter returned non-null");

	assert(jansson.value.json_object_iter_next(obj, null) == null, "json_object_iter_next with null iter returned non-null");

	assert(jansson.value.json_object_iter_next(num, iter) == null, "json_object_iter_next with non-object argument returned non-null");

	assert(jansson.value.json_object_iter_key(null) == null, "json_object_iter_key with null iter returned non-null");

	assert(jansson.value.json_object_key_to_iter(null) == null, "json_object_key_to_iter with null iter returned non-null");

	assert(jansson.value.json_object_iter_value(null) == null, "json_object_iter_value with null iter returned non-null");

	assert(jansson.value.json_object_iter_set_new(null, iter, jansson.jansson.json_incref(num)), "json_object_iter_set_new with non-object argument did not return error");

	assert(jansson.value.json_object_iter_set_new(num, iter, jansson.jansson.json_incref(num)), "json_object_iter_set_new with non-object argument did not return error");

	assert(jansson.value.json_object_iter_set_new(obj, null, jansson.jansson.json_incref(num)), "json_object_iter_set_new with null iter did not return error");

	assert(jansson.value.json_object_iter_set_new(obj, iter, null), "json_object_iter_set_new with null value did not return error");

	assert(obj.refcount == 1, "unexpected reference count for obj");

	assert(num.refcount == 1, "unexpected reference count for num");
}
