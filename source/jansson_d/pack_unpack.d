/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 * Copyright (c) 2011-2012 Graeme Smecher <graeme.smecher@mail.mcgill.ca>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.pack_unpack;


package:

private static import core.stdc.config;
private static import core.stdc.stdarg;
private static import core.stdc.string;
private static import jansson_d.hashtable;
private static import jansson_d.jansson;
private static import jansson_d.jansson_private;
private static import jansson_d.strbuffer;
private static import jansson_d.utf;
private static import jansson_d.value;

struct token_t
{
	int line;
	int column;
	size_t pos;
	char token = '\0';
}

struct scanner_t
{
	const (char)* start;
	const (char)* fmt;
	.token_t prev_token;
	.token_t token;
	.token_t next_token;
	jansson_d.jansson.json_error_t* error;
	size_t flags;
	int line;
	int column;
	size_t pos;
	int has_error;
}

private template token(string scanner)
{
	enum token = "((" ~ scanner ~ ").token.token)";
}

private static immutable string[] type_names = ["object\0", "array\0", "string\0", "integer\0", "real\0", "true\0", "false\0", "null\0"];

private template type_name(string x)
{
	enum type_name = "&(.type_names[mixin (jansson_d.jansson.json_typeof!(\"" ~ x ~ "\"))][0])";
}

private static immutable char[] unpack_value_starters = "{[siIbfFOon\0";

pure nothrow @trusted @nogc @live
private void scanner_init(scope scanner_t* s, scope jansson_d.jansson.json_error_t* error, size_t flags, scope const char* fmt)

	in
	{
		assert(s != null);
	}

	do
	{
		s.error = error;
		s.flags = flags;
		s.start = fmt;
		s.fmt = fmt;
		core.stdc.string.memset(&s.prev_token, 0, .token_t.sizeof);
		core.stdc.string.memset(&s.token, 0, .token_t.sizeof);
		core.stdc.string.memset(&s.next_token, 0, .token_t.sizeof);
		s.line = 1;
		s.column = 0;
		s.pos = 0;
		s.has_error = 0;
	}

pure nothrow @trusted @nogc @live
private void next_token(scope .scanner_t* s)

	in
	{
		assert(s != null);
	}

	do
	{
		s.prev_token = s.token;

		if (s.next_token.line) {
			s.token = s.next_token;
			s.next_token.line = 0;

			return;
		}

		if ((!mixin (.token!("s"))) && (*s.fmt == '\0')) {
			return;
		}

		const (char)* t = s.fmt;
		s.column++;
		s.pos++;

		/* skip space and ignored chars */
		while ((*t == ' ') || (*t == '\t') || (*t == '\n') || (*t == ',') || (*t == ':')) {
			if (*t == '\n') {
				s.line++;
				s.column = 1;
			} else {
				s.column++;
			}

			s.pos++;
			t++;
		}

		s.token.token = *t;
		s.token.line = s.line;
		s.token.column = s.column;
		s.token.pos = s.pos;

		if (*t != '\0') {
			t++;
		}

		s.fmt = t;
	}

pure nothrow @trusted @nogc @live
private void prev_token(scope .scanner_t* s)

	in
	{
		assert(s != null);
	}

	do
	{
		s.next_token = s.token;
		s.token = s.prev_token;
	}

nothrow @nogc @live
private void set_error(F ...)(scope .scanner_t* s, scope const char* source, jansson_d.jansson.json_error_code_t code, scope const char* fmt, F f)

	in
	{
		assert(s != null);
	}

	do
	{
		static if (f.length != 0) {
			jansson_d.jansson_private.jsonp_error_vset(s.error, s.token.line, s.token.column, s.token.pos, code, fmt, f[0 .. $]);
		} else {
			jansson_d.jansson_private.jsonp_error_vset(s.error, s.token.line, s.token.column, s.token.pos, code, fmt);
		}

		jansson_d.jansson_private.jsonp_error_set_source(s.error, source);
	}

/*
 * ours will be set to 1 if jsonp_free() must be called for the result
 * afterwards
 */
nothrow @nogc
private char* read_string(scope .scanner_t* s, scope core.stdc.stdarg.va_list* ap, scope const char* purpose, scope size_t* out_len, scope int* ours, int optional)

	in
	{
		assert(s != null);
		assert(out_len != null);
		assert(ours != null);
	}

	do
	{
		.next_token(s);
		char t = mixin (.token!("s"));
		.prev_token(s);

		*ours = 0;

		if ((t != '#') && (t != '%') && (t != '+')) {
			/* Optimize the simple case */
			const char* str = core.stdc.stdarg.va_arg!(const char*)(*ap);

			if (str == null) {
				if (!optional) {
					.set_error(s, "<args>", jansson_d.jansson.json_error_code_t.json_error_null_value, "null %s", purpose);
					s.has_error = 1;
				}

				return null;
			}

			size_t length_ = core.stdc.string.strlen(str);

			if (!jansson_d.utf.utf8_check_string(str, length_)) {
				.set_error(s, "<args>", jansson_d.jansson.json_error_code_t.json_error_invalid_utf8, "Invalid UTF-8 %s", purpose);
				s.has_error = 1;

				return null;
			}

			*out_len = length_;

			return cast(char*)(str);
		} else if (optional) {
			.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Cannot use '%c' on optional strings", t);
			s.has_error = 1;

			return null;
		}

		jansson_d.strbuffer.strbuffer_t strbuff = void;

		if (jansson_d.strbuffer.strbuffer_init(&strbuff)) {
			.set_error(s, "<internal>", jansson_d.jansson.json_error_code_t.json_error_out_of_memory, "Out of memory");
			s.has_error = 1;
		}

		while (true) {
			const char* str = core.stdc.stdarg.va_arg!(const char*)(*ap);

			if (str == null) {
				.set_error(s, "<args>", jansson_d.jansson.json_error_code_t.json_error_null_value, "null %s", purpose);
				s.has_error = 1;
			}

			.next_token(s);

			size_t length_ = void;

			if (mixin (.token!("s")) == '#') {
				length_ = core.stdc.stdarg.va_arg!(int)(*ap);
			} else if (mixin (.token!("s")) == '%') {
				length_ = core.stdc.stdarg.va_arg!(size_t)(*ap);
			} else {
				.prev_token(s);
				length_ = (s.has_error) ? (0) : (core.stdc.string.strlen(str));
			}

			if ((!s.has_error) && (jansson_d.strbuffer.strbuffer_append_bytes(&strbuff, str, length_) == -1)) {
				.set_error(s, "<internal>", jansson_d.jansson.json_error_code_t.json_error_out_of_memory, "Out of memory");
				s.has_error = 1;
			}

			.next_token(s);

			if (mixin (.token!("s")) != '+') {
				.prev_token(s);

				break;
			}
		}

		if (s.has_error) {
			jansson_d.strbuffer.strbuffer_close(&strbuff);

			return null;
		}

		if (!jansson_d.utf.utf8_check_string(strbuff.value, strbuff.length_)) {
			.set_error(s, "<args>", jansson_d.jansson.json_error_code_t.json_error_invalid_utf8, "Invalid UTF-8 %s", purpose);
			jansson_d.strbuffer.strbuffer_close(&strbuff);
			s.has_error = 1;

			return null;
		}

		*out_len = strbuff.length_;
		*ours = 1;

		return jansson_d.strbuffer.strbuffer_steal_value(&strbuff);
	}

nothrow @nogc
private jansson_d.jansson.json_t* pack_object(scope .scanner_t* s, scope core.stdc.stdarg.va_list* ap)

	do
	{
		jansson_d.jansson.json_t* object = jansson_d.value.json_object();
		.next_token(s);

		while (mixin (.token!("s")) != '}') {
			if (!mixin (.token!("s"))) {
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Unexpected end of format string");

				goto error_;
			}

			if (mixin (.token!("s")) != 's') {
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Expected format 's', got '%c'", mixin (.token!("s")));

				goto error_;
			}

			size_t len = void;
			int ours = void;
			char* key = .read_string(s, ap, "object key", &len, &ours, 0);

			.next_token(s);

			.next_token(s);
			char valueOptional = mixin (.token!("s"));
			.prev_token(s);

			jansson_d.jansson.json_t* value = .pack(s, ap);

			if (value == null) {
				if (ours) {
					jansson_d.jansson_private.jsonp_free(key);
				}

				if (valueOptional != '*') {
					.set_error(s, "<args>", jansson_d.jansson.json_error_code_t.json_error_null_value, "null object value");
					s.has_error = 1;
				}

				.next_token(s);

				continue;
			}

			if (s.has_error) {
				jansson_d.jansson.json_decref(value);
			}

			if ((!s.has_error) && (jansson_d.value.json_object_set_new_nocheck(object, key, value))) {
				.set_error(s, "<internal>", jansson_d.jansson.json_error_code_t.json_error_out_of_memory, "Unable to add key \"%s\"", key);
				s.has_error = 1;
			}

			if (ours) {
				jansson_d.jansson_private.jsonp_free(key);
			}

			.next_token(s);
		}

		if (!s.has_error) {
			return object;
		}

	error_:
		jansson_d.jansson.json_decref(object);

		return null;
	}

nothrow @nogc
private jansson_d.jansson.json_t* pack_array(scope .scanner_t* s, scope core.stdc.stdarg.va_list* ap)

	do
	{
		jansson_d.jansson.json_t* array = jansson_d.value.json_array();
		.next_token(s);

		while (mixin (.token!("s")) != ']') {
			if (!mixin (.token!("s"))) {
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Unexpected end of format string");
				/* Format string errors are unrecoverable. */
				goto error_;
			}

			.next_token(s);
			char valueOptional = mixin (.token!("s"));
			.prev_token(s);

			jansson_d.jansson.json_t* value = .pack(s, ap);

			if (value == null) {
				if (valueOptional != '*') {
					s.has_error = 1;
				}

				.next_token(s);

				continue;
			}

			if (s.has_error) {
				jansson_d.jansson.json_decref(value);
			}

			if ((!s.has_error) && (jansson_d.value.json_array_append_new(array, value))) {
				.set_error(s, "<internal>", jansson_d.jansson.json_error_code_t.json_error_out_of_memory, "Unable to append to array");
				s.has_error = 1;
			}

			.next_token(s);
		}

		if (!s.has_error) {
			return array;
		}

	error_:
		jansson_d.jansson.json_decref(array);

		return null;
	}

nothrow @nogc
private jansson_d.jansson.json_t* pack_string(scope .scanner_t* s, scope core.stdc.stdarg.va_list* ap)

	do
	{
		.next_token(s);
		char t = mixin (.token!("s"));
		int optional = (t == '?') || (t == '*');

		if (!optional) {
			.prev_token(s);
		}

		size_t len = void;
		int ours = void;
		char* str = .read_string(s, ap, "string", &len, &ours, optional);

		if (str == null) {
			return (t == '?') && (!s.has_error) ? (jansson_d.value.json_null()) : (null);
		}

		if (s.has_error) {
			/* It's impossible to reach this point if ours != 0, do not free str. */
			return null;
		}

		if (ours) {
			return jansson_d.jansson_private.jsonp_stringn_nocheck_own(str, len);
		}

		return jansson_d.value.json_stringn_nocheck(str, len);
	}

nothrow @nogc @live
private jansson_d.jansson.json_t* pack_object_inter(scope .scanner_t* s, scope core.stdc.stdarg.va_list* ap, int need_incref)

	do
	{
		.next_token(s);
		char ntoken = mixin (.token!("s"));

		if ((ntoken != '?') && (ntoken != '*')) {
			.prev_token(s);
		}

		jansson_d.jansson.json_t* json = core.stdc.stdarg.va_arg!(jansson_d.jansson.json_t*)(*ap);

		if (json != null) {
			return (need_incref) ? (jansson_d.jansson.json_incref(json)) : (json);
		}

		switch (ntoken) {
			case '?':
				return jansson_d.value.json_null();

			case '*':
				return null;

			default:
				break;
		}

		.set_error(s, "<args>", jansson_d.jansson.json_error_code_t.json_error_null_value, "null object");
		s.has_error = 1;

		return null;
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* pack_integer(scope .scanner_t* s, jansson_d.jansson.json_int_t value)

	do
	{
		jansson_d.jansson.json_t* json = jansson_d.value.json_integer(value);

		if (json == null) {
			.set_error(s, "<internal>", jansson_d.jansson.json_error_code_t.json_error_out_of_memory, "Out of memory");
			s.has_error = 1;
		}

		return json;
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* pack_real(scope .scanner_t* s, double value)

	in
	{
		assert(s != null);
	}

	do
	{
		/* Allocate without setting value so we can identify OOM error. */
		jansson_d.jansson.json_t* json = jansson_d.value.json_real(0.0);

		if (json == null) {
			.set_error(s, "<internal>", jansson_d.jansson.json_error_code_t.json_error_out_of_memory, "Out of memory");
			s.has_error = 1;

			return null;
		}

		if (jansson_d.value.json_real_set(json, value)) {
			jansson_d.jansson.json_decref(json);

			.set_error(s, "<args>", jansson_d.jansson.json_error_code_t.json_error_numeric_overflow, "Invalid floating point value");
			s.has_error = 1;

			return null;
		}

		return json;
	}

nothrow @nogc
private jansson_d.jansson.json_t* pack(scope .scanner_t* s, scope core.stdc.stdarg.va_list* ap)

	in
	{
		assert(s != null);
	}

	do
	{
		switch (mixin (.token!("s"))) {
			case '{':
				return .pack_object(s, ap);

			case '[':
				return .pack_array(s, ap);

			/* string */
			case 's':
				return .pack_string(s, ap);

			/* null */
			case 'n':
				return jansson_d.value.json_null();

			/* boolean */
			case 'b':
				return (core.stdc.stdarg.va_arg!(int)(*ap)) ? (jansson_d.value.json_true()) : (jansson_d.value.json_false());

			/* integer from int */
			case 'i':
				return .pack_integer(s, core.stdc.stdarg.va_arg!(int)(*ap));

			/* integer from json_int_t */
			case 'I':
				return .pack_integer(s, core.stdc.stdarg.va_arg!(jansson_d.jansson.json_int_t)(*ap));

			/* real */
			case 'f':
				return .pack_real(s, core.stdc.stdarg.va_arg!(double)(*ap));

			/* a json_t object; increments refcount */
			case 'O':
				return .pack_object_inter(s, ap, 1);

			/* a json_t object; doesn't increment refcount */
			case 'o':
				return .pack_object_inter(s, ap, 0);

			default:
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '%c'", mixin (.token!("s")));
				s.has_error = 1;

				return null;
		}
	}

nothrow @nogc
private int unpack_object(scope .scanner_t* s, scope jansson_d.jansson.json_t* root, scope core.stdc.stdarg.va_list* ap)

	do
	{
		int ret = -1;
		int strict = 0;
		bool gotopt = false;

		/*
		 * Use a set (emulated by a hashtable) to check that all object
		 *    keys are accessed. Checking that the correct number of keys
		 *    were accessed is not enough, as the same key can be unpacked
		 *    multiple times.
		 */
		jansson_d.hashtable.hashtable_t key_set = void;

		if (jansson_d.hashtable.hashtable_init(&key_set)) {
			.set_error(s, "<internal>", jansson_d.jansson.json_error_code_t.json_error_out_of_memory, "Out of memory");

			return -1;
		}

		if ((root != null) && (!mixin (jansson_d.jansson.json_is_object!("root")))) {
			.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_wrong_type, "Expected object, got %s", mixin (.type_name!("root")));

			goto out_;
		}

		.next_token(s);

		while (mixin (.token!("s")) != '}') {
			bool opt = false;

			if (strict != 0) {
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Expected '}' after '%c', got '%c'", (strict == 1) ? ('!') : ('*'), mixin (.token!("s")));

				goto out_;
			}

			if (!mixin (.token!("s"))) {
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Unexpected end of format string");

				goto out_;
			}

			if ((mixin (.token!("s")) == '!') || (mixin (.token!("s")) == '*')) {
				strict = (mixin (.token!("s")) == '!') ? (1) : (-1);
				.next_token(s);

				continue;
			}

			if (mixin (.token!("s")) != 's') {
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Expected format 's', got '%c'", mixin (.token!("s")));

				goto out_;
			}

			const char* key = core.stdc.stdarg.va_arg!(const char*)(*ap);

			if (key == null) {
				.set_error(s, "<args>", jansson_d.jansson.json_error_code_t.json_error_null_value, "null object key");

				goto out_;
			}

			.next_token(s);

			if (mixin (.token!("s")) == '?') {
				gotopt = true;
				opt = true;
				.next_token(s);
			}

			jansson_d.jansson.json_t* value = void;

			if (root == null) {
				/* skipping */
				value = null;
			} else {
				value = jansson_d.value.json_object_get(root, key);

				if ((value == null) && (!opt)) {
					.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_item_not_found, "Object item not found: %s", key);

					goto out_;
				}
			}

			if (.unpack(s, value, ap)) {
				goto out_;
			}

			jansson_d.hashtable.hashtable_set(&key_set, key, core.stdc.string.strlen(key), jansson_d.value.json_null());
			.next_token(s);
		}

		if ((strict == 0) && (s.flags & jansson_d.jansson.JSON_STRICT)) {
			strict = 1;
		}

		if ((root != null) && (strict == 1)) {
			/* We need to check that all non optional items have been parsed */

			/* keys_res is 1 for uninitialized, 0 for success, -1 for error. */
			int keys_res = 1;

			jansson_d.strbuffer.strbuffer_t unrecognized_keys = void;
			jansson_d.jansson.json_t* value = void;
			core.stdc.config.c_long unpacked = 0;

			if ((gotopt) || (jansson_d.value.json_object_size(root) != key_set.size)) {
				const (char)* key = void;
				size_t key_len = void;

				//jansson_d.jansson.json_object_keylen_foreach(root, key, key_len, value)
				for (key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter(root)), key_len = jansson_d.value.json_object_iter_key_len(jansson_d.value.json_object_key_to_iter(key)); (key != null) && ((value = jansson_d.value.json_object_iter_value(jansson_d.value.json_object_key_to_iter(key))) != null); key = jansson_d.value.json_object_iter_key(jansson_d.value.json_object_iter_next(root, jansson_d.value.json_object_key_to_iter(key))), key_len = jansson_d.value.json_object_iter_key_len(jansson_d.value.json_object_key_to_iter(key))) {
					if (jansson_d.hashtable.hashtable_get(&key_set, key, key_len) == null) {
						unpacked++;

						/* Save unrecognized keys for the error message */
						if (keys_res == 1) {
							keys_res = jansson_d.strbuffer.strbuffer_init(&unrecognized_keys);
						} else if (!keys_res) {
							keys_res = jansson_d.strbuffer.strbuffer_append_bytes(&unrecognized_keys, ", ", 2);
						}

						if (!keys_res) {
							keys_res = jansson_d.strbuffer.strbuffer_append_bytes(&unrecognized_keys, key, key_len);
						}
					}
				}
			}

			if (unpacked) {
				.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_end_of_input_expected, "%li object item(s) left unpacked: %s", unpacked, (keys_res) ? (&("<unknown>\0"[0])) : (jansson_d.strbuffer.strbuffer_value(&unrecognized_keys)));
				jansson_d.strbuffer.strbuffer_close(&unrecognized_keys);

				goto out_;
			}
		}

		ret = 0;

	out_:
		jansson_d.hashtable.hashtable_close(&key_set);

		return ret;
	}

nothrow @nogc
private int unpack_array(scope .scanner_t* s, scope jansson_d.jansson.json_t* root, scope core.stdc.stdarg.va_list* ap)

	do
	{
		size_t i = 0;
		int strict = 0;

		if ((root != null) && (!mixin (jansson_d.jansson.json_is_array!("root")))) {
			.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_wrong_type, "Expected array, got %s", mixin (.type_name!("root")));

			return -1;
		}

		.next_token(s);

		while (mixin (.token!("s")) != ']') {
			if (strict != 0) {
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Expected ']' after '%c', got '%c'", (strict == 1) ? ('!') : ('*'), mixin (.token!("s")));

				return -1;
			}

			if (!mixin (.token!("s"))) {
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Unexpected end of format string");

				return -1;
			}

			if ((mixin (.token!("s")) == '!') || (mixin (.token!("s")) == '*')) {
				strict = (mixin (.token!("s")) == '!') ? (1) : (-1);
				.next_token(s);

				continue;
			}

			if (!core.stdc.string.strchr(&(.unpack_value_starters[0]), mixin (.token!("s")))) {
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '%c'", mixin (.token!("s")));

				return -1;
			}

			jansson_d.jansson.json_t* value = void;

			if (root == null) {
				/* skipping */
				value = null;
			} else {
				value = jansson_d.value.json_array_get(root, i);

				if (value == null) {
					.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_index_out_of_range, "Array index %lu out of range", cast(core.stdc.config.c_ulong)(i));

					return -1;
				}
			}

			if (.unpack(s, value, ap)) {
				return -1;
			}

			.next_token(s);
			i++;
		}

		if ((strict == 0) && (s.flags & jansson_d.jansson.JSON_STRICT)) {
			strict = 1;
		}

		if ((root != null) && (strict == 1) && (i != jansson_d.value.json_array_size(root))) {
			core.stdc.config.c_long diff = cast(core.stdc.config.c_long)(jansson_d.value.json_array_size(root)) - cast(core.stdc.config.c_long)(i);
			.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_end_of_input_expected, "%li array item(s) left unpacked", diff);

			return -1;
		}

		return 0;
	}

nothrow @nogc
private int unpack(scope .scanner_t* s, scope jansson_d.jansson.json_t* root, scope core.stdc.stdarg.va_list* ap)

	in
	{
		assert(s != null);
	}

	do
	{
		switch (mixin (.token!("s"))) {
			case '{':
				return .unpack_object(s, root, ap);

			case '[':
				return .unpack_array(s, root, ap);

			case 's':
				if ((root != null) && (!mixin (jansson_d.jansson.json_is_string!("root")))) {
					.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_wrong_type, "Expected string, got %s", mixin (.type_name!("root")));

					return -1;
				}

				if (!(s.flags & jansson_d.jansson.JSON_VALIDATE_ONLY)) {
					size_t* len_target = null;

					const (char)** str_target = core.stdc.stdarg.va_arg!(const (char)**)(*ap);

					if (str_target == null) {
						.set_error(s, "<args>", jansson_d.jansson.json_error_code_t.json_error_null_value, "null string argument");

						return -1;
					}

					.next_token(s);

					if (mixin (.token!("s")) == '%') {
						len_target = core.stdc.stdarg.va_arg!(size_t*)(*ap);

						if (len_target == null) {
							.set_error(s, "<args>", jansson_d.jansson.json_error_code_t.json_error_null_value, "null string length argument");

							return -1;
						}
					} else {
						.prev_token(s);
					}

					if (root != null) {
						*str_target = jansson_d.value.json_string_value(root);

						if (len_target != null) {
							*len_target = jansson_d.value.json_string_length(root);
						}
					}
				}

				return 0;

			case 'i':
				if ((root != null) && (!mixin (jansson_d.jansson.json_is_integer!("root")))) {
					.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_wrong_type, "Expected integer, got %s", mixin (.type_name!("root")));

					return -1;
				}

				if (!(s.flags & jansson_d.jansson.JSON_VALIDATE_ONLY)) {
					int* target = core.stdc.stdarg.va_arg!(int*)(*ap);

					if (root != null) {
						*target = cast(int)(jansson_d.value.json_integer_value(root));
					}
				}

				return 0;

			case 'I':
				if ((root != null) && (!mixin (jansson_d.jansson.json_is_integer!("root")))) {
					.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_wrong_type, "Expected integer, got %s", mixin (.type_name!("root")));

					return -1;
				}

				if (!(s.flags & jansson_d.jansson.JSON_VALIDATE_ONLY)) {
					jansson_d.jansson.json_int_t* target = core.stdc.stdarg.va_arg!(jansson_d.jansson.json_int_t*)(*ap);

					if (root != null) {
						*target = jansson_d.value.json_integer_value(root);
					}
				}

				return 0;

			case 'b':
				if ((root != null) && (!mixin (jansson_d.jansson.json_is_boolean!("root")))) {
					.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_wrong_type, "Expected true or false, got %s", mixin (.type_name!("root")));

					return -1;
				}

				if (!(s.flags & jansson_d.jansson.JSON_VALIDATE_ONLY)) {
					int* target = core.stdc.stdarg.va_arg!(int*)(*ap);

					if (root != null) {
						*target = mixin (jansson_d.jansson.json_is_true!("root"));
					}
				}

				return 0;

			case 'f':
				if ((root != null) && (!mixin (jansson_d.jansson.json_is_real!("root")))) {
					.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_wrong_type, "Expected real, got %s", mixin (.type_name!("root")));

					return -1;
				}

				if (!(s.flags & jansson_d.jansson.JSON_VALIDATE_ONLY)) {
					double* target = core.stdc.stdarg.va_arg!(double*)(*ap);

					if (root != null) {
						*target = jansson_d.value.json_real_value(root);
					}
				}

				return 0;

			case 'F':
				if ((root != null) && (!mixin (jansson_d.jansson.json_is_number!("root")))) {
					.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_wrong_type, "Expected real or integer, got %s", mixin (.type_name!("root")));

					return -1;
				}

				if (!(s.flags & jansson_d.jansson.JSON_VALIDATE_ONLY)) {
					double* target = core.stdc.stdarg.va_arg!(double*)(*ap);

					if (root != null) {
						*target = jansson_d.value.json_number_value(root);
					}
				}

				return 0;

			case 'O':
				if ((root != null) && (!(s.flags & jansson_d.jansson.JSON_VALIDATE_ONLY))) {
					jansson_d.jansson.json_incref(root);
				}

				/* Fall through */
				goto case;

			case 'o':
				if (!(s.flags & jansson_d.jansson.JSON_VALIDATE_ONLY)) {
					jansson_d.jansson.json_t** target = core.stdc.stdarg.va_arg!(jansson_d.jansson.json_t**)(*ap);

					if (root != null) {
						*target = root;
					}
				}

				return 0;

			case 'n':
				/* Never assign, just validate */
				if ((root != null) && (!mixin (jansson_d.jansson.json_is_null!("root")))) {
					.set_error(s, "<validation>", jansson_d.jansson.json_error_code_t.json_error_wrong_type, "Expected null, got %s", mixin (.type_name!("root")));

					return -1;
				}

				return 0;

			default:
				.set_error(s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Unexpected format character '%c'", mixin (.token!("s")));

				return -1;
		}
	}

///
//nodiscard
extern (C)
nothrow @nogc
public jansson_d.jansson.json_t* json_vpack_ex(scope jansson_d.jansson.json_error_t* error, size_t flags, scope const char* fmt, core.stdc.stdarg.va_list ap)

	do
	{
		if ((fmt == null) || (*fmt == '\0')) {
			jansson_d.jansson_private.jsonp_error_init(error, "<format>");
			jansson_d.jansson_private.jsonp_error_set(error, -1, -1, 0, jansson_d.jansson.json_error_code_t.json_error_invalid_argument, "null or empty format string");

			return null;
		}

		jansson_d.jansson_private.jsonp_error_init(error, null);

		.scanner_t s = void;
		.scanner_init(&s, error, flags, fmt);
		.next_token(&s);

		core.stdc.stdarg.va_list ap_copy;
		jansson_d.jansson_private.va_copy(ap_copy, ap);
		jansson_d.jansson.json_t* value = .pack(&s, &ap_copy);
		core.stdc.stdarg.va_end(ap_copy);

		/* This will cover all situations where s.has_error is true */
		if (value == null) {
			return null;
		}

		.next_token(&s);

		if (mixin (.token!("&s"))) {
			jansson_d.jansson.json_decref(value);
			.set_error(&s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Garbage after format string");

			return null;
		}

		return value;
	}

///
//nodiscard
extern (C)
nothrow @nogc
public jansson_d.jansson.json_t* json_pack_ex(scope jansson_d.jansson.json_error_t* error, size_t flags, scope const char* fmt, ...)

	do
	{
		core.stdc.stdarg.va_list ap;
		core.stdc.stdarg.va_start(ap, fmt);
		jansson_d.jansson.json_t* value = .json_vpack_ex(error, flags, fmt, ap);
		core.stdc.stdarg.va_end(ap);

		return value;
	}

///
//nodiscard
extern (C)
nothrow @nogc
public jansson_d.jansson.json_t* json_pack(scope const char* fmt, ...)

	do
	{
		core.stdc.stdarg.va_list ap;
		core.stdc.stdarg.va_start(ap, fmt);
		jansson_d.jansson.json_t* value = .json_vpack_ex(null, 0, fmt, ap);
		core.stdc.stdarg.va_end(ap);

		return value;
	}

///
extern (C)
nothrow @nogc
public int json_vunpack_ex(scope jansson_d.jansson.json_t* root, scope jansson_d.jansson.json_error_t* error, size_t flags, scope const char* fmt, core.stdc.stdarg.va_list ap)

	do
	{
		if (root == null) {
			jansson_d.jansson_private.jsonp_error_init(error, "<root>");
			jansson_d.jansson_private.jsonp_error_set(error, -1, -1, 0, jansson_d.jansson.json_error_code_t.json_error_null_value, "null root value");

			return -1;
		}

		if ((fmt == null) || (*fmt == '\0')) {
			jansson_d.jansson_private.jsonp_error_init(error, "<format>");
			jansson_d.jansson_private.jsonp_error_set(error, -1, -1, 0, jansson_d.jansson.json_error_code_t.json_error_invalid_argument, "null or empty format string");

			return -1;
		}

		jansson_d.jansson_private.jsonp_error_init(error, null);

		.scanner_t s = void;
		.scanner_init(&s, error, flags, fmt);
		.next_token(&s);

		core.stdc.stdarg.va_list ap_copy;
		jansson_d.jansson_private.va_copy(ap_copy, ap);

		if (.unpack(&s, root, &ap_copy)) {
			core.stdc.stdarg.va_end(ap_copy);

			return -1;
		}

		core.stdc.stdarg.va_end(ap_copy);

		.next_token(&s);

		if (mixin (.token!("&s"))) {
			.set_error(&s, "<format>", jansson_d.jansson.json_error_code_t.json_error_invalid_format, "Garbage after format string");

			return -1;
		}

		return 0;
	}

///
extern (C)
nothrow @nogc
public int json_unpack_ex(scope jansson_d.jansson.json_t* root, scope jansson_d.jansson.json_error_t* error, size_t flags, scope const char* fmt, ...)

	do
	{
		core.stdc.stdarg.va_list ap;
		core.stdc.stdarg.va_start(ap, fmt);
		int ret = .json_vunpack_ex(root, error, flags, fmt, ap);
		core.stdc.stdarg.va_end(ap);

		return ret;
	}

///
extern (C)
nothrow @nogc
public int json_unpack(scope jansson_d.jansson.json_t* root, scope const char* fmt, ...)

	do
	{
		core.stdc.stdarg.va_list ap;
		core.stdc.stdarg.va_start(ap, fmt);
		int ret = .json_vunpack_ex(root, null, 0, fmt, ap);
		core.stdc.stdarg.va_end(ap);

		return ret;
	}
