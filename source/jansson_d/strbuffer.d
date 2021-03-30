/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.strbuffer;


package:

private static import core.stdc.string;
private static import jansson_d.jansson;
private static import jansson_d.jansson_private;

struct strbuffer_t
{
	char* value;

	/* bytes used */
	size_t length_;

	@disable
	alias length = length_;

	/* bytes allocated */
	size_t size;
}

private enum STRBUFFER_MIN_SIZE = 16;
private enum STRBUFFER_FACTOR = 2;
private enum size_t STRBUFFER_SIZE_MAX = size_t.max;

nothrow @trusted @nogc //ToDo: @nodiscard
int strbuffer_init(scope strbuffer_t* strbuff)

	in
	{
		assert(strbuff != null);
	}

	do
	{
		strbuff.size = STRBUFFER_MIN_SIZE;
		strbuff.length_ = 0;

		strbuff.value = cast(char*)(jansson_d.jansson_private.jsonp_malloc(strbuff.size));

		if (strbuff.value == null) {
			return -1;
		}

		/* initialize to empty */
		strbuff.value[0] = '\0';

		return 0;
	}

nothrow @trusted @nogc
void strbuffer_close(scope strbuffer_t* strbuff)

	in
	{
		assert(strbuff != null);
	}

	do
	{
		jansson_d.jansson_private.jsonp_free(strbuff.value);
		strbuff.size = 0;
		strbuff.length_ = 0;
		strbuff.value = null;
	}

pure nothrow @trusted @nogc @live
void strbuffer_clear(scope strbuffer_t* strbuff)

	in
	{
		assert(strbuff != null);
	}

	do
	{
		strbuff.length_ = 0;
		strbuff.value[0] = '\0';
	}

pure nothrow @trusted @nogc @live
const (char)* strbuffer_value(return scope const strbuffer_t* strbuff)

	in
	{
		assert(strbuff != null);
	}

	do
	{
		return strbuff.value;
	}

/* Steal the value and close the strbuffer */
pure nothrow @trusted @nogc @live
char* strbuffer_steal_value(scope strbuffer_t* strbuff)

	in
	{
		assert(strbuff != null);
	}

	do
	{
		char* result = strbuff.value;
		strbuff.value = null;

		return result;
	}

nothrow @trusted @nogc
int strbuffer_append_byte(scope strbuffer_t* strbuff, char byte_)

	do
	{
		return .strbuffer_append_bytes(strbuff, &byte_, 1);
	}

nothrow @trusted @nogc
int strbuffer_append_bytes(scope strbuffer_t* strbuff, scope const char* data, size_t size)

	in
	{
		assert(strbuff != null);
	}

	do
	{
		if (size >= (strbuff.size - strbuff.length_)) {
			/* avoid integer overflow */
			if ((strbuff.size > (STRBUFFER_SIZE_MAX / STRBUFFER_FACTOR)) || (size > (STRBUFFER_SIZE_MAX - 1)) || (strbuff.length_ > (STRBUFFER_SIZE_MAX - 1 - size))) {
				return -1;
			}

			size_t new_size = mixin (jansson_d.jansson_private.max!("strbuff.size * STRBUFFER_FACTOR", "strbuff.length_ + size + 1"));

			char* new_value = cast(char*)(jansson_d.jansson_private.jsonp_malloc(new_size));

			if (new_value == null) {
				return -1;
			}

			core.stdc.string.memcpy(new_value, strbuff.value, strbuff.length_);

			jansson_d.jansson_private.jsonp_free(strbuff.value);
			strbuff.value = new_value;
			strbuff.size = new_size;
		}

		core.stdc.string.memcpy(strbuff.value + strbuff.length_, data, size);
		strbuff.length_ += size;
		strbuff.value[strbuff.length_] = '\0';

		return 0;
	}

pure nothrow @trusted @nogc @live
char strbuffer_pop(scope strbuffer_t* strbuff)

	in
	{
		assert(strbuff != null);
	}

	do
	{
		if (strbuff.length_ > 0) {
			char c = strbuff.value[--strbuff.length_];
			strbuff.value[strbuff.length_] = '\0';

			return c;
		} else {
			return '\0';
		}
	}
