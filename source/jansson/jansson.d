/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.jansson;


private static import core.stdc.config;
private static import core.stdc.stdio;
private static import core.stdc.string;
private static import jansson.dump;
private static import jansson.hashtable_seed;
private static import jansson.jansson_config;
private static import jansson.load;
private static import jansson.memory;
private static import jansson.pack_unpack;
private static import jansson.value;
private static import jansson.version_;
private static import std.traits;
private static import std.typecons;

version (GNU) {
	private static import gcc.attributes;
}

private import jansson.jansson_config: JSON_INLINE;

version (D_BetterC) {
} else {
	version = JANSSON_D_NOT_BETTER_C;
}

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
static if ((jansson.jansson_config.JSON_HAVE_ATOMIC_BUILTINS) || (jansson.jansson_config.JSON_HAVE_SYNC_BUILTINS)) {
	enum JANSSON_THREAD_SAFE_REFCOUNT = 1;
}

version (GNU) {
	public alias JANSSON_ATTRS = gcc.attributes.attribute;
} else {
	private struct JANSSON_ATTRS_(A...)
	{
		A arguments;
	}

	pure nothrow @safe @nogc @live
	public auto JANSSON_ATTRS(A...)(A arguments)

		do
		{
			return .JANSSON_ATTRS_!(A)(arguments);
		}
}

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
	.json_type type = cast(.json_type)(0);

	/* volatile */
	size_t refcount;

private:
	extern (D)
	int json_object_foreach(int delegate (ref const (char)* key, ref .json_t* value) operations, .json_t* object_)

		do
		{
			int result = 0;

			const (char)* key = void;
			.json_t* value = void;

			for (key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_)); (key != null) && ((value = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(key))) != null); key = jansson.value.json_object_iter_key(jansson.value.json_object_iter_next(object_, jansson.value.json_object_key_to_iter(key)))) {
				result = operations(key, value);

				if (result) {
					break;
				}
			}

			return result;
		}

	extern (D)
	int json_object_keylen_foreach(int delegate (ref const (char)* key, ref size_t key_len, ref .json_t* value) operations, .json_t* object_)

		do
		{
			int result = 0;

			const (char)* key = void;
			size_t key_len = void;
			.json_t* value = void;

			for (key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_)), key_len = jansson.value.json_object_iter_key_len(jansson.value.json_object_key_to_iter(key)); (key != null) && ((value = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(key))) != null); key = jansson.value.json_object_iter_key(jansson.value.json_object_iter_next(object_, jansson.value.json_object_key_to_iter(key))), key_len = jansson.value.json_object_iter_key_len(jansson.value.json_object_key_to_iter(key))) {
				result = operations(key, key_len, value);

				if (result) {
					break;
				}
			}

			return result;
		}

	extern (D)
	int json_object_foreach_safe(int delegate (ref void* n, ref const (char)* key, ref .json_t* value) operations, .json_t* object_)

		do
		{
			int result = 0;

			void* n = void;
			const (char)* key = void;
			.json_t* value = void;

			for (key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_)), n = jansson.value.json_object_iter_next(object_, jansson.value.json_object_key_to_iter(key)); (key != null) && ((value = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(key))) != null); key = jansson.value.json_object_iter_key(n), n = jansson.value.json_object_iter_next(object_, jansson.value.json_object_key_to_iter(key))) {
				result = operations(n, key, value);

				if (result) {
					break;
				}
			}

			return result;
		}

	extern (D)
	int json_object_keylen_foreach_safe(int delegate (ref void* n, ref const (char)* key, ref size_t key_len, ref .json_t* value) operations, .json_t* object_)

		do
		{
			int result = 0;

			void* n = void;
			const (char)* key = void;
			size_t key_len = void;
			.json_t* value = void;

			for (key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_)), n = jansson.value.json_object_iter_next(object_, jansson.value.json_object_key_to_iter(key)), key_len = jansson.value.json_object_iter_key_len(jansson.value.json_object_key_to_iter(key)); (key != null) && ((value = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(key))) != null); key = jansson.value.json_object_iter_key(n), key_len = jansson.value.json_object_iter_key_len(n), n = jansson.value.json_object_iter_next(object_, jansson.value.json_object_key_to_iter(key))) {
				result = operations(n, key, key_len, value);

				if (result) {
					break;
				}
			}

			return result;
		}

	extern (D)
	int json_array_foreach(int delegate (ref size_t index, ref .json_t* value) operations, .json_t* object_)

		do
		{
			int result = 0;

			.json_t* value = void;

			for (size_t index = 0; (index < jansson.value.json_array_size(object_)) && ((value = jansson.value.json_array_get(object_, index)) != null); index++) {
				result = operations(index, value);

				if (result) {
					break;
				}
			}

			return result;
		}

public:
	extern (D)
	int opApply(int delegate (ref const (char)* key, ref .json_t* value) operations)

		do
		{
			return this.json_object_foreach(operations, &this);
		}

	extern (D)
	int opApply(int delegate (ref const (char)* key, ref size_t key_len, ref .json_t* value) operations)

		do
		{
			return this.json_object_keylen_foreach(operations, &this);
		}

	extern (D)
	int opApply(int delegate (ref void* n, ref const (char)* key, ref .json_t* value) operations)

		do
		{
			return this.json_object_foreach_safe(operations, &this);
		}

	extern (D)
	int opApply(int delegate (ref void* n, ref const (char)* key, ref size_t key_len, ref .json_t* value) operations)

		do
		{
			return this.json_object_keylen_foreach_safe(operations, &this);
		}

	extern (D)
	int opApply(int delegate (ref size_t index, ref .json_t* value) operations)

		do
		{
			return this.json_array_foreach(operations, &this);
		}

	version (JANSSON_D_NOT_BETTER_C)
	extern (D)
	static json_t* opCall(A)(A input)
		if (std.traits.isDynamicArray!(A))

		do
		{
			if (input.length != 0) {
				throw new JanssonException("Initialization of non-empty arrays is not yet supported");
			}

			return .json_array();
		}

	extern (D)
	nothrow @trusted @nogc
	static json_t* opCall(const (char)* input)

		do
		{
			return (input != null) ? (.json_string(input)) : (.json_null());
		}

	extern (D)
	nothrow @trusted @nogc
	static json_t* opCall(scope const char* input, size_t flags, scope jansson.jansson.json_error_t* error)

		do
		{
			return .json_loads(input, flags, error);
		}

	extern (D)
	nothrow @trusted @nogc
	static json_t* opCall(I)(I input)
		if ((is(I == bool)) || (is(I: .json_int_t)) || (is(I: double)))

		do
		{
			static if (is(I == bool)) {
				return (input) ? (.json_true()) : (.json_false());
			} else static if ((is(I: .json_int_t)) && (.json_int_t.max >= I.max)) {
				return .json_integer(input);
			} else {
				return .json_real(input);
			}
		}

	extern (D)
	nothrow @safe @nogc @live
	bool opEquals()(auto const ref .json_t input) const

		do
		{
			return .json_equal(&this, &input) == 1;
		}

	extern (D)
	pure nothrow @trusted @nogc @live
	bool opEquals(.json_type input) const

		do
		{
			return input == this.type;
		}

	extern (D)
	pure nothrow @trusted @nogc @live
	bool opEquals(scope const char* input) const

		do
		{
			if (input == null) {
				return this.type == .json_type.JSON_NULL;
			}

			if (this.type != .json_type.JSON_STRING) {
				return false;
			}

			size_t length_ = core.stdc.string.strlen(input);

			return (length_ == .json_string_length(&this)) && (core.stdc.string.memcmp(input, .json_string_value(&this), length_) == 0);
		}

	extern (D)
	pure nothrow @safe @nogc @live
	bool opEquals(I)(I input) const
		if ((is(I == bool)) || (is(I: .json_int_t)) || (is(I: double)))

		do
		{
			switch (this.type) {
				case .json_type.JSON_INTEGER:
					return input == .json_integer_value(&this);

				case .json_type.JSON_REAL:
					return input == .json_real_value(&this);

				default:
					if (input == 0) {
						return this.type == .json_type.JSON_FALSE;
					}

					if (input == 1) {
						return this.type == .json_type.JSON_TRUE;
					}

					return false;
			}
		}
}

/* disabled if using cmake */
//version (JANSSON_USING_CMAKE) {
version (all) {
	///
	public enum JSON_INTEGER_FORMAT = "lld";

	///
	public alias json_int_t = long;

	static assert(jansson.jansson_config.JSON_INTEGER_IS_LONG_LONG);
} else {
	static if (jansson.jansson_config.JSON_INTEGER_IS_LONG_LONG) {
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
	enum json_is_object = "((" ~ json ~ " != null) && (" ~ jansson.jansson.json_typeof!(json) ~ " == jansson.jansson.json_type.JSON_OBJECT))";
}

///Ditto
public template json_is_array(string json)
{
	enum json_is_array = "((" ~ json ~ " != null) && (" ~ jansson.jansson.json_typeof!(json) ~ " == jansson.jansson.json_type.JSON_ARRAY))";
}

///Ditto
public template json_is_string(string json)
{
	enum json_is_string = "((" ~ json ~ " != null) && (" ~ jansson.jansson.json_typeof!(json) ~ " == jansson.jansson.json_type.JSON_STRING))";
}

///Ditto
public template json_is_integer(string json)
{
	enum json_is_integer = "((" ~ json ~ " != null) && (" ~ jansson.jansson.json_typeof!(json) ~ " == jansson.jansson.json_type.JSON_INTEGER))";
}

///Ditto
public template json_is_real(string json)
{
	enum json_is_real = "((" ~ json ~ " != null) && (" ~ jansson.jansson.json_typeof!(json) ~ " == jansson.jansson.json_type.JSON_REAL))";
}

///Ditto
public template json_is_number(string json)
{
	enum json_is_number = "((" ~ jansson.jansson.json_is_integer!(json) ~ ") || (" ~ jansson.jansson.json_is_real!(json) ~ "))";
}

///Ditto
public template json_is_true(string json)
{
	enum json_is_true = "((" ~ json ~ " != null) && (" ~ jansson.jansson.json_typeof!(json) ~ " == jansson.jansson.json_type.JSON_TRUE))";
}

///Ditto
public template json_is_false(string json)
{
	enum json_is_false = "((" ~ json ~ " != null) && (" ~ jansson.jansson.json_typeof!(json) ~ " == jansson.jansson.json_type.JSON_FALSE))";
}

///Ditto
public template json_is_boolean(string json)
{
	enum json_is_boolean = "((" ~ jansson.jansson.json_is_true!(json) ~ ") || (" ~ jansson.jansson.json_is_false!(json) ~ "))";
}

///Ditto
public template json_is_null(string json)
{
	enum json_is_null = "((" ~ json ~ " != null) && (" ~ jansson.jansson.json_typeof!(json) ~ " == jansson.jansson.json_type.JSON_NULL))";
}

/* construction, destruction, reference counting */

///
public alias json_object = jansson.value.json_object;

///
public alias json_array = jansson.value.json_array;

///
public alias json_string = jansson.value.json_string;

///
public alias json_stringn = jansson.value.json_stringn;

///
public alias json_string_nocheck = jansson.value.json_string_nocheck;

///
public alias json_stringn_nocheck = jansson.value.json_stringn_nocheck;

///
public alias json_integer = jansson.value.json_integer;

///
public alias json_real = jansson.value.json_real;

///
public alias json_true = jansson.value.json_true;

///
public alias json_false = jansson.value.json_false;

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
	enum json_boolean = "((" ~ val ~ ") ? (jansson.value.json_true()) : (jansson.value.json_false()))";
}

///
public alias json_null = jansson.value.json_null;

/* do not call JSON_INTERNAL_INCREF or JSON_INTERNAL_DECREF directly */
static if (jansson.jansson_config.JSON_HAVE_ATOMIC_BUILTINS) {
	//#define JSON_INTERNAL_INCREF(json) __atomic_add_fetch(&json.refcount, 1, __ATOMIC_ACQUIRE)
	//#define JSON_INTERNAL_DECREF(json) __atomic_sub_fetch(&json.refcount, 1, __ATOMIC_RELEASE)
	static assert(false);
} else static if (jansson.jansson_config.JSON_HAVE_SYNC_BUILTINS) {
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
@JSON_INLINE
pure nothrow @trusted @nogc @live
public .json_t* json_incref(return scope .json_t* json)

	do
	{
		if ((json != null) && (json.refcount != size_t.max)) {
			mixin (.JSON_INTERNAL_INCREF!("json"));
		}

		return json;
	}

/** do not call json_delete directly */
public alias json_delete = jansson.value.json_delete;

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public void json_decref(scope .json_t* json)

	do
	{
		if ((json != null) && (json.refcount != size_t.max)) {
			mixin (.JSON_INTERNAL_DECREF!("json"));

			if (json.refcount == 0) {
				jansson.value.json_delete(json);
			}
		}
	}

//#if (defined(__GNUC__)) || (defined(__clang__))
version (all) {
	pragma(inline, true)
	@JSON_INLINE
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
@JSON_INLINE
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
public alias json_object_seed = jansson.hashtable_seed.json_object_seed;

///
public alias json_object_size = jansson.value.json_object_size;

///
public alias json_object_get = jansson.value.json_object_get;

///
public alias json_object_getn = jansson.value.json_object_getn;

///
public alias json_object_set_new = jansson.value.json_object_set_new;

///
public alias json_object_setn_new = jansson.value.json_object_setn_new;

///
public alias json_object_set_new_nocheck = jansson.value.json_object_set_new_nocheck;

///
public alias json_object_setn_new_nocheck = jansson.value.json_object_setn_new_nocheck;

///
public alias json_object_del = jansson.value.json_object_del;

///
public alias json_object_deln = jansson.value.json_object_deln;

///
public alias json_object_clear = jansson.value.json_object_clear;

///
public alias json_object_update = jansson.value.json_object_update;

///
public alias json_object_update_existing = jansson.value.json_object_update_existing;

///
public alias json_object_update_missing = jansson.value.json_object_update_missing;

///
public alias json_object_update_recursive = jansson.value.json_object_update_recursive;

///
public alias json_object_iter = jansson.value.json_object_iter;

///
public alias json_object_iter_at = jansson.value.json_object_iter_at;

///
public alias json_object_key_to_iter = jansson.value.json_object_key_to_iter;

///
public alias json_object_iter_next = jansson.value.json_object_iter_next;

///
public alias json_object_iter_key = jansson.value.json_object_iter_key;

///
public alias json_object_iter_key_len = jansson.value.json_object_iter_key_len;

///
public alias json_object_iter_value = jansson.value.json_object_iter_value;

///
public alias json_object_iter_set_new = jansson.value.json_object_iter_set_new;


alias json_object_return = std.typecons.Tuple!(const (char)*, "key", .json_t*, "value");
alias json_object_keylen_return = std.typecons.Tuple!(const (char)*, "key", size_t, "key_len", .json_t*, "value");
alias json_object_foreach_safe_return = std.typecons.Tuple!(void*, "n", const (char)*, "key", .json_t*, "value");
alias json_object_keylen_foreach_safe_return = std.typecons.Tuple!(void*, "n", const (char)*, "key", size_t, "key_len", .json_t*, "value");
alias json_array_return = std.typecons.Tuple!(size_t, "index", .json_t*, "value");

private struct json_object_foreach_internal1
{
private:
	.json_t** object_ = void;
	const (char)** key = void;
	.json_t** value = void;

public:
	pure nothrow @trusted @nogc @live
	this(ref .json_t* object_, ref const (char)* key, ref .json_t* value)

		do
		{
			key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_));
			this.object_ = &object_;
			this.key = &key;
			this.value = &value;
		}

	pure nothrow @safe @nogc @live
	int front() scope

		do
		{
			//dummy
			return 0;
		}

	pure nothrow @safe @nogc @live
	void popFront()

		do
		{
			*(this.key) = jansson.value.json_object_iter_key(jansson.value.json_object_iter_next(*(this.object_), jansson.value.json_object_key_to_iter(*(this.key))));
		}

	pure nothrow @safe @nogc @live
	bool empty()

		do
		{
			return (*(this.key) == null) || ((*(this.value) = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(*(this.key)))) == null);
		}
}

private struct json_object_foreach_internal2
{
private:
	.json_t* object_ = void;
	const (char)* key = void;
	.json_t* value = void;

public:
	pure nothrow @safe @nogc @live
	this(.json_t* object_)

		do
		{
			this.object_ = object_;
			this.key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_));
		}

	pure nothrow @safe @nogc @live
	.json_object_return front()

		do
		{
			.json_object_return result;

			result.key = this.key;
			result.value = this.value;

			return result;
		}

	pure nothrow @safe @nogc @live
	void popFront()

		do
		{
			this.key = jansson.value.json_object_iter_key(jansson.value.json_object_iter_next(this.object_, jansson.value.json_object_key_to_iter(this.key)));
		}

	pure nothrow @safe @nogc @live
	bool empty()

		do
		{
			return (this.key == null) || ((this.value = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(this.key))) == null);
		}
}

private struct json_object_keylen_foreach_internal1
{
private:
	.json_t** object_ = void;
	const (char)** key = void;
	size_t* key_len;
	.json_t** value = void;

public:
	pure nothrow @trusted @nogc @live
	this(ref .json_t* object_, ref const (char)* key, ref size_t key_len, ref .json_t* value)

		do
		{
			key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_));
			key_len = jansson.value.json_object_iter_key_len(jansson.value.json_object_key_to_iter(key));
			this.object_ = &object_;
			this.key = &key;
			this.key_len = &key_len;
			this.value = &value;
		}

	pure nothrow @safe @nogc @live
	int front() scope

		do
		{
			//dummy
			return 0;
		}

	pure nothrow @safe @nogc @live
	void popFront()

		do
		{
			*(this.key) = jansson.value.json_object_iter_key(jansson.value.json_object_iter_next(*(this.object_), jansson.value.json_object_key_to_iter(*(this.key))));
			*(this.key_len) = jansson.value.json_object_iter_key_len(jansson.value.json_object_key_to_iter(*(this.key)));
		}

	pure nothrow @safe @nogc @live
	bool empty()

		do
		{
			return (*(this.key) == null) || ((*(this.value) = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(*(this.key)))) == null);
		}
}

private struct json_object_keylen_foreach_internal2
{
private:
	.json_t* object_ = void;
	const (char)* key = void;
	size_t key_len;
	.json_t* value = void;

public:
	pure nothrow @safe @nogc @live
	this(.json_t* object_)

		do
		{
			this.object_ = object_;
			this.key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_));
			this.key_len = jansson.value.json_object_iter_key_len(jansson.value.json_object_key_to_iter(this.key));
		}

	pure nothrow @safe @nogc @live
	.json_object_keylen_return front()

		do
		{
			.json_object_keylen_return result;

			result.key = this.key;
			result.key_len = this.key_len;
			result.value = this.value;

			return result;
		}

	pure nothrow @safe @nogc @live
	void popFront()

		do
		{
			this.key = jansson.value.json_object_iter_key(jansson.value.json_object_iter_next(this.object_, jansson.value.json_object_key_to_iter(this.key)));
			this.key_len = jansson.value.json_object_iter_key_len(jansson.value.json_object_key_to_iter(this.key));
		}

	pure nothrow @safe @nogc @live
	bool empty()

		do
		{
			return (this.key == null) || ((this.value = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(this.key))) == null);
		}
}

private struct json_object_foreach_safe_internal1
{
private:
	.json_t** object_ = void;
	void** n = void;
	const (char)** key = void;
	.json_t** value = void;

public:
	pure nothrow @trusted @nogc @live
	this(ref .json_t* object_, ref void* n, ref const (char)* key, ref .json_t* value)

		do
		{
			key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_));
			n = jansson.value.json_object_iter_next(object_, jansson.value.json_object_key_to_iter(key));
			this.object_ = &object_;
			this.n = &n;
			this.key = &key;
			this.value = &value;
		}

	pure nothrow @safe @nogc @live
	int front() scope

		do
		{
			//dummy
			return 0;
		}

	pure nothrow @safe @nogc @live
	void popFront()

		do
		{
			*(this.key) = jansson.value.json_object_iter_key(*(this.n));
			*(this.n) = jansson.value.json_object_iter_next(*(this.object_), jansson.value.json_object_key_to_iter(*(this.key)));
		}

	pure nothrow @safe @nogc @live
	bool empty()

		do
		{
			return (*(this.key) == null) || ((*(this.value) = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(*(this.key)))) == null);
		}
}

private struct json_object_foreach_safe_internal2
{
private:
	.json_t* object_ = void;
	void* n = void;
	const (char)* key = void;
	.json_t* value = void;

public:
	pure nothrow @safe @nogc @live
	this(.json_t* object_)

		do
		{
			this.object_ = object_;
			this.key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_));
			this.n = jansson.value.json_object_iter_next(object_, jansson.value.json_object_key_to_iter(this.key));
		}

	pure nothrow @safe @nogc @live
	.json_object_foreach_safe_return front()

		do
		{
			.json_object_foreach_safe_return result;

			result.n = this.n;
			result.key = this.key;
			result.value = this.value;

			return result;
		}

	pure nothrow @safe @nogc @live
	void popFront()

		do
		{
			this.key = jansson.value.json_object_iter_key(this.n);
			this.n = jansson.value.json_object_iter_next(this.object_, jansson.value.json_object_key_to_iter(this.key));
		}

	pure nothrow @safe @nogc @live
	bool empty()

		do
		{
			return (this.key == null) || ((this.value = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(this.key))) == null);
		}
}

private struct json_object_keylen_foreach_safe_internal1
{
private:
	.json_t** object_ = void;
	void** n = void;
	const (char)** key = void;
	size_t* key_len;
	.json_t** value = void;

public:
	pure nothrow @trusted @nogc @live
	this(ref .json_t* object_, ref void* n, ref const (char)* key, ref size_t key_len, ref .json_t* value)

		do
		{
			key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_));
			n = jansson.value.json_object_iter_next(object_, jansson.value.json_object_key_to_iter(key));
			key_len = jansson.value.json_object_iter_key_len(jansson.value.json_object_key_to_iter(key));
			this.object_ = &object_;
			this.n = &n;
			this.key = &key;
			this.key_len = &key_len;
			this.value = &value;
		}

	pure nothrow @safe @nogc @live
	int front() scope

		do
		{
			//dummy
			return 0;
		}

	pure nothrow @safe @nogc @live
	void popFront()

		do
		{
			*(this.key) = jansson.value.json_object_iter_key(*(this.n));
			*(this.key_len) = jansson.value.json_object_iter_key_len(*(this.n));
			*(this.n) = jansson.value.json_object_iter_next(*(this.object_), jansson.value.json_object_key_to_iter(*(this.key)));
		}

	pure nothrow @safe @nogc @live
	bool empty()

		do
		{
			return (*(this.key) == null) || ((*(this.value) = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(*(this.key)))) == null);
		}
}

private struct json_object_keylen_foreach_safe_internal2
{
private:
	.json_t* object_ = void;
	void* n = void;
	const (char)* key = void;
	size_t key_len;
	.json_t* value = void;

public:
	pure nothrow @safe @nogc @live
	this(.json_t* object_)

		do
		{
			this.object_ = object_;
			this.key = jansson.value.json_object_iter_key(jansson.value.json_object_iter(object_));
			this.n = jansson.value.json_object_iter_next(object_, jansson.value.json_object_key_to_iter(this.key));
			this.key_len = jansson.value.json_object_iter_key_len(jansson.value.json_object_key_to_iter(this.key));
		}

	pure nothrow @safe @nogc @live
	.json_object_keylen_foreach_safe_return front()

		do
		{
			.json_object_keylen_foreach_safe_return result;

			result.n = this.n;
			result.key = this.key;
			result.key_len = this.key_len;
			result.value = this.value;

			return result;
		}

	pure nothrow @safe @nogc @live
	void popFront()

		do
		{
			this.key = jansson.value.json_object_iter_key(this.n);
			this.key_len = jansson.value.json_object_iter_key_len(this.n);
			this.n = jansson.value.json_object_iter_next(this.object_, jansson.value.json_object_key_to_iter(this.key));
		}

	pure nothrow @safe @nogc @live
	bool empty()

		do
		{
			return (this.key == null) || ((this.value = jansson.value.json_object_iter_value(jansson.value.json_object_key_to_iter(this.key))) == null);
		}
}

private struct json_array_foreach_internal1
{
private:
	const .json_t** array = void;
	size_t* index = void;
	.json_t** value = void;

public:
	pure nothrow @trusted @nogc @live
	this(const ref .json_t* array, ref size_t index, ref .json_t* value)

		do
		{
			this.array = &array;
			this.index = &index;
			*(this.index) = 0;
			this.value = &value;
		}

	pure nothrow @safe @nogc @live
	int front() scope

		do
		{
			//dummy
			return 0;
		}

	pure nothrow @safe @nogc @live
	void popFront()

		do
		{
			*(this.index) += 1;
		}

	pure nothrow @safe @nogc @live
	bool empty()

		do
		{
			return (*(this.index) >= jansson.value.json_array_size(*(this.array))) || ((*(this.value) = jansson.value.json_array_get(*(this.array), *(this.index))) == null);
		}
}

private struct json_array_foreach_internal2
{
private:
	const .json_t* array = void;
	size_t index = void;
	.json_t* value = void;

public:
	pure nothrow @safe @nogc @live
	this(const .json_t* array)

		do
		{
			this.array = array;
			this.index = 0;
		}

	pure nothrow @safe @nogc @live
	.json_array_return front()

		do
		{
			.json_array_return result;

			result.index = this.index;
			result.value = this.value;

			return result;
		}

	pure nothrow @safe @nogc @live
	void popFront()

		do
		{
			++this.index;
		}

	pure nothrow @safe @nogc @live
	bool empty()

		do
		{
			return (this.index >= jansson.value.json_array_size(this.array)) || ((this.value = jansson.value.json_array_get(this.array, this.index)) == null);
		}
}

/**
 * foreach function
 */
pragma(inline, true)
pure nothrow @trusted @nogc @live
public auto json_object_foreach(.json_t* object_)

	do
	{
		return .json_object_foreach_internal2(object_);
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public auto json_object_keylen_foreach(.json_t* object_)

	do
	{
		return .json_object_keylen_foreach_internal2(object_);
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public auto json_object_foreach_safe(.json_t* object_)

	do
	{
		return .json_object_foreach_safe_internal2(object_);
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public auto json_object_keylen_foreach_safe(.json_t* object_)

	do
	{
		return .json_object_keylen_foreach_safe_internal2(object_);
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public auto json_array_foreach(.json_t* array)

	do
	{
		return .json_array_foreach_internal2(array);
	}

/**
 * foreach function compatible with the original macro
 */
pragma(inline, true)
pure nothrow @trusted @nogc @live
public auto json_object_foreach(ref .json_t* object_, ref const (char)* key, ref .json_t* value)

	do
	{
		return .json_object_foreach_internal1(object_, key, value);
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public auto json_object_keylen_foreach(ref .json_t* object_, ref const (char)* key, ref size_t key_len, ref .json_t* value)

	do
	{
		return .json_object_keylen_foreach_internal1(object_, key, key_len, value);
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public auto json_object_foreach_safe(ref .json_t* object_, ref void* n, ref const (char)* key, ref .json_t* value)

	do
	{
		return .json_object_foreach_safe_internal1(object_, n, key, value);
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public auto json_object_keylen_foreach_safe(ref .json_t* object_, ref void* n, ref const (char)* key, ref size_t key_len, ref .json_t* value)

	do
	{
		return .json_object_keylen_foreach_safe_internal1(object_, n, key, key_len, value);
	}

///Ditto
pragma(inline, true)
pure nothrow @trusted @nogc @live
public auto json_array_foreach(const ref .json_t* array, ref size_t index, ref .json_t* value)

	do
	{
		return .json_array_foreach_internal1(array, index, value);
	}

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_object_set(scope .json_t* object_, scope const char* key, scope .json_t* value)

	do
	{
		return jansson.value.json_object_set_new(object_, key, .json_incref(value));
	}

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_object_setn(scope .json_t* object_, scope const char* key, size_t key_len, scope .json_t* value)

	do
	{
		return jansson.value.json_object_setn_new(object_, key, key_len, .json_incref(value));
	}

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_object_set_nocheck(scope .json_t* object_, scope const char* key, scope .json_t* value)

	do
	{
		return jansson.value.json_object_set_new_nocheck(object_, key, .json_incref(value));
	}

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_object_setn_nocheck(scope .json_t* object_, scope const char* key, size_t key_len, scope .json_t* value)

	do
	{
		return jansson.value.json_object_setn_new_nocheck(object_, key, key_len, .json_incref(value));
	}

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_object_iter_set(scope .json_t* object_, scope void* iter, scope .json_t* value)

	do
	{
		return jansson.value.json_object_iter_set_new(object_, iter, .json_incref(value));
	}

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_object_update_new(scope .json_t* object_, scope .json_t* other)

	do
	{
		int ret = jansson.value.json_object_update(object_, other);
		.json_decref(other);

		return ret;
	}

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_object_update_existing_new(scope .json_t* object_, scope .json_t* other)

	do
	{
		int ret = jansson.value.json_object_update_existing(object_, other);
		.json_decref(other);

		return ret;
	}

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_object_update_missing_new(scope .json_t* object_, scope .json_t* other)

	do
	{
		int ret = jansson.value.json_object_update_missing(object_, other);
		.json_decref(other);

		return ret;
	}

///
public alias json_array_size = jansson.value.json_array_size;

///
public alias json_array_get = jansson.value.json_array_get;

///
public alias json_array_set_new = jansson.value.json_array_set_new;

///
public alias json_array_append_new = jansson.value.json_array_append_new;

///
public alias json_array_insert_new = jansson.value.json_array_insert_new;

///
public alias json_array_remove = jansson.value.json_array_remove;

///
public alias json_array_clear = jansson.value.json_array_clear;

///
public alias json_array_extend = jansson.value.json_array_extend;

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_array_set(scope .json_t* array, size_t ind, scope .json_t* value)

	do
	{
		return jansson.value.json_array_set_new(array, ind, .json_incref(value));
	}

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_array_append(scope .json_t* array, scope .json_t* value)

	do
	{
		return jansson.value.json_array_append_new(array, .json_incref(value));
	}

///
pragma(inline, true)
@JSON_INLINE
nothrow @trusted @nogc
public int json_array_insert(scope .json_t* array, size_t ind, scope .json_t* value)

	do
	{
		return jansson.value.json_array_insert_new(array, ind, .json_incref(value));
	}

///
public alias json_string_value = jansson.value.json_string_value;

///
public alias json_string_length = jansson.value.json_string_length;

///
public alias json_integer_value = jansson.value.json_integer_value;

///
public alias json_real_value = jansson.value.json_real_value;

///
public alias json_number_value = jansson.value.json_number_value;

///
public alias json_string_set = jansson.value.json_string_set;

///
public alias json_string_setn = jansson.value.json_string_setn;

///
public alias json_string_set_nocheck = jansson.value.json_string_set_nocheck;

///
public alias json_string_setn_nocheck = jansson.value.json_string_setn_nocheck;

///
public alias json_integer_set = jansson.value.json_integer_set;

///
public alias json_real_set = jansson.value.json_real_set;

/* pack, unpack */

///
//.JANSSON_ATTRS((warn_unused_result));
public alias json_pack = jansson.pack_unpack.json_pack;

///
//.JANSSON_ATTRS((warn_unused_result));
public alias json_pack_ex = jansson.pack_unpack.json_pack_ex;

///
//.JANSSON_ATTRS((warn_unused_result));
public alias json_vpack_ex = jansson.pack_unpack.json_vpack_ex;

///
public enum JSON_VALIDATE_ONLY = 0x01;

///
public enum JSON_STRICT = 0x02;

///
public alias json_unpack = jansson.pack_unpack.json_unpack;

///
public alias json_unpack_ex = jansson.pack_unpack.json_unpack_ex;

///
public alias json_vunpack_ex = jansson.pack_unpack.json_vunpack_ex;

/* sprintf */

///
public alias json_sprintf = jansson.value.json_sprintf;

///
public alias json_vsprintf = jansson.value.json_vsprintf;

/* equality */

///
public alias json_equal = jansson.value.json_equal;

/* copying */

///
public alias json_copy = jansson.value.json_copy;

///
public alias json_deep_copy = jansson.value.json_deep_copy;

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
public alias json_loads = jansson.load.json_loads;

///
public alias json_loadb = jansson.load.json_loadb;

///
public alias json_loadf = jansson.load.json_loadf;

///
public alias json_loadfd = jansson.load.json_loadfd;

///
public alias json_load_file = jansson.load.json_load_file;

///
public alias json_load_callback = jansson.load.json_load_callback;

/* encoding */

///
public enum JSON_MAX_INDENT = 0x1F;

///
pragma(inline, true)
pure nothrow @safe @nogc @live
public N JSON_INDENT(N)(N n)

	do
	{
		return mixin (.JSON_INDENT!("n"));
	}

///Ditto
public template JSON_INDENT(string n)
{
	enum JSON_INDENT = "((" ~ n ~ ") & jansson.jansson.JSON_MAX_INDENT)";
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
pragma(inline, true)
pure nothrow @safe @nogc @live
public N JSON_INDENT(N)(N n)
	if (N.max > 0xF800)

	do
	{
		return mixin (.JSON_REAL_PRECISION!("n"));
	}

///Ditto
public template JSON_REAL_PRECISION(string n)
{
	enum JSON_REAL_PRECISION = "(((" ~ n ~ ") & 0x1F) << 11)";
}

///
public enum JSON_EMBED = 0x010000;

///
public alias json_dump_callback_t = extern (C) nothrow @nogc @live int function(scope const char* buffer, size_t size, void* data);

///
public alias json_dumps = jansson.dump.json_dumps;

///
public alias json_dumpb = jansson.dump.json_dumpb;

///
public alias json_dumpf = jansson.dump.json_dumpf;

///
public alias json_dumpfd = jansson.dump.json_dumpfd;

///
public alias json_dump_file = jansson.dump.json_dump_file;

///
public alias json_dump_callback = jansson.dump.json_dump_callback;

/* custom memory allocation */

///
public alias json_malloc_t = extern (C) nothrow @nogc void* function(size_t);

///
public alias json_free_t = extern (C) nothrow @nogc void function(void*);

///
public alias json_set_alloc_funcs = jansson.memory.json_set_alloc_funcs;

///
public alias json_get_alloc_funcs = jansson.memory.json_get_alloc_funcs;

/* runtime version checking */
///
public alias jansson_version_str = jansson.version_.jansson_version_str;

///
public alias jansson_version_cmp = jansson.version_.jansson_version_cmp;
