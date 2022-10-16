/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.value;


package:

private static import core.stdc.math;
private static import core.stdc.stdarg;
private static import core.stdc.string;
private static import jansson_d.hashtable;
private static import jansson_d.hashtable_seed;
private static import jansson_d.jansson;
private static import jansson_d.jansson_private;
private static import jansson_d.utf;

/* Work around nonstandard isnan() and isinf() implementations */
static if (!__traits(compiles, core.stdc.math.isnan)) {
	//version (Solaris) {
	//} else {
		pragma(inline, true)
		pure nothrow @safe @nogc @live
		private int isnan(double x)

			do
			{
				return x != x;
			}
	//}
} else {
	alias isnan = core.stdc.math.isnan;
}

static if (!__traits(compiles, core.stdc.math.isinf)) {
	pragma(inline, true)
	pure nothrow @safe @nogc @live
	private int isinf(double x)

		do
		{
			return (!.isnan(x)) && (.isnan(x - x));
		}
} else {
	alias isinf = core.stdc.math.isinf;
}

pragma(inline, true)
pure nothrow @trusted @nogc @live
private void json_init(scope jansson_d.jansson.json_t* json, jansson_d.jansson.json_type type)

	in
	{
		assert(json != null);
	}

	do
	{
		json.type = type;
		json.refcount = 1;
	}

nothrow @trusted @nogc
int jsonp_loop_check(scope jansson_d.hashtable.hashtable_t* parents, scope const jansson_d.jansson.json_t* json, scope char* key, size_t key_size, scope size_t* key_len_out)

	do
	{
		size_t key_len = jansson_d.jansson_private.snprintf(key, key_size, "%p", json);

		if (key_len_out != null) {
			*key_len_out = key_len;
		}

		if (jansson_d.hashtable.hashtable_get(parents, key, key_len)) {
			return -1;
		}

		return jansson_d.hashtable.hashtable_set(parents, key, key_len, .json_null());
	}

/* object */

///
extern (C)
nothrow @nogc
public jansson_d.jansson.json_t* json_object()

	do
	{
		jansson_d.jansson_private.json_object_t* object_ = cast(jansson_d.jansson_private.json_object_t*)(jansson_d.jansson_private.jsonp_malloc(jansson_d.jansson_private.json_object_t.sizeof));

		if (object_ == null) {
			return null;
		}

		if (!jansson_d.hashtable_seed.hashtable_seed) {
			/* Autoseed */
			jansson_d.hashtable_seed.json_object_seed(0);
		}

		.json_init(&object_.json, jansson_d.jansson.json_type.JSON_OBJECT);

		if (jansson_d.hashtable.hashtable_init(&object_.hashtable)) {
			jansson_d.jansson_private.jsonp_free(object_);

			return null;
		}

		return &object_.json;
	}

nothrow @trusted @nogc
private void json_delete_object(scope jansson_d.jansson_private.json_object_t* object_)

	in
	{
		assert(object_ != null);
	}

	do
	{
		jansson_d.hashtable.hashtable_close(&object_.hashtable);
		jansson_d.jansson_private.jsonp_free(object_);
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public size_t json_object_size(scope const jansson_d.jansson.json_t* json)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_object!("json"))) {
			return 0;
		}

		jansson_d.jansson_private.json_object_t* object_ = mixin (jansson_d.jansson_private.json_to_object!("json"));

		return object_.hashtable.size;
	}

///
//nodiscard
extern (C)
nothrow @trusted @nogc @live
public jansson_d.jansson.json_t* json_object_get(scope const jansson_d.jansson.json_t* json, scope const char* key)

	do
	{
		if (key == null) {
			return null;
		}

		return .json_object_getn(json, key, core.stdc.string.strlen(key));
	}

///
//nodiscard
extern (C)
nothrow @trusted @nogc @live
public jansson_d.jansson.json_t* json_object_getn(scope const jansson_d.jansson.json_t* json, scope const char* key, size_t key_len)

	do
	{
		if ((key == null) || (!mixin (jansson_d.jansson.json_is_object!("json")))) {
			return null;
		}

		jansson_d.jansson_private.json_object_t* object_ = mixin (jansson_d.jansson_private.json_to_object!("json"));

		return cast(jansson_d.jansson.json_t*)(jansson_d.hashtable.hashtable_get(&object_.hashtable, key, key_len));
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_set_new_nocheck(scope jansson_d.jansson.json_t* json, scope const char* key, scope jansson_d.jansson.json_t* value)

	do
	{
		if (key == null) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		return .json_object_setn_new_nocheck(json, key, core.stdc.string.strlen(key), value);
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_setn_new_nocheck(scope jansson_d.jansson.json_t* json, scope const char* key, size_t key_len, scope jansson_d.jansson.json_t* value)

	do
	{
		if (value == null) {
			return -1;
		}

		if ((key == null) || (!mixin (jansson_d.jansson.json_is_object!("json"))) || (json == value)) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		jansson_d.jansson_private.json_object_t* object_ = mixin (jansson_d.jansson_private.json_to_object!("json"));

		if (jansson_d.hashtable.hashtable_set(&object_.hashtable, key, key_len, value)) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		return 0;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_set_new(scope jansson_d.jansson.json_t* json, scope const char* key, scope jansson_d.jansson.json_t* value)

	do
	{
		if (key == null) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		return .json_object_setn_new(json, key, core.stdc.string.strlen(key), value);
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_setn_new(scope jansson_d.jansson.json_t* json, scope const char* key, size_t key_len, scope jansson_d.jansson.json_t* value)

	do
	{
		if ((key == null) || (!jansson_d.utf.utf8_check_string(key, key_len))) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		return .json_object_setn_new_nocheck(json, key, key_len, value);
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_del(scope jansson_d.jansson.json_t* json, scope const char* key)

	do
	{
		if (key == null) {
			return -1;
		}

		return .json_object_deln(json, key, core.stdc.string.strlen(key));
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_deln(scope jansson_d.jansson.json_t* json, scope const char* key, size_t key_len)

	do
	{
		if ((key == null) || (!mixin (jansson_d.jansson.json_is_object!("json")))) {
			return -1;
		}

		jansson_d.jansson_private.json_object_t* object_ = mixin (jansson_d.jansson_private.json_to_object!("json"));

		return jansson_d.hashtable.hashtable_del(&object_.hashtable, key, key_len);
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_clear(scope jansson_d.jansson.json_t* json)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_object!("json"))) {
			return -1;
		}

		jansson_d.jansson_private.json_object_t* object_ = mixin (jansson_d.jansson_private.json_to_object!("json"));
		jansson_d.hashtable.hashtable_clear(&object_.hashtable);

		return 0;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_update(scope jansson_d.jansson.json_t* object_, scope jansson_d.jansson.json_t* other)

	do
	{
		if ((!mixin (jansson_d.jansson.json_is_object!("object_"))) || (!mixin (jansson_d.jansson.json_is_object!("other")))) {
			return -1;
		}

		foreach (child_obj; jansson_d.jansson.json_object_keylen_foreach(other)) {
			if (jansson_d.jansson.json_object_setn_nocheck(object_, child_obj.key, child_obj.key_len, child_obj.value)) {
				return -1;
			}
		}

		return 0;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_update_existing(scope jansson_d.jansson.json_t* object_, scope jansson_d.jansson.json_t* other)

	do
	{
		if ((!mixin (jansson_d.jansson.json_is_object!("object_"))) || (!mixin (jansson_d.jansson.json_is_object!("other")))) {
			return -1;
		}

		foreach (child_obj; jansson_d.jansson.json_object_keylen_foreach(other)) {
			if (.json_object_getn(object_, child_obj.key, child_obj.key_len)) {
				jansson_d.jansson.json_object_setn_nocheck(object_, child_obj.key, child_obj.key_len, child_obj.value);
			}
		}

		return 0;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_update_missing(scope jansson_d.jansson.json_t* object_, scope jansson_d.jansson.json_t* other)

	do
	{
		if ((!mixin (jansson_d.jansson.json_is_object!("object_"))) || (!mixin (jansson_d.jansson.json_is_object!("other")))) {
			return -1;
		}

		foreach (child_obj; jansson_d.jansson.json_object_keylen_foreach(other)) {
			if (.json_object_getn(object_, child_obj.key, child_obj.key_len) == null) {
				jansson_d.jansson.json_object_setn_nocheck(object_, child_obj.key, child_obj.key_len, child_obj.value);
			}
		}

		return 0;
	}

nothrow @trusted @nogc
int do_object_update_recursive(scope jansson_d.jansson.json_t* object_, scope jansson_d.jansson.json_t* other, scope jansson_d.hashtable.hashtable_t* parents)

	do
	{
		if ((!mixin (jansson_d.jansson.json_is_object!("object_"))) || (!mixin (jansson_d.jansson.json_is_object!("other")))) {
			return -1;
		}

		char[jansson_d.jansson_private.LOOP_KEY_LEN] loop_key = void;
		size_t loop_key_len = void;

		if (.jsonp_loop_check(parents, other, &(loop_key[0]), loop_key.length, &loop_key_len)) {
			return -1;
		}

		int res = 0;

		foreach (child_obj; jansson_d.jansson.json_object_keylen_foreach(other)) {
			jansson_d.jansson.json_t* v = .json_object_getn(object_, child_obj.key, child_obj.key_len);

			if ((mixin (jansson_d.jansson.json_is_object!("v"))) && (jansson_d.jansson.json_is_object(child_obj.value))) {
				if (.do_object_update_recursive(v, child_obj.value, parents)) {
					res = -1;

					break;
				}
			} else {
				if (jansson_d.jansson.json_object_setn_nocheck(object_, child_obj.key, child_obj.key_len, child_obj.value)) {
					res = -1;

					break;
				}
			}
		}

		jansson_d.hashtable.hashtable_del(parents, &(loop_key[0]), loop_key_len);

		return res;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_update_recursive(scope jansson_d.jansson.json_t* object_, scope jansson_d.jansson.json_t* other)

	do
	{
		jansson_d.hashtable.hashtable_t parents_set = void;

		if (jansson_d.hashtable.hashtable_init(&parents_set)) {
			return -1;
		}

		int res = .do_object_update_recursive(object_, other, &parents_set);
		jansson_d.hashtable.hashtable_close(&parents_set);

		return res;
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public void* json_object_iter(scope jansson_d.jansson.json_t* json)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_object!("json"))) {
			return null;
		}

		jansson_d.jansson_private.json_object_t* object_ = mixin (jansson_d.jansson_private.json_to_object!("json"));

		return jansson_d.hashtable.hashtable_iter(&object_.hashtable);
	}

///
extern (C)
nothrow @trusted @nogc @live
public void* json_object_iter_at(scope jansson_d.jansson.json_t* json, scope const char* key)

	do
	{
		if ((key == null) || (!mixin (jansson_d.jansson.json_is_object!("json")))) {
			return null;
		}

		jansson_d.jansson_private.json_object_t* object_ = mixin (jansson_d.jansson_private.json_to_object!("json"));

		return jansson_d.hashtable.hashtable_iter_at(&object_.hashtable, key, core.stdc.string.strlen(key));
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public void* json_object_iter_next(scope jansson_d.jansson.json_t* json, scope void* iter)

	do
	{
		if ((!mixin (jansson_d.jansson.json_is_object!("json"))) || (iter == null)) {
			return null;
		}

		jansson_d.jansson_private.json_object_t* object_ = mixin (jansson_d.jansson_private.json_to_object!("json"));

		return jansson_d.hashtable.hashtable_iter_next(&object_.hashtable, iter);
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public const (char)* json_object_iter_key(scope void* iter)

	do
	{
		if (iter == null) {
			return null;
		}

		return cast(const (char)*)(jansson_d.hashtable.hashtable_iter_key(iter));
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public size_t json_object_iter_key_len(scope void* iter)

	do
	{
		if (iter == null) {
			return 0;
		}

		return jansson_d.hashtable.hashtable_iter_key_len(iter);
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public jansson_d.jansson.json_t* json_object_iter_value(scope void* iter)

	do
	{
		if (iter == null) {
			return null;
		}

		return cast(jansson_d.jansson.json_t*)(jansson_d.hashtable.hashtable_iter_value(iter));
	}

///
extern (C)
nothrow @trusted @nogc
public int json_object_iter_set_new(scope jansson_d.jansson.json_t* json, scope void* iter, scope jansson_d.jansson.json_t* value)

	do
	{
		if ((!mixin (jansson_d.jansson.json_is_object!("json"))) || (iter == null) || (value == null)) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		jansson_d.hashtable.hashtable_iter_set(iter, value);

		return 0;
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public void* json_object_key_to_iter(scope const char* key)

	do
	{
		if (key == null) {
			return null;
		}

		return mixin (jansson_d.hashtable.hashtable_key_to_iter!("key"));
	}

nothrow @trusted @nogc @live
private int json_object_equal(scope const jansson_d.jansson.json_t* object1, scope const jansson_d.jansson.json_t* object2)

	do
	{
		if (.json_object_size(object1) != .json_object_size(object2)) {
			return 0;
		}

		foreach (child_obj1; jansson_d.jansson.json_object_keylen_foreach(cast(jansson_d.jansson.json_t*)(object1))) {
			const (jansson_d.jansson.json_t)* value2 = .json_object_getn(object2, child_obj1.key, child_obj1.key_len);

			if (!.json_equal(child_obj1.value, value2)) {
				return 0;
			}
		}

		return 1;
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* json_object_copy(scope jansson_d.jansson.json_t* object_)

	do
	{
		jansson_d.jansson.json_t* result = .json_object();

		if (result == null) {
			return null;
		}

		foreach (child_obj; jansson_d.jansson.json_object_keylen_foreach(object_)) {
			jansson_d.jansson.json_object_setn_nocheck(result, child_obj.key, child_obj.key_len, child_obj.value);
		}

		return result;
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* json_object_deep_copy(scope const jansson_d.jansson.json_t* object_, scope jansson_d.hashtable.hashtable_t* parents)

	do
	{
		char[jansson_d.jansson_private.LOOP_KEY_LEN] loop_key = void;
		size_t loop_key_len = void;

		if (.jsonp_loop_check(parents, object_, &(loop_key[0]), loop_key.length, &loop_key_len)) {
			return null;
		}

		jansson_d.jansson.json_t* result = .json_object();

		if (result == null) {
			goto out_;
		}

		/*
		 * Cannot use jansson_d.jansson.json_object_foreach because object has to be cast
		 * non-const
		 */
		for (void* iter = .json_object_iter(cast(jansson_d.jansson.json_t*)(object_)); iter != null; iter = .json_object_iter_next(cast(jansson_d.jansson.json_t*)(object_), iter)) {
			const char* key = .json_object_iter_key(iter);
			size_t key_len = .json_object_iter_key_len(iter);
			const jansson_d.jansson.json_t* value = .json_object_iter_value(iter);

			if (.json_object_setn_new_nocheck(result, key, key_len, .do_deep_copy(value, parents))) {
				jansson_d.jansson.json_decref(result);
				result = null;

				break;
			}
		}

	out_:
		jansson_d.hashtable.hashtable_del(parents, &(loop_key[0]), loop_key_len);

		return result;
	}

/* array */

///
extern (C)
nothrow @trusted @nogc
public jansson_d.jansson.json_t* json_array()

	do
	{
		jansson_d.jansson_private.json_array_t* array = cast(jansson_d.jansson_private.json_array_t*)(jansson_d.jansson_private.jsonp_malloc(jansson_d.jansson_private.json_array_t.sizeof));

		if (array == null) {
			return null;
		}

		.json_init(&array.json, jansson_d.jansson.json_type.JSON_ARRAY);

		array.entries = 0;
		array.size = 8;

		array.table = cast(jansson_d.jansson.json_t**)(jansson_d.jansson_private.jsonp_malloc(array.size * (jansson_d.jansson.json_t*).sizeof));

		if (array.table == null) {
			jansson_d.jansson_private.jsonp_free(array);

			return null;
		}

		return &array.json;
	}

nothrow @trusted @nogc
private void json_delete_array(scope jansson_d.jansson_private.json_array_t* array)

	in
	{
		assert(array != null);
	}

	do
	{
		for (size_t i = 0; i < array.entries; i++) {
			jansson_d.jansson.json_decref(array.table[i]);
		}

		jansson_d.jansson_private.jsonp_free(array.table);
		array.table = null;
		jansson_d.jansson_private.jsonp_free(array);
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public size_t json_array_size(scope const jansson_d.jansson.json_t* json)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_array!("json"))) {
			return 0;
		}

		return (mixin (jansson_d.jansson_private.json_to_array!("json"))).entries;
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public jansson_d.jansson.json_t* json_array_get(scope const jansson_d.jansson.json_t* json, size_t index)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_array!("json"))) {
			return null;
		}

		jansson_d.jansson_private.json_array_t* array = mixin (jansson_d.jansson_private.json_to_array!("json"));

		if (index >= array.entries) {
			return null;
		}

		return array.table[index];
	}

///
extern (C)
nothrow @trusted @nogc
public int json_array_set_new(scope jansson_d.jansson.json_t* json, size_t index, scope jansson_d.jansson.json_t* value)

	do
	{
		if (value == null) {
			return -1;
		}

		if ((!mixin (jansson_d.jansson.json_is_array!("json"))) || (json == value)) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		jansson_d.jansson_private.json_array_t* array = mixin (jansson_d.jansson_private.json_to_array!("json"));

		if (index >= array.entries) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		jansson_d.jansson.json_decref(array.table[index]);
		array.table[index] = value;

		return 0;
	}

pure nothrow @trusted @nogc @live
private void array_move(scope jansson_d.jansson_private.json_array_t* array, size_t dest, size_t src, size_t count)

	in
	{
		assert(array != null);
	}

	do
	{
		core.stdc.string.memmove(&array.table[dest], &array.table[src], count * (jansson_d.jansson.json_t*).sizeof);
	}

pure nothrow @trusted @nogc @live
private void array_copy(scope jansson_d.jansson.json_t** dest, size_t dpos, scope jansson_d.jansson.json_t** src, size_t spos, size_t count)

	in
	{
		assert(dest != null);
		assert(src != null);
	}

	do
	{
		core.stdc.string.memcpy(&dest[dpos], &src[spos], count * (jansson_d.jansson.json_t*).sizeof);
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t** json_array_grow(scope jansson_d.jansson_private.json_array_t* array, size_t amount, int copy)

	in
	{
		assert(array != null);
	}

	do
	{
		if ((array.entries + amount) <= array.size) {
			return array.table;
		}

		jansson_d.jansson.json_t** old_table = array.table;

		size_t new_size = mixin (jansson_d.jansson_private.max!("array.size + amount", "array.size * 2"));
		jansson_d.jansson.json_t** new_table = cast(jansson_d.jansson.json_t**)(jansson_d.jansson_private.jsonp_malloc(new_size * (jansson_d.jansson.json_t*).sizeof));

		if (new_table == null) {
			return null;
		}

		array.size = new_size;
		array.table = new_table;

		if (copy) {
			.array_copy(array.table, 0, old_table, 0, array.entries);
			jansson_d.jansson_private.jsonp_free(old_table);

			return array.table;
		}

		return old_table;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_array_append_new(scope jansson_d.jansson.json_t* json, scope jansson_d.jansson.json_t* value)

	do
	{
		if (value == null) {
			return -1;
		}

		if ((!mixin (jansson_d.jansson.json_is_array!("json"))) || (json == value)) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		jansson_d.jansson_private.json_array_t* array = mixin (jansson_d.jansson_private.json_to_array!("json"));

		if (!.json_array_grow(array, 1, 1)) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		array.table[array.entries] = value;
		array.entries++;

		return 0;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_array_insert_new(scope jansson_d.jansson.json_t* json, size_t index, scope jansson_d.jansson.json_t* value)

	do
	{
		if (value == null) {
			return -1;
		}

		if ((!mixin (jansson_d.jansson.json_is_array!("json"))) || (json == value)) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		jansson_d.jansson_private.json_array_t* array = mixin (jansson_d.jansson_private.json_to_array!("json"));

		if (index > array.entries) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		jansson_d.jansson.json_t** old_table = .json_array_grow(array, 1, 0);

		if (old_table == null) {
			jansson_d.jansson.json_decref(value);

			return -1;
		}

		if (old_table != array.table) {
			.array_copy(array.table, 0, old_table, 0, index);
			.array_copy(array.table, index + 1, old_table, index, array.entries - index);
			jansson_d.jansson_private.jsonp_free(old_table);
		} else {
			.array_move(array, index + 1, index, array.entries - index);
		}

		array.table[index] = value;
		array.entries++;

		return 0;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_array_remove(scope jansson_d.jansson.json_t* json, size_t index)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_array!("json"))) {
			return -1;
		}

		jansson_d.jansson_private.json_array_t* array = mixin (jansson_d.jansson_private.json_to_array!("json"));

		if (index >= array.entries) {
			return -1;
		}

		jansson_d.jansson.json_decref(array.table[index]);

		/* If we're removing the last element, nothing has to be moved */
		if (index < (array.entries - 1)) {
			.array_move(array, index, index + 1, array.entries - index - 1);
		}

		array.entries--;

		return 0;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_array_clear(scope jansson_d.jansson.json_t* json)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_array!("json"))) {
			return -1;
		}

		jansson_d.jansson_private.json_array_t* array = mixin (jansson_d.jansson_private.json_to_array!("json"));

		for (size_t i = 0; i < array.entries; i++) {
			jansson_d.jansson.json_decref(array.table[i]);
		}

		array.entries = 0;

		return 0;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_array_extend(scope jansson_d.jansson.json_t* json, scope jansson_d.jansson.json_t* other_json)

	do
	{
		if ((!mixin (jansson_d.jansson.json_is_array!("json"))) || (!mixin (jansson_d.jansson.json_is_array!("other_json")))) {
			return -1;
		}

		jansson_d.jansson_private.json_array_t* array = mixin (jansson_d.jansson_private.json_to_array!("json"));
		jansson_d.jansson_private.json_array_t* other = mixin (jansson_d.jansson_private.json_to_array!("other_json"));

		if (!.json_array_grow(array, other.entries, 1)) {
			return -1;
		}

		for (size_t i = 0; i < other.entries; i++) {
			jansson_d.jansson.json_incref(other.table[i]);
		}

		.array_copy(array.table, array.entries, other.table, 0, other.entries);

		array.entries += other.entries;

		return 0;
	}

nothrow @trusted @nogc @live
private int json_array_equal(scope const jansson_d.jansson.json_t* array1, scope const jansson_d.jansson.json_t* array2)

	do
	{
		size_t size = .json_array_size(array1);

		if (size != .json_array_size(array2)) {
			return 0;
		}

		for (size_t i = 0; i < size; i++) {
			jansson_d.jansson.json_t* value1 = .json_array_get(array1, i);
			jansson_d.jansson.json_t* value2 = .json_array_get(array2, i);

			if (!.json_equal(value1, value2)) {
				return 0;
			}
		}

		return 1;
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* json_array_copy(scope jansson_d.jansson.json_t* array)

	do
	{
		jansson_d.jansson.json_t* result = .json_array();

		if (result == null) {
			return null;
		}

		for (size_t i = 0; i < .json_array_size(array); i++) {
			jansson_d.jansson.json_array_append(result, .json_array_get(array, i));
		}

		return result;
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* json_array_deep_copy(scope const jansson_d.jansson.json_t* array, scope jansson_d.hashtable.hashtable_t* parents)

	do
	{
		char[jansson_d.jansson_private.LOOP_KEY_LEN] loop_key = void;
		size_t loop_key_len = void;

		if (.jsonp_loop_check(parents, array, &(loop_key[0]), loop_key.length, &loop_key_len)) {
			return null;
		}

		jansson_d.jansson.json_t* result = .json_array();

		if (result == null) {
			goto out_;
		}

		for (size_t i = 0; i < .json_array_size(array); i++) {
			if (.json_array_append_new(result, .do_deep_copy(.json_array_get(array, i), parents))) {
				jansson_d.jansson.json_decref(result);
				result = null;

				break;
			}
		}

	out_:
		jansson_d.hashtable.hashtable_del(parents, &(loop_key[0]), loop_key_len);

		return result;
	}

/* string */

nothrow @trusted @nogc
private jansson_d.jansson.json_t* string_create(scope const char* value, size_t len, int own)

	do
	{
		if (value == null) {
			return null;
		}

		char* v = void;

		if (own) {
			v = cast(char*)(value);
		} else {
			v = jansson_d.jansson_private.jsonp_strndup(value, len);

			if (v == null) {
				return null;
			}
		}

		jansson_d.jansson_private.json_string_t* string_ = cast(jansson_d.jansson_private.json_string_t*)(jansson_d.jansson_private.jsonp_malloc(jansson_d.jansson_private.json_string_t.sizeof));

		if (string_ == null) {
			jansson_d.jansson_private.jsonp_free(v);

			return null;
		}

		.json_init(&string_.json, jansson_d.jansson.json_type.JSON_STRING);
		string_.value = v;
		string_.length_ = len;

		return &string_.json;
	}

///
extern (C)
nothrow @trusted @nogc
public jansson_d.jansson.json_t* json_string_nocheck(scope const char* value)

	do
	{
		if (value == null) {
			return null;
		}

		return .string_create(value, core.stdc.string.strlen(value), 0);
	}

///
extern (C)
nothrow @trusted @nogc
public jansson_d.jansson.json_t* json_stringn_nocheck(scope const char* value, size_t len)

	do
	{
		return .string_create(value, len, 0);
	}

/* this is private; "steal" is not a public API concept */
nothrow @trusted @nogc
jansson_d.jansson.json_t* jsonp_stringn_nocheck_own(scope const char* value, size_t len)

	do
	{
		return .string_create(value, len, 1);
	}

///
extern (C)
nothrow @trusted @nogc
public jansson_d.jansson.json_t* json_string(scope const char* value)

	do
	{
		if (value == null) {
			return null;
		}

		return .json_stringn(value, core.stdc.string.strlen(value));
	}

///
extern (C)
nothrow @trusted @nogc
public jansson_d.jansson.json_t* json_stringn(scope const char* value, size_t len)

	do
	{
		if ((value == null) || (!jansson_d.utf.utf8_check_string(value, len))) {
			return null;
		}

		return .json_stringn_nocheck(value, len);
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public const (char)* json_string_value(scope const jansson_d.jansson.json_t* json)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_string!("json"))) {
			return null;
		}

		return (mixin (jansson_d.jansson_private.json_to_string!("json"))).value;
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public size_t json_string_length(scope const jansson_d.jansson.json_t* json)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_string!("json"))) {
			return 0;
		}

		return (mixin (jansson_d.jansson_private.json_to_string!("json"))).length_;
	}

///
extern (C)
nothrow @trusted @nogc @live
public int json_string_set_nocheck(scope jansson_d.jansson.json_t* json, scope const char* value)

	do
	{
		if (value == null) {
			return -1;
		}

		return .json_string_setn_nocheck(json, value, core.stdc.string.strlen(value));
	}

///
extern (C)
nothrow @trusted @nogc
public int json_string_setn_nocheck(scope jansson_d.jansson.json_t* json, scope const char* value, size_t len)

	do
	{
		if ((!mixin (jansson_d.jansson.json_is_string!("json"))) || (value == null)) {
			return -1;
		}

		char* dup = jansson_d.jansson_private.jsonp_strndup(value, len);

		if (dup == null) {
			return -1;
		}

		jansson_d.jansson_private.json_string_t* string_ = mixin (jansson_d.jansson_private.json_to_string!("json"));
		jansson_d.jansson_private.jsonp_free(string_.value);
		string_.value = dup;
		string_.length_ = len;

		return 0;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_string_set(scope jansson_d.jansson.json_t* json, scope const char* value)

	do
	{
		if (value == null) {
			return -1;
		}

		return .json_string_setn(json, value, core.stdc.string.strlen(value));
	}

///
extern (C)
nothrow @trusted @nogc
public int json_string_setn(scope jansson_d.jansson.json_t* json, scope const char* value, size_t len)

	do
	{
		if ((value == null) || (!jansson_d.utf.utf8_check_string(value, len))) {
			return -1;
		}

		return .json_string_setn_nocheck(json, value, len);
	}

nothrow @trusted @nogc
private void json_delete_string(scope jansson_d.jansson_private.json_string_t* string_)

	in
	{
		assert(string_ != null);
	}

	do
	{
		jansson_d.jansson_private.jsonp_free(string_.value);
		string_.value = null;
		jansson_d.jansson_private.jsonp_free(string_);
	}

pure nothrow @trusted @nogc @live
private int json_string_equal(scope const jansson_d.jansson.json_t* string1, scope const jansson_d.jansson.json_t* string2)

	in
	{
		assert(string1 != null);
		assert(string2 != null);
	}

	do
	{
		jansson_d.jansson_private.json_string_t* s1 = mixin (jansson_d.jansson_private.json_to_string!("string1"));
		jansson_d.jansson_private.json_string_t* s2 = mixin (jansson_d.jansson_private.json_to_string!("string2"));

		return (s1.length_ == s2.length_) && (core.stdc.string.memcmp(s1.value, s2.value, s1.length_) == 0);
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* json_string_copy(scope const jansson_d.jansson.json_t* string_)

	in
	{
		assert(string_ != null);
	}

	do
	{
		jansson_d.jansson_private.json_string_t* s = mixin (jansson_d.jansson_private.json_to_string!("string_"));

		return .json_stringn_nocheck(s.value, s.length_);
	}

///
//JANSSON_ATTRS((warn_unused_result, format(printf, 1, 0)))
//nodiscard
extern (C)
nothrow @nogc
public jansson_d.jansson.json_t* json_vsprintf(scope const char* fmt, core.stdc.stdarg.va_list ap)

	do
	{
		char* buf = void;
		jansson_d.jansson.json_t* json = null;
		core.stdc.stdarg.va_list aq;
		jansson_d.jansson_private.va_copy(aq, ap);

		int length_ = jansson_d.jansson_private.vsnprintf(null, 0, fmt, ap);

		if (length_ < 0) {
			goto out_;
		}

		if (length_ == 0) {
			json = .json_string("\0");

			goto out_;
		}

		buf = cast(char*)(jansson_d.jansson_private.jsonp_malloc(cast(size_t)(length_) + 1));

		if (buf == null) {
			goto out_;
		}

		jansson_d.jansson_private.vsnprintf(buf, cast(size_t)(length_) + 1, fmt, aq);

		if (!jansson_d.utf.utf8_check_string(buf, length_)) {
			jansson_d.jansson_private.jsonp_free(buf);

			goto out_;
		}

		json = .jsonp_stringn_nocheck_own(buf, length_);

	out_:
		core.stdc.stdarg.va_end(aq);

		return json;
	}

///
//JANSSON_ATTRS((warn_unused_result, format(printf, 1, 2)))
//nodiscard
extern (C)
nothrow @nogc
public jansson_d.jansson.json_t* json_sprintf(scope const char* fmt, ...)

	do
	{
		core.stdc.stdarg.va_list ap;

		core.stdc.stdarg.va_start(ap, fmt);
		jansson_d.jansson.json_t* result = .json_vsprintf(fmt, ap);
		core.stdc.stdarg.va_end(ap);

		return result;
	}

/* integer */

///
extern (C)
nothrow @trusted @nogc
public jansson_d.jansson.json_t* json_integer(jansson_d.jansson.json_int_t value)

	do
	{
		jansson_d.jansson_private.json_integer_t* integer = cast(jansson_d.jansson_private.json_integer_t*)(jansson_d.jansson_private.jsonp_malloc(jansson_d.jansson_private.json_integer_t.sizeof));

		if (integer == null) {
			return null;
		}

		.json_init(&integer.json, jansson_d.jansson.json_type.JSON_INTEGER);

		integer.value = value;

		return &integer.json;
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public jansson_d.jansson.json_int_t json_integer_value(scope const jansson_d.jansson.json_t* json)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_integer!("json"))) {
			return 0;
		}

		return (mixin (jansson_d.jansson_private.json_to_integer!("json"))).value;
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public int json_integer_set(scope jansson_d.jansson.json_t* json, jansson_d.jansson.json_int_t value)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_integer!("json"))) {
			return -1;
		}

		(mixin (jansson_d.jansson_private.json_to_integer!("json"))).value = value;

		return 0;
	}

nothrow @trusted @nogc
private void json_delete_integer(scope jansson_d.jansson_private.json_integer_t* integer)

	do
	{
		jansson_d.jansson_private.jsonp_free(integer);
	}

pure nothrow @trusted @nogc @live
private int json_integer_equal(scope const jansson_d.jansson.json_t* integer1, scope const jansson_d.jansson.json_t* integer2)

	do
	{
		return .json_integer_value(integer1) == .json_integer_value(integer2);
	}

nothrow @trusted @nogc @live
private jansson_d.jansson.json_t* json_integer_copy(scope const jansson_d.jansson.json_t* integer)

	do
	{
		return .json_integer(.json_integer_value(integer));
	}

/* real */

///
extern (C)
nothrow @trusted @nogc
public jansson_d.jansson.json_t* json_real(double value)

	do
	{
		if ((.isnan(value)) || (.isinf(value))) {
			return null;
		}

		jansson_d.jansson_private.json_real_t* real_ = cast(jansson_d.jansson_private.json_real_t*)(jansson_d.jansson_private.jsonp_malloc(jansson_d.jansson_private.json_real_t.sizeof));

		if (real_ == null) {
			return null;
		}

		.json_init(&real_.json, jansson_d.jansson.json_type.JSON_REAL);

		real_.value = value;

		return &real_.json;
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public double json_real_value(scope const jansson_d.jansson.json_t* json)

	do
	{
		if (!mixin (jansson_d.jansson.json_is_real!("json"))) {
			return 0;
		}

		return (mixin (jansson_d.jansson_private.json_to_real!("json"))).value;
	}

///
extern (C)
pure nothrow @trusted @nogc @live
public int json_real_set(scope jansson_d.jansson.json_t* json, double value)

	do
	{
		if ((!mixin (jansson_d.jansson.json_is_real!("json"))) || (.isnan(value)) || (.isinf(value))) {
			return -1;
		}

		(mixin (jansson_d.jansson_private.json_to_real!("json"))).value = value;

		return 0;
	}

nothrow @trusted @nogc
private void json_delete_real(scope jansson_d.jansson_private.json_real_t* real_)

	do
	{
		jansson_d.jansson_private.jsonp_free(real_);
	}

pure nothrow @trusted @nogc @live
private int json_real_equal(scope const jansson_d.jansson.json_t* real1, scope const jansson_d.jansson.json_t* real2)

	do
	{
		return .json_real_value(real1) == .json_real_value(real2);
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* json_real_copy(scope const jansson_d.jansson.json_t* real_)

	do
	{
		return .json_real(.json_real_value(real_));
	}

/* number */

///
extern (C)
pure nothrow @trusted @nogc @live
public double json_number_value(scope const jansson_d.jansson.json_t* json)

	do
	{
		if (mixin (jansson_d.jansson.json_is_integer!("json"))) {
			return cast(double)(.json_integer_value(json));
		} else if (mixin (jansson_d.jansson.json_is_real!("json"))) {
			return .json_real_value(json);
		} else {
			return 0.0;
		}
	}

/* simple values */

///
extern (C)
nothrow @trusted @nogc @live
public jansson_d.jansson.json_t* json_true()

	do
	{
		static jansson_d.jansson.json_t the_true = {jansson_d.jansson.json_type.JSON_TRUE, size_t.max};

		return &the_true;
	}

///
extern (C)
nothrow @trusted @nogc @live
public jansson_d.jansson.json_t* json_false()

	do
	{
		static jansson_d.jansson.json_t the_false = {jansson_d.jansson.json_type.JSON_FALSE, size_t.max};

		return &the_false;
	}

///
extern (C)
nothrow @trusted @nogc @live
public jansson_d.jansson.json_t* json_null()

	do
	{
		static jansson_d.jansson.json_t the_null = {jansson_d.jansson.json_type.JSON_NULL, size_t.max};

		return &the_null;
	}

/* deletion */

///
extern (C)
nothrow @trusted @nogc
public void json_delete(scope jansson_d.jansson.json_t* json)

	do
	{
		if (json == null) {
			return;
		}

		switch (mixin (jansson_d.jansson.json_typeof!("json"))) {
			case jansson_d.jansson.json_type.JSON_OBJECT:
				.json_delete_object(mixin (jansson_d.jansson_private.json_to_object!("json")));

				break;

			case jansson_d.jansson.json_type.JSON_ARRAY:
				.json_delete_array(mixin (jansson_d.jansson_private.json_to_array!("json")));

				break;

			case jansson_d.jansson.json_type.JSON_STRING:
				.json_delete_string(mixin (jansson_d.jansson_private.json_to_string!("json")));

				break;

			case jansson_d.jansson.json_type.JSON_INTEGER:
				.json_delete_integer(mixin (jansson_d.jansson_private.json_to_integer!("json")));

				break;

			case jansson_d.jansson.json_type.JSON_REAL:
				.json_delete_real(mixin (jansson_d.jansson_private.json_to_real!("json")));

				break;

			default:
				return;
		}

		/* json_delete is not called for true, false or null */
	}

/* equality */

///
extern (C)
nothrow @trusted @nogc @live
public int json_equal(scope const jansson_d.jansson.json_t* json1, scope const jansson_d.jansson.json_t* json2)

	do
	{
		if ((json1 == null) || (json2 == null)) {
			return 0;
		}

		if (mixin (jansson_d.jansson.json_typeof!("json1")) != mixin (jansson_d.jansson.json_typeof!("json2"))) {
			return 0;
		}

		/* this covers true, false and null as they are singletons */
		if (json1 == json2) {
			return 1;
		}

		switch (mixin (jansson_d.jansson.json_typeof!("json1"))) {
			case jansson_d.jansson.json_type.JSON_OBJECT:
				return .json_object_equal(json1, json2);

			case jansson_d.jansson.json_type.JSON_ARRAY:
				return .json_array_equal(json1, json2);

			case jansson_d.jansson.json_type.JSON_STRING:
				return .json_string_equal(json1, json2);

			case jansson_d.jansson.json_type.JSON_INTEGER:
				return .json_integer_equal(json1, json2);

			case jansson_d.jansson.json_type.JSON_REAL:
				return .json_real_equal(json1, json2);

			default:
				return 0;
		}
	}

/* copying */

///
//nodiscard
extern (C)
nothrow @trusted @nogc
public jansson_d.jansson.json_t* json_copy(scope jansson_d.jansson.json_t* json)

	do
	{
		if (json == null) {
			return null;
		}

		switch (mixin (jansson_d.jansson.json_typeof!("json"))) {
			case jansson_d.jansson.json_type.JSON_OBJECT:
				return .json_object_copy(json);

			case jansson_d.jansson.json_type.JSON_ARRAY:
				return .json_array_copy(json);

			case jansson_d.jansson.json_type.JSON_STRING:
				return .json_string_copy(json);

			case jansson_d.jansson.json_type.JSON_INTEGER:
				return .json_integer_copy(json);

			case jansson_d.jansson.json_type.JSON_REAL:
				return .json_real_copy(json);

			case jansson_d.jansson.json_type.JSON_TRUE:
			case jansson_d.jansson.json_type.JSON_FALSE:
			case jansson_d.jansson.json_type.JSON_NULL:
				return json;

			default:
				return null;
		}
	}

///
//nodiscard
extern (C)
nothrow @trusted @nogc
public jansson_d.jansson.json_t* json_deep_copy(scope const jansson_d.jansson.json_t* json)

	do
	{
		jansson_d.hashtable.hashtable_t parents_set = void;

		if (jansson_d.hashtable.hashtable_init(&parents_set)) {
			return null;
		}

		jansson_d.jansson.json_t* res = .do_deep_copy(json, &parents_set);
		jansson_d.hashtable.hashtable_close(&parents_set);

		return res;
	}

nothrow @trusted @nogc
jansson_d.jansson.json_t* do_deep_copy(scope const jansson_d.jansson.json_t* json, scope jansson_d.hashtable.hashtable_t* parents)

	do
	{
		if (json == null) {
			return null;
		}

		switch (mixin (jansson_d.jansson.json_typeof!("json"))) {
			case jansson_d.jansson.json_type.JSON_OBJECT:
				return .json_object_deep_copy(json, parents);

			case jansson_d.jansson.json_type.JSON_ARRAY:
				return .json_array_deep_copy(json, parents);

			/*
			 * for the rest of the types, deep copying doesn't differ from
			 * shallow copying
			 */
			case jansson_d.jansson.json_type.JSON_STRING:
				return .json_string_copy(json);

			case jansson_d.jansson.json_type.JSON_INTEGER:
				return .json_integer_copy(json);

			case jansson_d.jansson.json_type.JSON_REAL:
				return .json_real_copy(json);

			case jansson_d.jansson.json_type.JSON_TRUE:
			case jansson_d.jansson.json_type.JSON_FALSE:
			case jansson_d.jansson.json_type.JSON_NULL:
				return cast(jansson_d.jansson.json_t*)(json);

			default:
				return null;
		}
	}
