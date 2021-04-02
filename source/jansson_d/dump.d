/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.dump;


package:

private static import core.stdc.stdio;
private static import core.stdc.stdlib;
private static import core.stdc.string;
private static import core.sys.posix.sys.types;
private static import core.sys.posix.unistd;
private static import jansson_d.hashtable;
private static import jansson_d.jansson;
private static import jansson_d.jansson_private;
private static import jansson_d.strbuffer;
private static import jansson_d.utf;
private static import jansson_d.value;

enum MAX_INTEGER_STR_LENGTH = 100;
enum MAX_REAL_STR_LENGTH = 100;

private template FLAGS_TO_INDENT(string f)
{
	enum FLAGS_TO_INDENT = "(" ~ f ~ " &0x1F)";
}

private template FLAGS_TO_PRECISION(string f)
{
	enum FLAGS_TO_PRECISION = "((" ~ f ~ " >> 11) & 0x1F)";
}

private struct buffer_
{
	const size_t size;
	size_t used;
	char* data;
}

extern (C)
nothrow @trusted @nogc
private int dump_to_strbuffer(scope const char* buffer, size_t size, scope void* data)

	do
	{
		return jansson_d.strbuffer.strbuffer_append_bytes(cast(jansson_d.strbuffer.strbuffer_t*)(data), buffer, size);
	}

extern (C)
pure nothrow @trusted @nogc @live
private int dump_to_buffer(scope const char* buffer, size_t size, scope void* data)

	in
	{
		assert(buffer != null);
		assert(data != null);
	}

	do
	{
		.buffer_* buf = cast(.buffer_*)(data);

		if ((buf.used + size) <= buf.size) {
			core.stdc.string.memcpy(&buf.data[buf.used], buffer, size);
		}

		buf.used += size;

		return 0;
	}

extern (C)
nothrow @nogc @live
private int dump_to_file(scope const char* buffer, size_t size, void* data)

	in
	{
		assert(buffer != null);
		assert(data != null);
	}

	do
	{
		core.stdc.stdio.FILE* dest = cast(core.stdc.stdio.FILE*)(data);

		if (core.stdc.stdio.fwrite(buffer, size, 1, dest) != 1) {
			return -1;
		}

		return 0;
	}

extern (C)
nothrow @nogc @live
private int dump_to_fd(scope const char* buffer, size_t size, scope void* data)

	in
	{
		assert(buffer != null);
		assert(data != null);
	}

	do
	{
		static if (__traits(compiles, core.sys.posix.unistd.write)) {
			int* dest = cast(int*)(data);

			if (core.sys.posix.unistd.write(*dest, buffer, size) == cast(core.sys.posix.sys.types.ssize_t)(size)) {
				return 0;
			}
		}

		return -1;
	}

/* 32 spaces (the maximum indentation size) */
private static immutable char[] whitespace = "                                \0";

nothrow @nogc @live
private int dump_indent(size_t flags, int depth, int space, jansson_d.jansson.json_dump_callback_t dump, void* data)

	in
	{
		assert(dump != null);
	}

	do
	{
		if (mixin (.FLAGS_TO_INDENT!("flags")) > 0) {
			uint ws_count = mixin (.FLAGS_TO_INDENT!("flags"));
			uint n_spaces = depth * ws_count;

			if (dump("\n", 1, data)) {
				return -1;
			}

			while (n_spaces > 0) {
				int cur_n = (n_spaces < (.whitespace.length - 1)) ? (n_spaces) : (.whitespace.length - 1);

				if (dump(&(.whitespace[0]), cur_n, data)) {
					return -1;
				}

				n_spaces -= cur_n;
			}
		} else if ((space) && (!(flags & jansson_d.jansson.JSON_COMPACT))) {
			return dump(" ", 1, data);
		}

		return 0;
	}

nothrow @nogc @live
private int dump_string(scope const char* str, size_t len, jansson_d.jansson.json_dump_callback_t dump, void* data, size_t flags)

	in
	{
		assert(str != null);
		assert(dump != null);
	}

	do
	{
		if (dump("\"", 1, data)) {
			return -1;
		}

		const (char)* str_temp = str;
		const (char)* pos = str_temp;
		const (char)* end = str_temp;
		const (char)* lim = str_temp + len;
		int codepoint = 0;

		while (true) {
			while (end < lim) {
				end = jansson_d.utf.utf8_iterate(pos, lim - pos, &codepoint);

				if (end == null) {
					return -1;
				}

				/* mandatory escape or control char */
				if ((codepoint == '\\') || (codepoint == '"') || (codepoint < 0x20)) {
					break;
				}

				/* slash */
				if ((flags & jansson_d.jansson.JSON_ESCAPE_SLASH) && (codepoint == '/')) {
					break;
				}

				/* non-ASCII */
				if ((flags & jansson_d.jansson.JSON_ENSURE_ASCII) && (codepoint > 0x7F)) {
					break;
				}

				pos = end;
			}

			if (pos != str_temp) {
				if (dump(str_temp, pos - str_temp, data)) {
					return -1;
				}
			}

			if (end == pos) {
				break;
			}

			/* handle \, /, ", and control codes */
			int length_ = 2;

			const (char)* text = void;

			switch (codepoint) {
				case '\\':
					text = "\\\\";

					break;

				case '\"':
					text = "\\\"";

					break;

				case '\b':
					text = "\\b";

					break;

				case '\f':
					text = "\\f";

					break;

				case '\n':
					text = "\\n";

					break;

				case '\r':
					text = "\\r";

					break;

				case '\t':
					text = "\\t";

					break;

				case '/':
					text = "\\/";

					break;

				default:
					char[13] seq = void;

					/* codepoint is in BMP */
					if (codepoint < 0x010000) {
						jansson_d.jansson_private.snprintf(&(seq[0]), seq.length, "\\u%04X", cast(uint)(codepoint));
						length_ = 6;
					} else {
						/* not in BMP . construct a UTF-16 surrogate pair */

						codepoint -= 0x010000;
						int first = 0xD800 | ((codepoint & 0x0FFC00) >> 10);
						int last = 0xDC00 | (codepoint & 0x0003FF);

						jansson_d.jansson_private.snprintf(&(seq[0]), seq.length, "\\u%04X\\u%04X", cast(uint)(first), cast(uint)(last));
						length_ = 12;
					}

					text = &(seq[0]);

					break;
			}

			if (dump(text, length_, data)) {
				return -1;
			}

			pos = end;
			str_temp = end;
		}

		return dump("\"", 1, data);
	}

private struct key_len_
{
	const (char)* key;
	int len;
}

extern (C)
pure nothrow @trusted @nogc @live
private int compare_keys(scope const void* key1, scope const void* key2)

	in
	{
		assert(key1 != null);
		assert(key2 != null);
	}

	do
	{
		const .key_len_* k1 = cast(const .key_len_*)(key1);
		const .key_len_* k2 = cast(const .key_len_*)(key2);
		const size_t min_size = (k1.len < k2.len) ? (k1.len) : (k2.len);
		int res = core.stdc.string.memcmp(k1.key, k2.key, min_size);

		if (res) {
			return res;
		}

		return k1.len - k2.len;
	}

nothrow @trusted @nogc
private int do_dump(scope const jansson_d.jansson.json_t* json, size_t flags, int depth, scope jansson_d.hashtable.hashtable_t* parents, jansson_d.jansson.json_dump_callback_t dump, void* data)

	in
	{
		assert(dump != null);
	}

	do
	{
		int embed = flags & jansson_d.jansson.JSON_EMBED;

		flags &= ~jansson_d.jansson.JSON_EMBED;

		if (json == null) {
			return -1;
		}

		switch (mixin (jansson_d.jansson.json_typeof!("json"))) {
			case jansson_d.jansson.json_type.JSON_NULL:
				return dump("null", 4, data);

			case jansson_d.jansson.json_type.JSON_TRUE:
				return dump("true", 4, data);

			case jansson_d.jansson.json_type.JSON_FALSE:
				return dump("false", 5, data);

			case jansson_d.jansson.json_type.JSON_INTEGER:
				char[.MAX_INTEGER_STR_LENGTH] buffer = void;
				int size = jansson_d.jansson_private.snprintf(&(buffer[0]), buffer.length, "%" ~ jansson_d.jansson.JSON_INTEGER_FORMAT, jansson_d.value.json_integer_value(json));

				if ((size < 0) || (size >= buffer.length)) {
					return -1;
				}

				return dump(&(buffer[0]), size, data);

			case jansson_d.jansson.json_type.JSON_REAL:
				char[.MAX_REAL_STR_LENGTH] buffer = void;
				double value = jansson_d.value.json_real_value(json);
				int size = jansson_d.jansson_private.jsonp_dtostr(&(buffer[0]), buffer.length, value, mixin (.FLAGS_TO_PRECISION!("flags")));

				if (size < 0) {
					return -1;
				}

				return dump(&(buffer[0]), size, data);

			case jansson_d.jansson.json_type.JSON_STRING:
				return .dump_string(jansson_d.value.json_string_value(json), jansson_d.value.json_string_length(json), dump, data, flags);

			case jansson_d.jansson.json_type.JSON_ARRAY:
				/*
				 * Space for "0x", double the sizeof a pointer for the hex and a
				 * terminator.
				 */
				char[2 + (json.sizeof * 2) + 1] key = void;
				size_t key_len = void;

				/* detect circular references */
				if (jansson_d.jansson_private.jsonp_loop_check(parents, json, &(key[0]), key.length, &key_len)) {
					return -1;
				}

				size_t n = jansson_d.value.json_array_size(json);

				if ((!embed) && (dump("[", 1, data))) {
					return -1;
				}

				if (n == 0) {
					jansson_d.hashtable.hashtable_del(parents, &(key[0]), key_len);

					return (embed) ? (0) : (dump("]", 1, data));
				}

				if (.dump_indent(flags, depth + 1, 0, dump, data)) {
					return -1;
				}

				for (size_t i = 0; i < n; ++i) {
					if (.do_dump(jansson_d.value.json_array_get(json, i), flags, depth + 1, parents, dump, data)) {
						return -1;
					}

					if (i < (n - 1)) {
						if ((dump(",", 1, data)) || (.dump_indent(flags, depth + 1, 1, dump, data))) {
							return -1;
						}
					} else {
						if (.dump_indent(flags, depth, 0, dump, data)) {
							return -1;
						}
					}
				}

				jansson_d.hashtable.hashtable_del(parents, &(key[0]), key_len);

				return (embed) ? (0) : (dump("]", 1, data));

			case jansson_d.jansson.json_type.JSON_OBJECT:
				const (char)* separator = void;
				int separator_length = void;

				if (flags & jansson_d.jansson.JSON_COMPACT) {
					separator = ":";
					separator_length = 1;
				} else {
					separator = ": ";
					separator_length = 2;
				}

				char[jansson_d.jansson_private.LOOP_KEY_LEN] loop_key = void;
				size_t loop_key_len = void;

				/* detect circular references */
				if (jansson_d.jansson_private.jsonp_loop_check(parents, json, &(loop_key[0]), loop_key.length, &loop_key_len)) {
					return -1;
				}

				void* iter = jansson_d.value.json_object_iter(cast(jansson_d.jansson.json_t*)(json));

				if ((!embed) && (dump("{", 1, data))) {
					return -1;
				}

				if (iter == null) {
					jansson_d.hashtable.hashtable_del(parents, &(loop_key[0]), loop_key_len);

					return (embed) ? (0) : (dump("}", 1, data));
				}

				if (.dump_indent(flags, depth + 1, 0, dump, data)) {
					return -1;
				}

				if (flags & jansson_d.jansson.JSON_SORT_KEYS) {
					size_t size = jansson_d.value.json_object_size(json);
					.key_len_* keys = cast(.key_len_*)(jansson_d.jansson_private.jsonp_malloc(size * .key_len_.sizeof));

					if (keys == null) {
						return -1;
					}

					size_t i = 0;

					while (iter != null) {
						.key_len_* keylen = &keys[i];

						keylen.key = jansson_d.value.json_object_iter_key(iter);
						keylen.len = cast(int)(jansson_d.value.json_object_iter_key_len(iter));

						iter = jansson_d.value.json_object_iter_next(cast(jansson_d.jansson.json_t*)(json), iter);
						i++;
					}

					assert(i == size);

					core.stdc.stdlib.qsort(keys, size, .key_len_.sizeof, &.compare_keys);

					for (i = 0; i < size; i++) {
						const .key_len_* key = &keys[i];
						jansson_d.jansson.json_t* value = jansson_d.value.json_object_getn(json, key.key, key.len);
						assert(value);

						.dump_string(key.key, key.len, dump, data, flags);

						if ((dump(separator, separator_length, data)) || (.do_dump(value, flags, depth + 1, parents, dump, data))) {
							jansson_d.jansson_private.jsonp_free(keys);

							return -1;
						}

						if (i < (size - 1)) {
							if ((dump(",", 1, data)) || (.dump_indent(flags, depth + 1, 1, dump, data))) {
								jansson_d.jansson_private.jsonp_free(keys);

								return -1;
							}
						} else {
							if (.dump_indent(flags, depth, 0, dump, data)) {
								jansson_d.jansson_private.jsonp_free(keys);

								return -1;
							}
						}
					}

					jansson_d.jansson_private.jsonp_free(keys);
				} else {
					/* Don't sort keys */

					while (iter != null) {
						void* next = jansson_d.value.json_object_iter_next(cast(jansson_d.jansson.json_t*)(json), iter);
						const char* key = jansson_d.value.json_object_iter_key(iter);
						const size_t key_len = jansson_d.value.json_object_iter_key_len(iter);

						.dump_string(key, key_len, dump, data, flags);

						if ((dump(separator, separator_length, data)) || (.do_dump(jansson_d.value.json_object_iter_value(iter), flags, depth + 1, parents, dump, data))) {
							return -1;
						}

						if (next != null) {
							if ((dump(",", 1, data)) || (.dump_indent(flags, depth + 1, 1, dump, data))) {
								return -1;
							}
						} else {
							if (.dump_indent(flags, depth, 0, dump, data)) {
								return -1;
							}
						}

						iter = next;
					}
				}

				jansson_d.hashtable.hashtable_del(parents, &(loop_key[0]), loop_key_len);

				return (embed) ? (0) : (dump("}", 1, data));

			default:
				/* not reached */
				return -1;
		}
	}

///
extern (C)
nothrow @trusted @nogc @live //ToDo: @nodiscard
public char* json_dumps(scope const jansson_d.jansson.json_t* json, size_t flags)

	do
	{
		jansson_d.strbuffer.strbuffer_t strbuff = void;

		if (jansson_d.strbuffer.strbuffer_init(&strbuff)) {
			return null;
		}

		char* result = void;

		if (.json_dump_callback(json, &.dump_to_strbuffer, cast(void*)(&strbuff), flags)) {
			result = null;
		} else {
			result = jansson_d.jansson_private.jsonp_strdup(jansson_d.strbuffer.strbuffer_value(&strbuff));
		}

		jansson_d.strbuffer.strbuffer_close(&strbuff);

		return result;
	}

///
extern (C)
nothrow @trusted @nogc @live
public size_t json_dumpb(scope const jansson_d.jansson.json_t* json, scope char* buffer, size_t size, size_t flags)

	do
	{
		.buffer_ buf = {size, 0, buffer};

		if (.json_dump_callback(json, &.dump_to_buffer, cast(void*)(&buf), flags)) {
			return 0;
		}

		return buf.used;
	}

///
extern (C)
nothrow @trusted @nogc @live
public int json_dumpf(scope const jansson_d.jansson.json_t* json, core.stdc.stdio.FILE* output, size_t flags)

	do
	{
		return .json_dump_callback(json, &.dump_to_file, cast(void*)(output), flags);
	}

///
extern (C)
nothrow @trusted @nogc @live
public int json_dumpfd(scope const jansson_d.jansson.json_t* json, int output, size_t flags)

	do
	{
		return .json_dump_callback(json, &.dump_to_fd, cast(void*)(&output), flags);
	}

///
extern (C)
nothrow @nogc @live
public int json_dump_file(scope const jansson_d.jansson.json_t* json, scope const char* path, size_t flags)

	do
	{
		core.stdc.stdio.FILE* output = core.stdc.stdio.fopen(path, "w");

		if (output == null) {
			return -1;
		}

		int result = .json_dumpf(json, output, flags);

		if (core.stdc.stdio.fclose(output) != 0) {
			return -1;
		}

		return result;
	}

///
extern (C)
nothrow @trusted @nogc
public int json_dump_callback(scope const jansson_d.jansson.json_t* json, jansson_d.jansson.json_dump_callback_t callback, void* data, size_t flags)

	do
	{
		if (!(flags & jansson_d.jansson.JSON_ENCODE_ANY)) {
			if ((!mixin (jansson_d.jansson.json_is_array!("json"))) && (!mixin (jansson_d.jansson.json_is_object!("json")))) {
				return -1;
			}
		}

		jansson_d.hashtable.hashtable_t parents_set = void;

		if (jansson_d.hashtable.hashtable_init(&parents_set)) {
			return -1;
		}

		int res = .do_dump(json, flags, 0, &parents_set, callback, data);
		jansson_d.hashtable.hashtable_close(&parents_set);

		return res;
	}
