/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.load;


package:

private static import core.stdc.errno;
private static import core.stdc.stdio;
private static import core.stdc.stdlib;
private static import core.stdc.string;
private static import core.sys.posix.unistd;
private static import jansson_d.jansson;
private static import jansson_d.jansson_config;
private static import jansson_d.jansson_private;
private static import jansson_d.strbuffer;
private static import jansson_d.utf;
private static import jansson_d.value;

enum STREAM_STATE_OK = 0;
enum STREAM_STATE_EOF = -1;
enum STREAM_STATE_ERROR = -2;

enum TOKEN_INVALID = -1;
enum TOKEN_EOF = 0;
enum TOKEN_STRING = 256;
enum TOKEN_INTEGER = 257;
enum TOKEN_REAL = 258;
enum TOKEN_TRUE = 259;
enum TOKEN_FALSE = 260;
enum TOKEN_NULL = 261;

/* Locale independent versions of isxxx() functions */
private template l_isupper(string c)
{
	enum l_isupper = "(('A' <= (c)) && ((c) <= 'Z'))";
}

private template l_islower(string c)
{
	enum l_islower = "(('a' <= (c)) && ((c) <= 'z'))";
}

private template l_isalpha(string c)
{
	enum l_isalpha = "((mixin (jansson_d.load.l_isupper!(\"" ~ c ~ "\"))) || (mixin (jansson_d.load.l_islower!(\"" ~ c ~ "\"))))";
}

private template l_isdigit(string c)
{
	enum l_isdigit = "(('0' <= (c)) && ((c) <= '9'))";
}

private template l_isxdigit(string c)
{
	enum l_isxdigit = "((mixin (jansson_d.load.l_isdigit!(\"" ~ c ~ "\"))) || (('A' <= (c)) && ((c) <= 'F')) || (('a' <= (c)) && ((c) <= 'f')))";
}

/*
 * Read one byte from stream, convert to ubyte, then int, and
 * return. return EOF on end of file. This corresponds to the
 * behaviour of fgetc().
 */
alias get_func = extern (C) nothrow @nogc @live int function(scope void* data);

struct stream_t
{
	.get_func get;
	void* data;
	char[5] buffer;
	size_t buffer_pos;
	int state;
	int line;
	int column;
	int last_column;
	size_t position;
}

struct lex_t
{
	.stream_t stream;
	jansson_d.strbuffer.strbuffer_t saved_text;
	size_t flags;
	size_t depth;
	int token;

	union value_
	{
		struct string__
		{
			char* val;
			size_t len;
		}

		string__ string_;
		jansson_d.jansson.json_int_t integer;
		double real_;
	}

	value_ value;
}

private template stream_to_lex(string stream)
{
	enum stream_to_lex = "(mixin (jansson_d.jansson_private.container_of!(\"" ~ stream ~ "\", \"jansson_d.load.lex_t\", \"stream\")))";
}

/* error reporting */
nothrow @trusted @nogc @live
private void error_set(F ...)(scope jansson_d.jansson.json_error_t* error, scope const .lex_t* lex, jansson_d.jansson.json_error_code_t code, scope const char* msg, F f)

	do
	{
		char[jansson_d.jansson.JSON_ERROR_TEXT_LENGTH] msg_text = void;
		char[jansson_d.jansson.JSON_ERROR_TEXT_LENGTH] msg_with_context = void;

		int line = -1;
		int col = -1;
		size_t pos = 0;
		const (char)* result = &(msg_text[0]);

		if (error == null) {
			return;
		}

		static if (f.length != 0) {
			jansson_d.jansson_private.snprintf(&(msg_text[0]), msg_text.length, msg, f[0 .. $]);
		} else {
			jansson_d.jansson_private.snprintf(&(msg_text[0]), msg_text.length, msg);
		}

		msg_text[msg_text.length - 1] = '\0';

		if (lex != null) {
			const char* saved_text = jansson_d.strbuffer.strbuffer_value(&lex.saved_text);

			line = lex.stream.line;
			col = lex.stream.column;
			pos = lex.stream.position;

			if ((saved_text != null) && (saved_text[0])) {
				if (lex.saved_text.length_ <= 20) {
					jansson_d.jansson_private.snprintf(&(msg_with_context[0]), msg_with_context.length, "%s near '%s'", &(msg_text[0]), saved_text);
					msg_with_context[msg_with_context.length - 1] = '\0';
					result = &(msg_with_context[0]);
				}
			} else {
				if (code == jansson_d.jansson.json_error_code_t.json_error_invalid_syntax) {
					/* More specific error code for premature end of file. */
					code = jansson_d.jansson.json_error_code_t.json_error_premature_end_of_input;
				}

				if (lex.stream.state == .STREAM_STATE_ERROR) {
					/* No context for UTF-8 decoding errors */
					result = &(msg_text[0]);
				} else {
					jansson_d.jansson_private.snprintf(&(msg_with_context[0]), msg_with_context.length, "%s near end of file", &(msg_text[0]));
					msg_with_context[msg_with_context.length - 1] = '\0';
					result = &(msg_with_context[0]);
				}
			}
		}

		jansson_d.jansson_private.jsonp_error_set(error, line, col, pos, code, "%s", result);
	}

/* lexical analyzer */

pure nothrow @trusted @nogc @live
private void stream_init(scope .stream_t* stream, .get_func get, scope void* data)

	in
	{
		assert(stream != null);
	}

	do
	{
		stream.get = get;
		stream.data = data;
		stream.buffer[0] = '\0';
		stream.buffer_pos = 0;

		stream.state = .STREAM_STATE_OK;
		stream.line = 1;
		stream.column = 0;
		stream.position = 0;
	}

nothrow @nogc @live
private int stream_get(scope .stream_t* stream, scope jansson_d.jansson.json_error_t* error)

	in
	{
		assert(stream != null);
	}

	do
	{
		if (stream.state != .STREAM_STATE_OK) {
			return stream.state;
		}

		int c = void;

		if (!stream.buffer[stream.buffer_pos]) {
			assert(stream.get != null);
			c = stream.get(stream.data);

			if (c == core.stdc.stdio.EOF) {
				stream.state = .STREAM_STATE_EOF;

				return .STREAM_STATE_EOF;
			}

			stream.buffer[0] = cast(char)(c);
			stream.buffer_pos = 0;

			if ((0x80 <= c) && (c <= 0xFF)) {
				/* multi-byte UTF-8 sequence */

				size_t count = jansson_d.utf.utf8_check_first(cast(char)(c));

				if (count == 0) {
					goto out_;
				}

				assert(count >= 2);

				for (size_t i = 1; i < count; i++) {
					stream.buffer[i] = cast(char)(stream.get(stream.data));
				}

				if (!jansson_d.utf.utf8_check_full(&(stream.buffer[0]), count, null)) {
					goto out_;
				}

				stream.buffer[count] = '\0';
			} else {
				stream.buffer[1] = '\0';
			}
		}

		c = stream.buffer[stream.buffer_pos++];

		stream.position++;

		if (c == '\n') {
			stream.line++;
			stream.last_column = stream.column;
			stream.column = 0;
		} else if (jansson_d.utf.utf8_check_first(cast(char)(c))) {
			/*
			 * track the Unicode character column, so increment only if
			 * this is the first character of a UTF-8 sequence
			 */
			stream.column++;
		}

		return c;

	out_:
		stream.state = .STREAM_STATE_ERROR;
		.error_set(error, mixin (.stream_to_lex!("stream")), jansson_d.jansson.json_error_code_t.json_error_invalid_utf8, "unable to decode byte 0x%x", c);

		return .STREAM_STATE_ERROR;
	}

pure nothrow @trusted @nogc @live
private void stream_unget(scope .stream_t* stream, int c)

	in
	{
		assert(stream != null);
	}

	do
	{
		if ((c == .STREAM_STATE_EOF) || (c == .STREAM_STATE_ERROR)) {
			return;
		}

		stream.position--;

		if (c == '\n') {
			stream.line--;
			stream.column = stream.last_column;
		} else if (jansson_d.utf.utf8_check_first(cast(char)(c))) {
			stream.column--;
		}

		assert(stream.buffer_pos > 0);
		stream.buffer_pos--;
		assert(stream.buffer[stream.buffer_pos] == c);
	}

nothrow @nogc @live
private int lex_get(scope .lex_t* lex, scope jansson_d.jansson.json_error_t* error)

	in
	{
		assert(lex != null);
	}

	do
	{
		return .stream_get(&lex.stream, error);
	}

nothrow @trusted @nogc
private void lex_save(scope .lex_t* lex, int c)

	in
	{
		assert(lex != null);
	}

	do
	{
		jansson_d.strbuffer.strbuffer_append_byte(&lex.saved_text, cast(char)(c));
	}

nothrow @nogc @live
private int lex_get_save(scope .lex_t* lex, scope jansson_d.jansson.json_error_t* error)

	in
	{
		assert(lex != null);
	}

	do
	{
		int c = .stream_get(&lex.stream, error);

		if ((c != .STREAM_STATE_EOF) && (c != .STREAM_STATE_ERROR)) {
			.lex_save(lex, c);
		}

		return c;
	}

pure nothrow @trusted @nogc @live
private void lex_unget(scope .lex_t* lex, int c)

	in
	{
		assert(lex != null);
	}

	do
	{
		.stream_unget(&lex.stream, c);
	}

pure nothrow @trusted @nogc @live
private void lex_unget_unsave(scope .lex_t* lex, int c)

	in
	{
		assert(lex != null);
	}

	do
	{
		if ((c != .STREAM_STATE_EOF) && (c != .STREAM_STATE_ERROR)) {
			/*
			 * Since we treat warnings as errors, when assertions are turned
			 * off the "d" variable would be set but never used. Which is
			 * treated as an error by GCC.
			 */
			//#if !defined(NDEBUG)
				//char d;
			//#endif

			.stream_unget(&lex.stream, c);

			version (NDEBUG) {
				jansson_d.strbuffer.strbuffer_pop(&lex.saved_text);
			} else {
				char d = jansson_d.strbuffer.strbuffer_pop(&lex.saved_text);
			}

			//assert(c == d);
		}
	}

nothrow @trusted @nogc
private void lex_save_cached(scope .lex_t* lex)

	in
	{
		assert(lex != null);
	}

	do
	{
		while (lex.stream.buffer[lex.stream.buffer_pos] != '\0') {
			.lex_save(lex, lex.stream.buffer[lex.stream.buffer_pos]);
			lex.stream.buffer_pos++;
			lex.stream.position++;
		}
	}

nothrow @trusted @nogc
private void lex_free_string(scope .lex_t* lex)

	in
	{
		assert(lex != null);
	}

	do
	{
		jansson_d.jansson_private.jsonp_free(lex.value.string_.val);
		lex.value.string_.val = null;
		lex.value.string_.len = 0;
	}

/* assumes that str points to 'u' plus at least 4 valid hex digits */
pure nothrow @trusted @nogc @live
private int decode_unicode_escape(scope const char* str)

	in
	{
		assert(str != null);
		assert(str[0] == 'u');
	}

	do
	{
		int value = 0;

		for (size_t i = 1; i <= 4; i++) {
			char c = str[i];
			value <<= 4;

			if (mixin (.l_isdigit!("c"))) {
				value += c - '0';
			} else if (mixin (.l_islower!("c"))) {
				value += c - 'a' + 10;
			} else if (mixin (.l_isupper!("c"))) {
				value += c - 'A' + 10;
			} else {
				return -1;
			}
		}

		return value;
	}

nothrow @nogc @live
private void lex_scan_string(scope .lex_t* lex, scope jansson_d.jansson.json_error_t* error)

	in
	{
		assert(lex != null);
	}

	do
	{
		char* t = void;
		const (char)* p = void;

		lex.value.string_.val = null;
		lex.token = .TOKEN_INVALID;

		int c = .lex_get_save(lex, error);

		while (c != '"') {
			if (c == .STREAM_STATE_ERROR) {
				goto out_;
			} else if (c == .STREAM_STATE_EOF) {
				.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_premature_end_of_input, "premature end of input");

				goto out_;
			} else if ((0 <= c) && (c <= 0x1F)) {
				/* control character */
				.lex_unget_unsave(lex, c);

				if (c == '\n') {
					.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "unexpected newline");
				} else {
					.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "control character 0x%x", c);
				}

				goto out_;
			} else if (c == '\\') {
				c = .lex_get_save(lex, error);

				if (c == 'u') {
					c = .lex_get_save(lex, error);

					for (size_t i = 0; i < 4; i++) {
						if (!mixin (.l_isxdigit!("c"))) {
							.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "invalid escape");

							goto out_;
						}

						c = .lex_get_save(lex, error);
					}
				} else if ((c == '"') || (c == '\\') || (c == '/') || (c == 'b') || (c == 'f') || (c == 'n') || (c == 'r') || (c == 't')) {
					c = .lex_get_save(lex, error);
				} else {
					.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "invalid escape");

					goto out_;
				}
			} else {
				c = .lex_get_save(lex, error);
			}
		}

		/*
		 * the actual value is at most of the same length as the source
		 *    string_, because:
		 *      - shortcut escapes (e.g. "\t") (length 2) are converted to 1 byte
		 *      - a single \uXXXX escape (length 6) is converted to at most 3 bytes
		 *      - two \uXXXX escapes (length 12) forming an UTF-16 surrogate pair
		 *        are converted to 4 bytes
		 */
		t = cast(char*)(jansson_d.jansson_private.jsonp_malloc(lex.saved_text.length_ + 1));

		if (t == null) {
			/* this is not very nice, since TOKEN_INVALID is returned */
			goto out_;
		}

		lex.value.string_.val = t;

		/* + 1 to skip the " */
		assert(jansson_d.strbuffer.strbuffer_value(&lex.saved_text) != null);
		p = jansson_d.strbuffer.strbuffer_value(&lex.saved_text) + 1;

		while (*p != '"') {
			if (*p == '\\') {
				p++;

				if (*p == 'u') {
					int value = .decode_unicode_escape(p);

					if (value < 0) {
						.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "invalid Unicode escape '%.6s'", p - 1);

						goto out_;
					}

					p += 5;

					if ((0xD800 <= value) && (value <= 0xDBFF)) {
						/* surrogate pair */
						if ((*p == '\\') && (*(p + 1) == 'u')) {
							int value2 = .decode_unicode_escape(++p);

							if (value2 < 0) {
								.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "invalid Unicode escape '%.6s'", p - 1);

								goto out_;
							}

							p += 5;

							if ((0xDC00 <= value2) && (value2 <= 0xDFFF)) {
								/* valid second surrogate */
								value = ((value - 0xD800) << 10) + (value2 - 0xDC00) + 0x010000;
							} else {
								/* invalid second surrogate */
								.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "invalid Unicode '\\u%04X\\u%04X'", value, value2);

								goto out_;
							}
						} else {
							/* no second surrogate */
							.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "invalid Unicode '\\u%04X'", value);

							goto out_;
						}
					} else if ((0xDC00 <= value) && (value <= 0xDFFF)) {
						.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "invalid Unicode '\\u%04X'", value);

						goto out_;
					}

					size_t length_ = void;

					if (jansson_d.utf.utf8_encode(value, t, &length_)) {
						assert(0);
					}

					t += length_;
				} else {
					switch (*p) {
						case '"':
						case '\\':
						case '/':
							*t = *p;

							break;

						case 'b':
							*t = '\b';

							break;

						case 'f':
							*t = '\f';

							break;

						case 'n':
							*t = '\n';

							break;

						case 'r':
							*t = '\r';

							break;

						case 't':
							*t = '\t';

							break;

						default:
							assert(0);
					}

					t++;
					p++;
				}
			} else {
				*(t++) = *(p++);
			}
		}

		*t = '\0';
		lex.value.string_.len = t - lex.value.string_.val;
		lex.token = .TOKEN_STRING;

		return;

	out_:
		.lex_free_string(lex);
	}

/* disabled if using cmake */
version (JANSSON_USING_CMAKE) {
} else {
	static if (jansson_d.jansson_config.JSON_INTEGER_IS_LONG_LONG) {
		static if (__traits(compiles, core.stdc.stdlib._strtoi64)) {
			private alias json_strtoint = core.stdc.stdlib._strtoi64;
		} else {
			private alias json_strtoint = core.stdc.stdlib.strtoll;
		}
	} else {
		private alias json_strtoint = core.stdc.stdlib.strtol;
	}
}

nothrow @nogc @live
private int lex_scan_number(scope .lex_t* lex, int c, scope jansson_d.jansson.json_error_t* error)

	in
	{
		assert(lex != null);
	}

	do
	{
		lex.token = .TOKEN_INVALID;

		if (c == '-') {
			c = .lex_get_save(lex, error);
		}

		if (c == '0') {
			c = .lex_get_save(lex, error);

			if (mixin (.l_isdigit!("c"))) {
				.lex_unget_unsave(lex, c);

				return -1;
			}
		} else if (mixin (.l_isdigit!("c"))) {
			do {
				c = .lex_get_save(lex, error);
			} while (mixin (.l_isdigit!("c")));
		} else {
			.lex_unget_unsave(lex, c);

			return -1;
		}

		if ((!(lex.flags & jansson_d.jansson.JSON_DECODE_INT_AS_REAL)) && (c != '.') && (c != 'E') && (c != 'e')) {
			.lex_unget_unsave(lex, c);

			const char* saved_text = jansson_d.strbuffer.strbuffer_value(&lex.saved_text);

			core.stdc.errno.errno = 0;
			const (char)* end = null;
			jansson_d.jansson.json_int_t intval = .json_strtoint(saved_text, &end, 10);

			if (core.stdc.errno.errno == core.stdc.errno.ERANGE) {
				if (intval < 0) {
					.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_numeric_overflow, "too big negative integer");
				} else {
					.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_numeric_overflow, "too big integer");
				}

				return -1;
			}

			assert(end == (saved_text + lex.saved_text.length_));

			lex.token = .TOKEN_INTEGER;
			lex.value.integer = intval;

			return 0;
		}

		if (c == '.') {
			c = .lex_get(lex, error);

			if (!mixin (.l_isdigit!("c"))) {
				.lex_unget(lex, c);

				return -1;
			}

			.lex_save(lex, c);

			do {
				c = .lex_get_save(lex, error);
			} while (mixin (.l_isdigit!("c")));
		}

		if ((c == 'E') || (c == 'e')) {
			c = .lex_get_save(lex, error);

			if ((c == '+') || (c == '-')) {
				c = .lex_get_save(lex, error);
			}

			if (!mixin (.l_isdigit!("c"))) {
				.lex_unget_unsave(lex, c);

				return -1;
			}

			do {
				c = .lex_get_save(lex, error);
			} while (mixin (.l_isdigit!("c")));
		}

		.lex_unget_unsave(lex, c);

		double doubleval = void;

		if (jansson_d.jansson_private.jsonp_strtod(&lex.saved_text, &doubleval)) {
			.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_numeric_overflow, "real number overflow");

			return -1;
		}

		lex.token = .TOKEN_REAL;
		lex.value.real_ = doubleval;

		return 0;
	}

nothrow @trusted @nogc
private int lex_scan(scope .lex_t* lex, scope jansson_d.jansson.json_error_t* error)

	in
	{
		assert(lex != null);
	}

	do
	{
		jansson_d.strbuffer.strbuffer_clear(&lex.saved_text);

		if (lex.token == .TOKEN_STRING) {
			.lex_free_string(lex);
		}

		int c = void;

		do {
			c = .lex_get(lex, error);
		} while ((c == ' ') || (c == '\t') || (c == '\n') || (c == '\r'));

		if (c == .STREAM_STATE_EOF) {
			lex.token = .TOKEN_EOF;

			goto out_;
		}

		if (c == .STREAM_STATE_ERROR) {
			lex.token = .TOKEN_INVALID;

			goto out_;
		}

		.lex_save(lex, c);

		if ((c == '{') || (c == '}') || (c == '[') || (c == ']') || (c == ':') || (c == ',')) {
			lex.token = c;
		} else if (c == '"') {
			.lex_scan_string(lex, error);
		} else if ((mixin (.l_isdigit!("c"))) || (c == '-')) {
			if (.lex_scan_number(lex, c, error)) {
				goto out_;
			}
		} else if (mixin (.l_isalpha!("c"))) {
			/* eat up the whole identifier for clearer error messages */

			do {
				c = .lex_get_save(lex, error);
			} while (mixin (.l_isalpha!("c")));

			.lex_unget_unsave(lex, c);

			const char* saved_text = jansson_d.strbuffer.strbuffer_value(&lex.saved_text);

			if (core.stdc.string.strcmp(saved_text, "true") == 0) {
				lex.token = .TOKEN_TRUE;
			} else if (core.stdc.string.strcmp(saved_text, "false") == 0) {
				lex.token = .TOKEN_FALSE;
			} else if (core.stdc.string.strcmp(saved_text, "null") == 0) {
				lex.token = .TOKEN_NULL;
			} else {
				lex.token = .TOKEN_INVALID;
			}
		} else {
			/*
			 * save the rest of the input UTF-8 sequence to get an error
			 * message of valid UTF-8
			 */
			.lex_save_cached(lex);
			lex.token = .TOKEN_INVALID;
		}

	out_:
		return lex.token;
	}

pure nothrow @trusted @nogc @live
private char* lex_steal_string(scope .lex_t* lex, scope size_t* out_len)

	in
	{
		assert(lex != null);
		assert(out_len != null);
	}

	do
	{
		char* result = null;

		if (lex.token == .TOKEN_STRING) {
			result = lex.value.string_.val;
			*out_len = lex.value.string_.len;
			lex.value.string_.val = null;
			lex.value.string_.len = 0;
		}

		return result;
	}

nothrow @trusted @nogc
private int lex_init(scope .lex_t* lex, .get_func get, size_t flags, scope void* data)

	in
	{
		assert(lex != null);
	}

	do
	{
		.stream_init(&lex.stream, get, data);

		if (jansson_d.strbuffer.strbuffer_init(&lex.saved_text)) {
			return -1;
		}

		lex.flags = flags;
		lex.token = .TOKEN_INVALID;

		return 0;
	}

nothrow @trusted @nogc
private void lex_close(scope .lex_t* lex)

	in
	{
		assert(lex != null);
	}

	do
	{
		if (lex.token == .TOKEN_STRING) {
			.lex_free_string(lex);
		}

		jansson_d.strbuffer.strbuffer_close(&lex.saved_text);
	}

/* parser */

nothrow @trusted @nogc
private jansson_d.jansson.json_t* parse_object(scope lex_t* lex, size_t flags, scope jansson_d.jansson.json_error_t* error)

	in
	{
		assert(lex != null);
	}

	do
	{
		jansson_d.jansson.json_t* object = jansson_d.value.json_object();

		if (object == null) {
			return null;
		}

		.lex_scan(lex, error);

		if (lex.token == '}') {
			return object;
		}

		while (true) {
			if (lex.token != .TOKEN_STRING) {
				.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "string or '}' expected");

				goto error_;
			}

			size_t len = void;
			char* key = .lex_steal_string(lex, &len);

			if (key == null) {
				return null;
			}

			if (core.stdc.string.memchr(key, '\0', len)) {
				jansson_d.jansson_private.jsonp_free(key);
				.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_null_byte_in_key, "NUL byte in object key not supported");

				goto error_;
			}

			if (flags & jansson_d.jansson.JSON_REJECT_DUPLICATES) {
				if (jansson_d.value.json_object_getn(object, key, len)) {
					jansson_d.jansson_private.jsonp_free(key);
					.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_duplicate_key, "duplicate object key");

					goto error_;
				}
			}

			.lex_scan(lex, error);

			if (lex.token != ':') {
				jansson_d.jansson_private.jsonp_free(key);
				.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "':' expected");

				goto error_;
			}

			.lex_scan(lex, error);
			jansson_d.jansson.json_t* value = .parse_value(lex, flags, error);

			if (value == null) {
				jansson_d.jansson_private.jsonp_free(key);

				goto error_;
			}

			if (jansson_d.value.json_object_setn_new_nocheck(object, key, len, value)) {
				jansson_d.jansson_private.jsonp_free(key);

				goto error_;
			}

			jansson_d.jansson_private.jsonp_free(key);

			.lex_scan(lex, error);

			if (lex.token != ',') {
				break;
			}

			.lex_scan(lex, error);
		}

		if (lex.token != '}') {
			.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "'}' expected");

			goto error_;
		}

		return object;

	error_:
		jansson_d.jansson.json_decref(object);

		return null;
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* parse_array(scope .lex_t* lex, size_t flags, scope jansson_d.jansson.json_error_t* error)

	in
	{
		assert(lex != null);
	}

	do
	{
		jansson_d.jansson.json_t* array = jansson_d.value.json_array();

		if (array == null) {
			return null;
		}

		.lex_scan(lex, error);

		if (lex.token == ']') {
			return array;
		}

		while (lex.token) {
			jansson_d.jansson.json_t* elem = .parse_value(lex, flags, error);

			if (elem == null) {
				goto error_;
			}

			if (jansson_d.value.json_array_append_new(array, elem)) {
				goto error_;
			}

			.lex_scan(lex, error);

			if (lex.token != ',') {
				break;
			}

			.lex_scan(lex, error);
		}

		if (lex.token != ']') {
			.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "']' expected");

			goto error_;
		}

		return array;

	error_:
		jansson_d.jansson.json_decref(array);

		return null;
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* parse_value(scope .lex_t* lex, size_t flags, scope jansson_d.jansson.json_error_t* error)

	in
	{
		assert(lex != null);
	}

	do
	{
		lex.depth++;

		if (lex.depth > jansson_d.jansson_config.JSON_PARSER_MAX_DEPTH) {
			.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_stack_overflow, "maximum parsing depth reached");

			return null;
		}

		jansson_d.jansson.json_t* json = null;

		switch (lex.token) {
			case .TOKEN_STRING: {
				const char* value = lex.value.string_.val;
				size_t len = lex.value.string_.len;

				if (!(flags & jansson_d.jansson.JSON_ALLOW_NUL)) {
					if (core.stdc.string.memchr(value, '\0', len)) {
						.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_null_character, "\\u0000 is not allowed without JSON_ALLOW_NUL");

						return null;
					}
				}

				json = jansson_d.jansson_private.jsonp_stringn_nocheck_own(value, len);
				lex.value.string_.val = null;
				lex.value.string_.len = 0;

				break;
			}

			case .TOKEN_INTEGER: {
				json = jansson_d.value.json_integer(lex.value.integer);

				break;
			}

			case .TOKEN_REAL: {
				json = jansson_d.value.json_real(lex.value.real_);

				break;
			}

			case .TOKEN_TRUE:
				json = jansson_d.value.json_true();

				break;

			case .TOKEN_FALSE:
				json = jansson_d.value.json_false();

				break;

			case .TOKEN_NULL:
				json = jansson_d.value.json_null();

				break;

			case '{':
				json = .parse_object(lex, flags, error);

				break;

			case '[':
				json = .parse_array(lex, flags, error);

				break;

			case .TOKEN_INVALID:
				.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "invalid token");

				return null;

			default:
				.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "unexpected token");

				return null;
		}

		if (json == null) {
			return null;
		}

		lex.depth--;

		return json;
	}

nothrow @trusted @nogc
private jansson_d.jansson.json_t* parse_json(scope .lex_t* lex, size_t flags, scope jansson_d.jansson.json_error_t* error)

	in
	{
		assert(lex != null);
	}

	do
	{
		lex.depth = 0;

		.lex_scan(lex, error);

		if (!(flags & jansson_d.jansson.JSON_DECODE_ANY)) {
			if ((lex.token != '[') && (lex.token != '{')) {
				.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_invalid_syntax, "'[' or '{' expected");

				return null;
			}
		}

		jansson_d.jansson.json_t* result = .parse_value(lex, flags, error);

		if (result == null) {
			return null;
		}

		if (!(flags & jansson_d.jansson.JSON_DISABLE_EOF_CHECK)) {
			.lex_scan(lex, error);

			if (lex.token != .TOKEN_EOF) {
				.error_set(error, lex, jansson_d.jansson.json_error_code_t.json_error_end_of_input_expected, "end of file expected");
				jansson_d.jansson.json_decref(result);

				return null;
			}
		}

		if (error != null) {
			/* Save the position even though there was no error */
			error.position = cast(int)(lex.stream.position);
		}

		return result;
	}

struct string_data_t
{
	const (char)* data;
	size_t pos;
}

extern (C)
pure nothrow @trusted @nogc @live
private int string_get(scope void* data)

	in
	{
		assert(data != null);
	}

	do
	{
		.string_data_t* stream = cast(.string_data_t*)(data);
		char c = stream.data[stream.pos];

		if (c == '\0') {
			return core.stdc.stdio.EOF;
		} else {
			stream.pos++;

			return cast(ubyte)(c);
		}
	}

///
extern (C)
nothrow @trusted @nogc //ToDo: @nodiscard
public jansson_d.jansson.json_t* json_loads(scope const char* string_, size_t flags, scope jansson_d.jansson.json_error_t* error)

	do
	{
		jansson_d.jansson_private.jsonp_error_init(error, "<string>");

		if (string_ == null) {
			.error_set(error, null, jansson_d.jansson.json_error_code_t.json_error_invalid_argument, "wrong arguments");

			return null;
		}

		.string_data_t stream_data =
		{
			data: string_,
			pos: 0,
		};

		.lex_t lex = void;

		if (.lex_init(&lex, &.string_get, flags, cast(void*)(&stream_data))) {
			return null;
		}

		jansson_d.jansson.json_t* result = .parse_json(&lex, flags, error);

		.lex_close(&lex);

		return result;
	}

struct buffer_data_t
{
	const (char)* data;
	size_t len;
	size_t pos;
}

extern (C)
pure nothrow @trusted @nogc @live
private int buffer_get(scope void* data)

	in
	{
		assert(data != null);
	}

	do
	{
		.buffer_data_t* stream = cast(.buffer_data_t*)(data);

		if (stream.pos >= stream.len) {
			return core.stdc.stdio.EOF;
		}

		char c = stream.data[stream.pos];
		stream.pos++;

		return cast(ubyte)(c);
	}

///
extern (C)
nothrow @trusted @nogc //ToDo: @nodiscard
public jansson_d.jansson.json_t* json_loadb(scope const char* buffer, size_t buflen, size_t flags, scope jansson_d.jansson.json_error_t* error)

	do
	{
		jansson_d.jansson_private.jsonp_error_init(error, "<buffer>");

		if (buffer == null) {
			.error_set(error, null, jansson_d.jansson.json_error_code_t.json_error_invalid_argument, "wrong arguments");

			return null;
		}

		.buffer_data_t stream_data =
		{
			data: buffer,
			pos: 0,
			len: buflen,
		};

		.lex_t lex = void;

		if (.lex_init(&lex, &.buffer_get, flags, cast(void*)(&stream_data))) {
			return null;
		}

		jansson_d.jansson.json_t* result = .parse_json(&lex, flags, error);

		.lex_close(&lex);

		return result;
	}

///
extern (C)
nothrow @trusted @nogc //ToDo: @nodiscard
public jansson_d.jansson.json_t* json_loadf(core.stdc.stdio.FILE* input, size_t flags, scope jansson_d.jansson.json_error_t* error)

	do
	{
		const (char)* source = void;

		if (input == core.stdc.stdio.stdin) {
			source = "<stdin>";
		} else {
			source = "<stream>";
		}

		jansson_d.jansson_private.jsonp_error_init(error, source);

		if (input == null) {
			.error_set(error, null, jansson_d.jansson.json_error_code_t.json_error_invalid_argument, "wrong arguments");

			return null;
		}

		.lex_t lex = void;

		if (.lex_init(&lex, cast(.get_func)(&core.stdc.stdio.fgetc), flags, cast(void*)(input))) {
			return null;
		}

		jansson_d.jansson.json_t* result = .parse_json(&lex, flags, error);

		.lex_close(&lex);

		return result;
	}

extern (C)
nothrow @nogc @live
private int fd_get_func(scope int* fd)

	in
	{
		assert(fd != null);
	}

	do
	{
		static if (__traits(compiles, core.sys.posix.unistd.read)) {
			ubyte c = void;

			if (core.sys.posix.unistd.read(*fd, &c, 1) == 1) {
				return c;
			}
		}

		return core.stdc.stdio.EOF;
	}

///
extern (C)
nothrow @nogc @live //ToDo: @nodiscard
public jansson_d.jansson.json_t* json_loadfd(int input, size_t flags, scope jansson_d.jansson.json_error_t* error)

	do
	{
		const (char)* source = void;

		static if (__traits(compiles, core.sys.posix.unistd.STDIN_FILENO)) {
			if (input == core.sys.posix.unistd.STDIN_FILENO) {
				source = "<stdin>";
			} else {
				source = "<stream>";
			}
		} else {
			source = "<stream>";
		}

		jansson_d.jansson_private.jsonp_error_init(error, source);

		if (input < 0) {
			.error_set(error, null, jansson_d.jansson.json_error_code_t.json_error_invalid_argument, "wrong arguments");

			return null;
		}

		.lex_t lex = void;

		if (.lex_init(&lex, cast(.get_func)(&.fd_get_func), flags, &input)) {
			return null;
		}

		jansson_d.jansson.json_t* result = .parse_json(&lex, flags, error);

		.lex_close(&lex);

		return result;
	}

///
extern (C)
nothrow @nogc //ToDo: @nodiscard
public jansson_d.jansson.json_t* json_load_file(scope const char* path, size_t flags, scope jansson_d.jansson.json_error_t* error)

	do
	{
		jansson_d.jansson_private.jsonp_error_init(error, path);

		if (path == null) {
			.error_set(error, null, jansson_d.jansson.json_error_code_t.json_error_invalid_argument, "wrong arguments");

			return null;
		}

		core.stdc.stdio.FILE* fp = core.stdc.stdio.fopen(path, "rb");

		if (fp == null) {
			.error_set(error, null, jansson_d.jansson.json_error_code_t.json_error_cannot_open_file, "unable to open %s: %s", path, core.stdc.string.strerror(core.stdc.errno.errno));

			return null;
		}

		jansson_d.jansson.json_t* result = .json_loadf(fp, flags, error);

		core.stdc.stdio.fclose(fp);

		return result;
	}

enum MAX_BUF_LEN = 1024;

struct callback_data_t
{
	char[.MAX_BUF_LEN] data;
	size_t len;
	size_t pos;
	jansson_d.jansson.json_load_callback_t callback;
	void* arg;
}

extern (C)
nothrow @nogc
private int callback_get(scope void* data)

	in
	{
		assert(data != null);
		assert((cast(.callback_data_t*)(data)).callback != null);
	}

	do
	{
		.callback_data_t* stream = cast(.callback_data_t*)(data);

		if (stream.pos >= stream.len) {
			stream.pos = 0;
			stream.len = stream.callback(&(stream.data[0]), stream.data.length, stream.arg);

			if ((stream.len == 0) || (stream.len == size_t.max)) {
				return core.stdc.stdio.EOF;
			}
		}

		char c = stream.data[stream.pos];
		stream.pos++;

		return cast(ubyte)(c);
	}

///
extern (C)
nothrow @nogc //ToDo: @nodiscard
public jansson_d.jansson.json_t* json_load_callback(jansson_d.jansson.json_load_callback_t callback, scope void* arg, size_t flags, scope jansson_d.jansson.json_error_t* error)

	do
	{
		.callback_data_t stream_data = void;
		core.stdc.string.memset(&stream_data, 0, stream_data.sizeof);
		stream_data.callback = callback;
		stream_data.arg = arg;

		jansson_d.jansson_private.jsonp_error_init(error, "<callback>");

		if (callback == null) {
			.error_set(error, null, jansson_d.jansson.json_error_code_t.json_error_invalid_argument, "wrong arguments");

			return null;
		}

		.lex_t lex = void;

		if (.lex_init(&lex, cast(.get_func)(&.callback_get), flags, &stream_data)) {
			return null;
		}

		jansson_d.jansson.json_t* result = .parse_json(&lex, flags, error);

		.lex_close(&lex);

		return result;
	}
