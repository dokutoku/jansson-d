/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.utf;


package:

pure nothrow @trusted @nogc @live
int utf8_encode(int codepoint, scope char* buffer, scope size_t* size)

	in
	{
		assert(buffer != null);
		assert(size != null);
	}

	do
	{
		if (codepoint < 0) {
			return -1;
		} else if (codepoint < 0x80) {
			buffer[0] = cast(char)(codepoint);
			*size = 1;
		} else if (codepoint < 0x0800) {
			buffer[0] = 0xC0 + ((codepoint & 0x07C0) >> 6);
			buffer[1] = 0x80 + ((codepoint & 0x003F));
			*size = 2;
		} else if (codepoint < 0x010000) {
			buffer[0] = 0xE0 + ((codepoint & 0xF000) >> 12);
			buffer[1] = 0x80 + ((codepoint & 0x0FC0) >> 6);
			buffer[2] = 0x80 + ((codepoint & 0x003F));
			*size = 3;
		} else if (codepoint <= 0x10FFFF) {
			buffer[0] = 0xF0 + ((codepoint & 0x1C0000) >> 18);
			buffer[1] = 0x80 + ((codepoint & 0x03F000) >> 12);
			buffer[2] = 0x80 + ((codepoint & 0x000FC0) >> 6);
			buffer[3] = 0x80 + ((codepoint & 0x00003F));
			*size = 4;
		} else {
			return -1;
		}

		return 0;
	}

pure nothrow @safe @nogc @live
size_t utf8_check_first(char byte_)

	do
	{
		ubyte u = cast(ubyte)(byte_);

		if (u < 0x80) {
			return 1;
		}

		if ((0x80 <= u) && (u <= 0xBF)) {
			/*
			 * second, third or fourth byte of a multi-byte
			 * sequence, i.e. a "continuation byte"
			 */
			return 0;
		} else if ((u == 0xC0) || (u == 0xC1)) {
			/* overlong encoding of an ASCII byte */
			return 0;
		} else if ((0xC2 <= u) && (u <= 0xDF)) {
			/* 2-byte sequence */
			return 2;
		} else if ((0xE0 <= u) && (u <= 0xEF)) {
			/* 3-byte sequence */
			return 3;
		} else if ((0xF0 <= u) && (u <= 0xF4)) {
			/* 4-byte sequence */
			return 4;
		} else { /* u >= 0xF5 */
			/*
			 * Restricted (start of 4-, 5- or 6-byte sequence) or invalid
			 * UTF-8
			 */
			return 0;
		}
	}

pure nothrow @trusted @nogc @live
bool utf8_check_full(scope const char* buffer, size_t size, scope int* codepoint)

	in
	{
		assert(buffer != null);
	}

	do
	{
		ubyte u = cast(ubyte)(buffer[0]);
		int value = void;

		if (size == 2) {
			value = u & 0x1F;
		} else if (size == 3) {
			value = u & 0x0F;
		} else if (size == 4) {
			value = u & 0x07;
		} else {
			return false;
		}

		for (size_t i = 1; i < size; i++) {
			u = cast(ubyte)(buffer[i]);

			if ((u < 0x80) || (u > 0xBF)) {
				/* not a continuation byte */
				return false;
			}

			value = (value << 6) + (u & 0x3F);
		}

		if (value > 0x10FFFF) {
			/* not in Unicode range */
			return false;
		} else if ((0xD800 <= value) && (value <= 0xDFFF)) {
			/* invalid code point (UTF-16 surrogate halves) */
			return false;
		} else if (((size == 2) && (value < 0x80)) || ((size == 3) && (value < 0x0800)) || ((size == 4) && (value < 0x010000))) {
			/* overlong encoding */
			return false;
		}

		if (codepoint != null) {
			*codepoint = value;
		}

		return true;
	}

pure nothrow @trusted @nogc @live
const (char)* utf8_iterate(return scope const (char)* buffer, size_t bufsize, scope int* codepoint)

	in
	{
		assert(buffer != null);
	}

	do
	{
		if (bufsize == 0) {
			return buffer;
		}

		size_t count = .utf8_check_first(buffer[0]);

		if (count <= 0) {
			return null;
		}

		int value = void;

		if (count == 1) {
			value = cast(ubyte)(buffer[0]);
		} else {
			if ((count > bufsize) || (!.utf8_check_full(buffer, count, &value))) {
				return null;
			}
		}

		if (codepoint != null) {
			*codepoint = value;
		}

		return buffer + count;
	}

pure nothrow @trusted @nogc @live
int utf8_check_string(scope const char* string_, size_t length_)

	in
	{
		assert(string_ != null);
	}

	do
	{
		for (size_t i = 0; i < length_; i++) {
			size_t count = .utf8_check_first(string_[i]);

			if (count == 0) {
				return 0;
			} else if (count > 1) {
				if (count > (length_ - i)) {
					return 0;
				}

				if (!.utf8_check_full(&string_[i], count, null)) {
					return 0;
				}

				i += count - 1;
			}
		}

		return 1;
	}
