/*
 * Copyright (c) 2020 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.test_fixed_size;


private static import core.memory;
private static import core.stdc.string;
private static import jansson.dump;
private static import jansson.jansson;
private static import jansson.test.util;
private static import jansson.value;

private void test_keylen_iterator(scope jansson.jansson.json_t* object_)

	do
	{
		static immutable char[][] reference_keys =
		[
			['t', 'e', 's', 't', '1'],
			['t', 'e', 's', 't'],
			['t', 'e', 's', '\0', 't'],
			['t', 'e', 's', 't', '\0'],
		];

		size_t index = 0;

		foreach (child_obj; jansson.jansson.json_object_keylen_foreach(object_)) {
			assert(child_obj.key_len == reference_keys[index].length, "invalid key len in iterator");

			assert(core.stdc.string.memcmp(child_obj.key, &(reference_keys[index][0]), reference_keys[index].length) == 0, "invalid key in iterator");

			index++;
		}
	}

//test_keylen
unittest
{
	static immutable char[] key = ['t', 'e', 's', 't', '1'];
	static immutable char[] key2 = ['t', 'e', 's', 't'];
	static immutable char[] key3 = ['t', 'e', 's', '\0', 't'];
	static immutable char[] key4 = ['t', 'e', 's', 't', '\0'];

	jansson.test.util.init_unittest();
	jansson.jansson.json_t* obj = jansson.value.json_object();

	scope (exit) {
		jansson.jansson.json_decref(obj);
	}

	assert(jansson.value.json_object_size(obj) == 0, "incorrect json");

	jansson.value.json_object_set_new_nocheck(obj, "test1", jansson.value.json_true());

	assert(jansson.value.json_object_size(obj) == 1, "incorrect json");

	assert(jansson.value.json_object_getn(obj, &(key[0]), key.length) == jansson.value.json_true(), "json_object_getn failed");

	assert(jansson.value.json_object_getn(obj, &(key2[0]), key2.length) == null, "false positive json_object_getn by key2");

	assert(!jansson.jansson.json_object_setn_nocheck(obj, &(key2[0]), key2.length, jansson.value.json_false()), "json_object_setn_nocheck for key2 failed");

	assert(jansson.value.json_object_size(obj) == 2, "incorrect json");

	assert(jansson.value.json_object_get(obj, "test") == jansson.value.json_false(), "json_object_setn_nocheck for key2 failed");

	assert(jansson.value.json_object_getn(obj, &(key2[0]), key2.length) == jansson.value.json_false(), "json_object_getn by key 2 failed");

	assert(jansson.value.json_object_getn(obj, &(key3[0]), key3.length) == null, "false positive json_object_getn by key3");

	assert(!jansson.jansson.json_object_setn_nocheck(obj, &(key3[0]), key3.length, jansson.value.json_false()), "json_object_setn_nocheck for key3 failed");

	assert(jansson.value.json_object_size(obj) == 3, "incorrect json");

	assert(jansson.value.json_object_getn(obj, &(key3[0]), key3.length) == jansson.value.json_false(), "json_object_getn by key 3 failed");

	assert(jansson.value.json_object_getn(obj, &(key4[0]), key4.length) == null, "false positive json_object_getn by key3");

	assert(!jansson.jansson.json_object_setn_nocheck(obj, &(key4[0]), key4.length, jansson.value.json_false()), "json_object_setn_nocheck for key3 failed");

	assert(jansson.value.json_object_size(obj) == 4, "incorrect json");

	.test_keylen_iterator(obj);

	assert(jansson.value.json_object_getn(obj, &(key4[0]), key4.length) == jansson.value.json_false(), "json_object_getn by key 3 failed");

	assert(jansson.value.json_object_size(obj) == 4, "incorrect json");

	assert(!jansson.value.json_object_deln(obj, &(key4[0]), key4.length), "json_object_deln failed");

	assert(jansson.value.json_object_getn(obj, &(key4[0]), key4.length) == null, "json_object_deln failed");

	assert(jansson.value.json_object_size(obj) == 3, "incorrect json");

	assert(!jansson.value.json_object_deln(obj, &(key3[0]), key3.length), "json_object_deln failed");

	assert(jansson.value.json_object_getn(obj, &(key3[0]), key3.length) == null, "json_object_deln failed");

	assert(jansson.value.json_object_size(obj) == 2, "incorrect json");

	assert(!jansson.value.json_object_deln(obj, &(key2[0]), key2.length), "json_object_deln failed");

	assert(jansson.value.json_object_getn(obj, &(key2[0]), key2.length) == null, "json_object_deln failed");

	assert(jansson.value.json_object_size(obj) == 1, "incorrect json");

	assert(!jansson.value.json_object_deln(obj, &(key[0]), key.length), "json_object_deln failed");

	assert(jansson.value.json_object_getn(obj, &(key[0]), key.length) == null, "json_object_deln failed");

	assert(jansson.value.json_object_size(obj) == 0, "incorrect json");
}

//test_invalid_keylen
unittest
{
	static immutable char[] key = ['t', 'e', 's', 't', '1'];

	jansson.test.util.init_unittest();
	jansson.jansson.json_t* obj = jansson.value.json_object();
	jansson.jansson.json_t* empty_obj = jansson.value.json_object();

	scope (exit) {
		jansson.jansson.json_decref(obj);
		jansson.jansson.json_decref(empty_obj);
	}

	jansson.value.json_object_set_new_nocheck(obj, "test1", jansson.value.json_true());

	assert(jansson.value.json_object_getn(null, &(key[0]), key.length) == null, "json_object_getn on null failed");

	assert(jansson.value.json_object_getn(obj, null, key.length) == null, "json_object_getn on null failed");

	assert(jansson.value.json_object_getn(obj, &(key[0]), 0) == null, "json_object_getn on null failed");

	assert(jansson.value.json_object_setn_new(obj, null, key.length, jansson.value.json_true()), "json_object_setn_new with null key failed");

	assert(jansson.value.json_object_setn_new_nocheck(obj, null, key.length, jansson.value.json_true()), "json_object_setn_new_nocheck with null key failed");

	assert(jansson.value.json_object_del(obj, null), "json_object_del with null failed");

	assert(jansson.value.json_object_deln(empty_obj, &(key[0]), key.length), "json_object_deln with empty object failed");

	assert(jansson.value.json_object_deln(obj, &(key[0]), key.length - 1), "json_object_deln with incomplete key failed");
}

//test_binary_keys
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* obj = jansson.value.json_object();
	int key1 = 0;
	int key2 = 1;

	scope (exit) {
		jansson.jansson.json_decref(obj);
	}

	jansson.jansson.json_object_setn_nocheck(obj, cast(const char*)(&key1), key1.sizeof, jansson.value.json_true());
	jansson.jansson.json_object_setn_nocheck(obj, cast(const char*)(&key2), key2.sizeof, jansson.value.json_true());

	assert(mixin (jansson.jansson.json_is_true!("jansson.value.json_object_getn(obj, cast(const char*)(&key1), key1.sizeof)")), "cannot get integer key1");

	assert(mixin (jansson.jansson.json_is_true!("jansson.value.json_object_getn(obj, cast(const char*)(&key1), key2.sizeof)")), "cannot get integer key2");

	assert(jansson.value.json_object_size(obj) == 2, "binary object size missmatch");

	assert(!jansson.value.json_object_deln(obj, cast(const char*)(&key1), key1.sizeof), "cannot del integer key1");

	assert(jansson.value.json_object_size(obj) == 1, "binary object size missmatch");

	assert(!jansson.value.json_object_deln(obj, cast(const char*)(&key2), key2.sizeof), "cannot del integer key2");

	assert(jansson.value.json_object_size(obj) == 0, "binary object size missmatch");
}

//test_dump_order
unittest
{
	static immutable char[] key1 = ['k', '\0', '-', '2'];
	static immutable char[] key2 = ['k', '\0', '-', '1'];
	static immutable char[] expected_sorted_str = "{\"k\\u0000-1\": \"first\", \"k\\u0000-2\": \"second\"}\0";
	static immutable char[] expected_nonsorted_str = "{\"k\\u0000-2\": \"second\", \"k\\u0000-1\": \"first\"}\0";

	jansson.test.util.init_unittest();
	jansson.jansson.json_t* obj = jansson.value.json_object();

	scope (exit) {
		jansson.jansson.json_decref(obj);
	}

	jansson.value.json_object_setn_new_nocheck(obj, &(key1[0]), key1.length, jansson.value.json_string("second"));
	jansson.value.json_object_setn_new_nocheck(obj, &(key2[0]), key2.length, jansson.value.json_string("first"));

	{
		char* out_ = cast(char*)(core.memory.pureMalloc(512));

		assert(out_ != null);

		scope (exit) {
			core.memory.pureFree(out_);
		}

		{
			jansson.dump.json_dumpb(obj, out_, 512, 0);

			assert(core.stdc.string.memcmp(&(expected_nonsorted_str[0]), out_, expected_nonsorted_str.length - 1) == 0, "preserve order failed");
		}

		{
			jansson.dump.json_dumpb(obj, out_, 512, jansson.jansson.JSON_SORT_KEYS);

			assert(core.stdc.string.memcmp(&(expected_sorted_str[0]), out_, expected_sorted_str.length - 1) == 0, "utf-8 sort failed");
		}
	}
}
