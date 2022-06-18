/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.jansson;


private static import core.stdc.config;
private static import core.stdc.stdio;
private static import jansson_d.dump;
private static import jansson_d.hashtable_seed;
private static import jansson_d.jansson_config;
private static import jansson_d.load;
private static import jansson_d.memory;
private static import jansson_d.pack_unpack;
private static import jansson_d.value;
private static import jansson_d.version_;

/* version */

///
public enum JANSSON_MAJOR_VERSION = 2;

///
public enum JANSSON_MINOR_VERSION = 14;

///
public enum JANSSON_MICRO_VERSION = 0;

/* Micro version is omitted if it's 0 */
///
public enum JANSSON_VERSION = "2.14";

/**
 * Version as a 3-byte hex number, e.g. 0x010201 == 1.2.1. Use this
 * for numeric comparisons, e.g. #if JANSSON_VERSION_HEX >= ...
 */
public enum JANSSON_VERSION_HEX = (.JANSSON_MAJOR_VERSION << 16) | (.JANSSON_MINOR_VERSION << 8) | (.JANSSON_MICRO_VERSION << 0);

/*
 * If __atomic or __sync builtins are available the library is thread
 * safe for all read-only functions plus reference counting.
 */
static if ((jansson_d.jansson_config.JSON_HAVE_ATOMIC_BUILTINS) || (jansson_d.jansson_config.JSON_HAVE_SYNC_BUILTINS)) {
	enum JANSSON_THREAD_SAFE_REFCOUNT = 1;
}

//#if (defined(__GNUC__)) || (defined(__clang__))
	//#define JANSSON_ATTRS(x) __attribute__(x)
//#else
	//#define JANSSON_ATTRS(x)
//#endif

/* types */

///
public enum json_type
{
	JSON_OBJECT,
	JSON_ARRAY,
	JSON_STRING,
	JSON_INTEGER,
	JSON_REAL,
	JSON_TRUE,
	JSON_FALSE,
	JSON_NULL,
}

//Declaration name in C language
public enum
{
	JSON_OBJECT = .json_type.JSON_OBJECT,
	JSON_ARRAY = .json_type.JSON_ARRAY,
	JSON_STRING = .json_type.JSON_STRING,
	JSON_INTEGER = .json_type.JSON_INTEGER,
	JSON_REAL = .json_type.JSON_REAL,
	JSON_TRUE = .json_type.JSON_TRUE,
	JSON_FALSE = .json_type.JSON_FALSE,
	JSON_NULL = .json_type.JSON_NULL,
}

///
extern (C)
public struct json_t
{
	json_type type = cast(.json_type)(0);

	/* volatile */
	size_t refcount;
}

/* disabled if using cmake */
//version (JANSSON_USING_CMAKE) {
version (all) {
	///
	public enum JSON_INTEGER_FORMAT = "lld";

	///
	public alias json_int_t = long;

	static assert(jansson_d.jansson_config.JSON_INTEGER_IS_LONG_LONG);
} else {
	static if (jansson_d.jansson_config.JSON_INTEGER_IS_LONG_LONG) {
		//version (Windows) {
		version (none) {
			public enum JSON_INTEGER_FORMAT = "I64d";
		} else {
			public enum JSON_INTEGER_FORMAT = "lld";
		}

		version (none) {
			public alias json_int_t = core.stdc.config.cpp_longlong;
		} else {
			public alias json_int_t = long;
		}
	} else {
		enum JSON_INTEGER_FORMAT = "ld";
		public alias json_int_t = core.stdc.config.c_long;
	}
}

///
pragma(inline, true)
pure nothrow @trusted @nogc @live
public .json_type json_typeof(scope const .json_t* json)

	in
	{
		assert(json != null);
	}

	do
	{
		return mixin (.json_typeof!("json"));
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public bool json_is_object(scope const .json_t* json)

	do
	{
		return mixin (.json_is_object!("json"));
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public bool json_is_array(scope const .json_t* json)

	do
	{
		return mixin (.json_is_array!("json"));
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public bool json_is_string(scope const .json_t* json)

	do
	{
		return mixin (.json_is_string!("json"));
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public bool json_is_integer(scope const .json_t* json)

	do
	{
		return mixin (.json_is_integer!("json"));
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public bool json_is_real(scope const .json_t* json)

	do
	{
		return mixin (.json_is_real!("json"));
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public bool json_is_number(scope const .json_t* json)

	do
	{
		return mixin (.json_is_number!("json"));
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public bool json_is_true(scope const .json_t* json)

	do
	{
		return mixin (.json_is_true!("json"));
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public bool json_is_false(scope const .json_t* json)

	do
	{
		return mixin (.json_is_false!("json"));
	}

///Ditto
public alias json_boolean_value = .json_is_true;

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public bool json_is_boolean(scope const .json_t* json)

	do
	{
		return mixin (.json_is_boolean!("json"));
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public bool json_is_null(scope const .json_t* json)

	do
	{
		return mixin (.json_is_null!("json"));
	}

///Ditto
public template json_typeof(string json)
{
	enum json_typeof = "((" ~ json ~ ").type)";
}

///Ditto
public template json_is_object(string json)
{
	enum json_is_object = "((" ~ json ~ " != null) && (mixin (jansson_d.jansson.json_typeof!(\"" ~ json ~ "\")) == jansson_d.jansson.json_type.JSON_OBJECT))";
}

///Ditto
public template json_is_array(string json)
{
	enum json_is_array = "((" ~ json ~ " != null) && (mixin (jansson_d.jansson.json_typeof!(\"" ~ json ~ "\")) == jansson_d.jansson.json_type.JSON_ARRAY))";
}

///Ditto
public template json_is_string(string json)
{
	enum json_is_string = "((" ~ json ~ " != null) && (mixin (jansson_d.jansson.json_typeof!(\"" ~ json ~ "\")) == jansson_d.jansson.json_type.JSON_STRING))";
}

///Ditto
public template json_is_integer(string json)
{
	enum json_is_integer = "((" ~ json ~ " != null) && (mixin (jansson_d.jansson.json_typeof!(\"" ~ json ~ "\")) == jansson_d.jansson.json_type.JSON_INTEGER))";
}

///Ditto
public template json_is_real(string json)
{
	enum json_is_real = "((" ~ json ~ " != null) && (mixin (jansson_d.jansson.json_typeof!(\"" ~ json ~ "\")) == jansson_d.jansson.json_type.JSON_REAL))";
}

///Ditto
public template json_is_number(string json)
{
	enum json_is_number = "((mixin (jansson_d.jansson.json_is_integer!(\"" ~ json ~ "\"))) || (mixin (jansson_d.jansson.json_is_real!(\"" ~ json ~ "\"))))";
}

///Ditto
public template json_is_true(string json)
{
	enum json_is_true = "((" ~ json ~ " != null) && (mixin (jansson_d.jansson.json_typeof!(\"" ~ json ~ "\")) == jansson_d.jansson.json_type.JSON_TRUE))";
}

///Ditto
public template json_is_false(string json)
{
	enum json_is_false = "((" ~ json ~ " != null) && (mixin (jansson_d.jansson.json_typeof!(\"" ~ json ~ "\")) == jansson_d.jansson.json_type.JSON_FALSE))";
}

///Ditto
public template json_is_boolean(string json)
{
	enum json_is_boolean = "((mixin (jansson_d.jansson.json_is_true!(\"" ~ json ~ "\"))) || (mixin (jansson_d.jansson.json_is_false!(\"" ~ json ~ "\"))))";
}

///Ditto
public template json_is_null(string json)
{
	enum json_is_null = "((" ~ json ~ " != null) && (mixin (jansson_d.jansson.json_typeof!(\"" ~ json ~ "\")) == jansson_d.jansson.json_type.JSON_NULL))";
}

/* construction, destruction, reference counting */

///
public alias json_object = jansson_d.value.json_object;

///
public alias json_array = jansson_d.value.json_array;

///
public alias json_string = jansson_d.value.json_string;

///
public alias json_stringn = jansson_d.value.json_stringn;

///
public alias json_string_nocheck = jansson_d.value.json_string_nocheck;

///
public alias json_stringn_nocheck = jansson_d.value.json_stringn_nocheck;

///
public alias json_integer = jansson_d.value.json_integer;

///
public alias json_real = jansson_d.value.json_real;

///
public alias json_true = jansson_d.value.json_true;

///
public alias json_false = jansson_d.value.json_false;

///
pragma(inline, true)
pure nothrow @trusted @nogc @live
public .json_t* json_boolean(VAL)(VAL val)

	do
	{
		return mixin (.json_boolean!("val"));
	}

///Ditto
public template json_boolean(string val)
{
	enum json_boolean = "((" ~ val ~ ") ? (jansson_d.value.json_true()) : (jansson_d.value.json_false()))";
}

///
public alias json_null = jansson_d.value.json_null;

/* do not call JSON_INTERNAL_INCREF or JSON_INTERNAL_DECREF directly */
static if (jansson_d.jansson_config.JSON_HAVE_ATOMIC_BUILTINS) {
	//#define JSON_INTERNAL_INCREF(json) __atomic_add_fetch(&json.refcount, 1, __ATOMIC_ACQUIRE)
	//#define JSON_INTERNAL_DECREF(json) __atomic_sub_fetch(&json.refcount, 1, __ATOMIC_RELEASE)
	static assert(false);
} else static if (jansson_d.jansson_config.JSON_HAVE_SYNC_BUILTINS) {
	//#define JSON_INTERNAL_INCREF(json) __sync_add_and_fetch(&json.refcount, 1)
	//#define JSON_INTERNAL_DECREF(json) __sync_sub_and_fetch(&json.refcount, 1)
	static assert(false);
} else {
	template JSON_INTERNAL_INCREF(string json)
	{
		enum JSON_INTERNAL_INCREF = "(++" ~ json ~ ".refcount);";
	}

	template JSON_INTERNAL_DECREF(string json)
	{
		enum JSON_INTERNAL_DECREF = "(--" ~ json ~ ".refcount);";
	}
}

///
pragma(inline, true)
pure nothrow @trusted @nogc @live
public .json_t* json_incref(scope .json_t* json)

	do
	{
		if ((json != null) && (json.refcount != size_t.max)) {
			mixin (.JSON_INTERNAL_INCREF!("json"));
		}

		return json;
	}

/** do not call json_delete directly */
public alias json_delete = jansson_d.value.json_delete;

///
pragma(inline, true)
nothrow @trusted @nogc
public void json_decref(scope .json_t* json)

	do
	{
		if ((json != null) && (json.refcount != size_t.max)) {
			mixin (.JSON_INTERNAL_DECREF!("json"));

			if (json.refcount == 0) {
				jansson_d.value.json_delete(json);
			}
		}
	}

//#if (defined(__GNUC__)) || (defined(__clang__))
version (all) {
	pragma(inline, true)
	nothrow @trusted @nogc
	void json_decrefp(scope .json_t** json)

		do
		{
			if (json != null) {
				.json_decref(*json);
				*json = null;
			}
		}

	version (none) {
		alias json_auto_t = .json_t;
	}

	template json_auto_t_exit(string json)
	{
		enum json_auto_t_exit = "scope (exit) { jansson_d.jansson.json_decrefp(" ~ json ~ "); }";
	}
}

/* error reporting */

///
public enum JSON_ERROR_TEXT_LENGTH = 160;

///
public enum JSON_ERROR_SOURCE_LENGTH = 80;

///
extern (C)
public struct json_error_t
{
	int line;
	int column;
	int position;
	char[.JSON_ERROR_SOURCE_LENGTH] source = '\0';
	char[.JSON_ERROR_TEXT_LENGTH] text = '\0';
}

///
public enum json_error_code_t
{
	json_error_unknown,
	json_error_out_of_memory,
	json_error_stack_overflow,
	json_error_cannot_open_file,
	json_error_invalid_argument,
	json_error_invalid_utf8,
	json_error_premature_end_of_input,
	json_error_end_of_input_expected,
	json_error_invalid_syntax,
	json_error_invalid_format,
	json_error_wrong_type,
	json_error_null_character,
	json_error_null_value,
	json_error_null_byte_in_key,
	json_error_duplicate_key,
	json_error_numeric_overflow,
	json_error_item_not_found,
	json_error_index_out_of_range,
}

//Declaration name in C language
public enum
{
	json_error_unknown = .json_error_code_t.json_error_unknown,
	json_error_out_of_memory = .json_error_code_t.json_error_out_of_memory,
	json_error_stack_overflow = .json_error_code_t.json_error_stack_overflow,
	json_error_cannot_open_file = .json_error_code_t.json_error_cannot_open_file,
	json_error_invalid_argument = .json_error_code_t.json_error_invalid_argument,
	json_error_invalid_utf8 = .json_error_code_t.json_error_invalid_utf8,
	json_error_premature_end_of_input = .json_error_code_t.json_error_premature_end_of_input,
	json_error_end_of_input_expected = .json_error_code_t.json_error_end_of_input_expected,
	json_error_invalid_syntax = .json_error_code_t.json_error_invalid_syntax,
	json_error_invalid_format = .json_error_code_t.json_error_invalid_format,
	json_error_wrong_type = .json_error_code_t.json_error_wrong_type,
	json_error_null_character = .json_error_code_t.json_error_null_character,
	json_error_null_value = .json_error_code_t.json_error_null_value,
	json_error_null_byte_in_key = .json_error_code_t.json_error_null_byte_in_key,
	json_error_duplicate_key = .json_error_code_t.json_error_duplicate_key,
	json_error_numeric_overflow = .json_error_code_t.json_error_numeric_overflow,
	json_error_item_not_found = .json_error_code_t.json_error_item_not_found,
	json_error_index_out_of_range = .json_error_code_t.json_error_index_out_of_range,
}

///
pragma(inline, true)
pure nothrow @trusted @nogc @live
public .json_error_code_t json_error_code(scope const .json_error_t* e)

	in
	{
		assert(e != null);
	}

	do
	{
		return cast(.json_error_code_t)(e.text[e.text.length - 1]);
	}

/* getters, setters, manipulation */

///
public alias json_object_seed = jansson_d.hashtable_seed.json_object_seed;

///
public alias json_object_size = jansson_d.value.json_object_size;

///
public alias json_object_get = jansson_d.value.json_object_get;

///
public alias json_object_getn = jansson_d.value.json_object_getn;

///
public alias json_object_set_new = jansson_d.value.json_object_set_new;

///
public alias json_object_setn_new = jansson_d.value.json_object_setn_new;

///
public alias json_object_set_new_nocheck = jansson_d.value.json_object_set_new_nocheck;

///
public alias json_object_setn_new_nocheck = jansson_d.value.json_object_setn_new_nocheck;

///
public alias json_object_del = jansson_d.value.json_object_del;

///
public alias json_object_deln = jansson_d.value.json_object_deln;

///
public alias json_object_clear = jansson_d.value.json_object_clear;

///
public alias json_object_update = jansson_d.value.json_object_update;

///
public alias json_object_update_existing = jansson_d.value.json_object_update_existing;

///
public alias json_object_update_missing = jansson_d.value.json_object_update_missing;

///
public alias json_object_update_recursive = jansson_d.value.json_object_update_recursive;

///
public alias json_object_iter = jansson_d.value.json_object_iter;

///
public alias json_object_iter_at = jansson_d.value.json_object_iter_at;

///
public alias json_object_key_to_iter = jansson_d.value.json_object_key_to_iter;

///
public alias json_object_iter_next = jansson_d.value.json_object_iter_next;

///
public alias json_object_iter_key = jansson_d.value.json_object_iter_key;

///
public alias json_object_iter_key_len = jansson_d.value.json_object_iter_key_len;

///
public alias json_object_iter_value = jansson_d.value.json_object_iter_value;

///
public alias json_object_iter_set_new = jansson_d.value.json_object_iter_set_new;

//#define json_object_foreach(object, key, value) for (key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter(object)); (key) && (value = jansson_d.value.json_object_iter_value(jansson_d.value.json_object_key_to_iter(key))); key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter_next(object, jansson_d.value.json_object_key_to_iter(key))))

//#define json_object_keylen_foreach(object, key, key_len, value) for (key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter(object)), key_len = jansson_d.value.json_object_iter_key_len(jansson_d.value.json_object_key_to_iter(key)); (key) && (value = jansson_d.value.json_object_iter_value(jansson_d.value.json_object_key_to_iter(key))); key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter_next(object, jansson_d.value.json_object_key_to_iter(key))), key_len = jansson_d.value.json_object_iter_key_len(jansson_d.value.json_object_key_to_iter(key)))

//#define json_object_foreach_safe(object, n, key, value) for (key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter(object)), n = jansson_d.value.json_object_iter_next(object, jansson_d.value.json_object_key_to_iter(key)); (key) && (value = jansson_d.value.json_object_iter_value(jansson_d.value.json_object_key_to_iter(key))); key = jansson_d.value.json_object_iter_key(n), n = jansson_d.value.json_object_iter_next(object, jansson_d.value.json_object_key_to_iter(key)))

//#define json_object_keylen_foreach_safe(object, n, key, key_len, value) for (key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter(object)), n = jansson_d.value.json_object_iter_next(object, jansson_d.value.json_object_key_to_iter(key)), key_len = jansson_d.value.json_object_iter_key_len(jansson_d.value.json_object_key_to_iter(key)); (key) && (value = jansson_d.value.json_object_iter_value(jansson_d.value.json_object_key_to_iter(key))); key = jansson_d.value.json_object_iter_key(n), key_len = jansson_d.value.json_object_iter_key_len(n), n = jansson_d.value.json_object_iter_next(object, jansson_d.value.json_object_key_to_iter(key)))

//#define json_array_foreach(array, index, value) for (index = 0; (index < jansson_d.value.json_array_size(array)) && (value = jansson_d.value.json_array_get(array, index)); index++)

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_object_set(scope .json_t* object, scope const char* key, scope .json_t* value)

	do
	{
		return jansson_d.value.json_object_set_new(object, key, .json_incref(value));
	}

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_object_setn(scope .json_t* object, scope const char* key, size_t key_len, scope .json_t* value)

	do
	{
		return jansson_d.value.json_object_setn_new(object, key, key_len, .json_incref(value));
	}

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_object_set_nocheck(scope .json_t* object, scope const char* key, scope .json_t* value)

	do
	{
		return jansson_d.value.json_object_set_new_nocheck(object, key, .json_incref(value));
	}

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_object_setn_nocheck(scope .json_t* object, scope const char* key, size_t key_len, scope .json_t* value)

	do
	{
		return jansson_d.value.json_object_setn_new_nocheck(object, key, key_len, .json_incref(value));
	}

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_object_iter_set(scope .json_t* object, scope void* iter, scope .json_t* value)

	do
	{
		return jansson_d.value.json_object_iter_set_new(object, iter, .json_incref(value));
	}

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_object_update_new(scope .json_t* object, scope .json_t* other)

	do
	{
		int ret = jansson_d.value.json_object_update(object, other);
		.json_decref(other);

		return ret;
	}

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_object_update_existing_new(scope .json_t* object, scope .json_t* other)

	do
	{
		int ret = jansson_d.value.json_object_update_existing(object, other);
		.json_decref(other);

		return ret;
	}

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_object_update_missing_new(scope .json_t* object, scope .json_t* other)

	do
	{
		int ret = jansson_d.value.json_object_update_missing(object, other);
		.json_decref(other);

		return ret;
	}

///
public alias json_array_size = jansson_d.value.json_array_size;

///
public alias json_array_get = jansson_d.value.json_array_get;

///
public alias json_array_set_new = jansson_d.value.json_array_set_new;

///
public alias json_array_append_new = jansson_d.value.json_array_append_new;

///
public alias json_array_insert_new = jansson_d.value.json_array_insert_new;

///
public alias json_array_remove = jansson_d.value.json_array_remove;

///
public alias json_array_clear = jansson_d.value.json_array_clear;

///
public alias json_array_extend = jansson_d.value.json_array_extend;

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_array_set(scope jansson_d.jansson.json_t* array, size_t ind, scope jansson_d.jansson.json_t* value)

	do
	{
		return jansson_d.value.json_array_set_new(array, ind, .json_incref(value));
	}

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_array_append(scope .json_t* array, scope .json_t* value)

	do
	{
		return jansson_d.value.json_array_append_new(array, .json_incref(value));
	}

///
pragma(inline, true)
nothrow @trusted @nogc
public int json_array_insert(scope .json_t* array, size_t ind, scope .json_t* value)

	do
	{
		return jansson_d.value.json_array_insert_new(array, ind, .json_incref(value));
	}

///
public alias json_string_value = jansson_d.value.json_string_value;

///
public alias json_string_length = jansson_d.value.json_string_length;

///
public alias json_integer_value = jansson_d.value.json_integer_value;

///
public alias json_real_value = jansson_d.value.json_real_value;

///
public alias json_number_value = jansson_d.value.json_number_value;

///
public alias json_string_set = jansson_d.value.json_string_set;

///
public alias json_string_setn = jansson_d.value.json_string_setn;

///
public alias json_string_set_nocheck = jansson_d.value.json_string_set_nocheck;

///
public alias json_string_setn_nocheck = jansson_d.value.json_string_setn_nocheck;

///
public alias json_integer_set = jansson_d.value.json_integer_set;

///
public alias json_real_set = jansson_d.value.json_real_set;

/* pack, unpack */

///
//.JANSSON_ATTRS((warn_unused_result));
public alias json_pack = jansson_d.pack_unpack.json_pack;

///
//.JANSSON_ATTRS((warn_unused_result));
public alias json_pack_ex = jansson_d.pack_unpack.json_pack_ex;

///
//.JANSSON_ATTRS((warn_unused_result));
public alias json_vpack_ex = jansson_d.pack_unpack.json_vpack_ex;

///
public enum JSON_VALIDATE_ONLY = 0x01;

///
public enum JSON_STRICT = 0x02;

///
public alias json_unpack = jansson_d.pack_unpack.json_unpack;

///
public alias json_unpack_ex = jansson_d.pack_unpack.json_unpack_ex;

///
public alias json_vunpack_ex = jansson_d.pack_unpack.json_vunpack_ex;

/* sprintf */

///
public alias json_sprintf = jansson_d.value.json_sprintf;

///
public alias json_vsprintf = jansson_d.value.json_vsprintf;

/* equality */

///
public alias json_equal = jansson_d.value.json_equal;

/* copying */

///
public alias json_copy = jansson_d.value.json_copy;

///
public alias json_deep_copy = jansson_d.value.json_deep_copy;

/* decoding */

///
public enum JSON_REJECT_DUPLICATES = 0x01;

///
public enum JSON_DISABLE_EOF_CHECK = 0x02;

///
public enum JSON_DECODE_ANY = 0x04;

///
public enum JSON_DECODE_INT_AS_REAL = 0x08;

///
public enum JSON_ALLOW_NUL = 0x10;

///
public alias json_load_callback_t = extern (C) nothrow @nogc size_t function(scope void* buffer, size_t buflen, scope void* data);

///
public alias json_loads = jansson_d.load.json_loads;

///
public alias json_loadb = jansson_d.load.json_loadb;

///
public alias json_loadf = jansson_d.load.json_loadf;

///
public alias json_loadfd = jansson_d.load.json_loadfd;

///
public alias json_load_file = jansson_d.load.json_load_file;

///
public alias json_load_callback = jansson_d.load.json_load_callback;

/* encoding */

///
public enum JSON_MAX_INDENT = 0x1F;

///
public template JSON_INDENT(string n)
{
	enum JSON_INDENT = "((" ~ n ~ ") & jansson_d.jansson.JSON_MAX_INDENT)";
}

///
public enum JSON_COMPACT = 0x20;

///
public enum JSON_ENSURE_ASCII = 0x40;

///
public enum JSON_SORT_KEYS = 0x80;

///
public enum JSON_PRESERVE_ORDER = 0x0100;

///
public enum JSON_ENCODE_ANY = 0x0200;

///
public enum JSON_ESCAPE_SLASH = 0x0400;

///
public template JSON_REAL_PRECISION(string n)
{
	enum JSON_REAL_PRECISION = "(((" ~ n ~ ") & 0x1F) << 11)";
}

///
public enum JSON_EMBED = 0x010000;

///
public alias json_dump_callback_t = extern (C) nothrow @nogc @live int function(scope const char* buffer, size_t size, void* data);

///
public alias json_dumps = jansson_d.dump.json_dumps;

///
public alias json_dumpb = jansson_d.dump.json_dumpb;

///
public alias json_dumpf = jansson_d.dump.json_dumpf;

///
public alias json_dumpfd = jansson_d.dump.json_dumpfd;

///
public alias json_dump_file = jansson_d.dump.json_dump_file;

///
public alias json_dump_callback = jansson_d.dump.json_dump_callback;

/* custom memory allocation */

///
public alias json_malloc_t = extern (C) nothrow @nogc void* function(size_t);

///
public alias json_free_t = extern (C) nothrow @nogc void function(void*);

///
public alias json_set_alloc_funcs = jansson_d.memory.json_set_alloc_funcs;

///
public alias json_get_alloc_funcs = jansson_d.memory.json_get_alloc_funcs;

/* runtime version checking */
///
public alias jansson_version_str = jansson_d.version_.jansson_version_str;

///
public alias jansson_version_cmp = jansson_d.version_.jansson_version_cmp;
