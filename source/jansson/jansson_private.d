/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.jansson_private;


package:

private static import core.stdc.stdarg;
private static import core.stdc.stdio;
private static import core.stdc.string;
private static import core.stdcpp.xutility;
private static import jansson.error;
private static import jansson.hashtable;
private static import jansson.jansson;
private static import jansson.memory;
private static import jansson.strconv;
private static import jansson.value;

package template container_of(string ptr_, string type_, string member_)
{
	enum container_of = "(cast(" ~ type_ ~ "*)(cast(char*)(" ~ ptr_ ~ ") - " ~ type_ ~ "." ~ member_ ~ ".offsetof))";
}

/* On some platforms, max() may already be defined */
package template max(string a, string b)
{
	enum max = "(( " ~ a ~ ") > (" ~ b ~ ") ? (" ~ a ~ ") : (" ~ b ~ "))";
}

/*
 * va_copy is a C99 feature. In C89 implementations, it's sometimes
 * available as __va_copy. If not, memcpy() should do the trick.
 */
static if (__traits(compiles, core.stdc.stdarg.va_copy)) {
	alias va_copy = core.stdc.stdarg.va_copy;
} else {
	void va_copy(A, B)(A a, B b)

		do
		{
			core.stdc.string.memcpy(&a, &b, core.stdc.stdarg.va_list.sizeof);
		}
}

struct json_object_t
{
	jansson.jansson.json_t json;
	jansson.hashtable.hashtable_t hashtable;
}

struct json_array_t
{
	jansson.jansson.json_t json;
	size_t size;
	size_t entries;
	jansson.jansson.json_t** table;
}

struct json_string_t
{
	jansson.jansson.json_t json;
	char* value;
	size_t length_;

	@disable
	alias length = length_;
}

struct json_real_t
{
	jansson.jansson.json_t json;
	double value = 0;
}

struct json_integer_t
{
	jansson.jansson.json_t json;
	jansson.jansson.json_int_t value;
}

template json_to_object(string json_)
{
	enum json_to_object = jansson.jansson_private.container_of!(json_, "jansson.jansson_private.json_object_t", "json");
}

template json_to_array(string json_)
{
	enum json_to_array = jansson.jansson_private.container_of!(json_, "jansson.jansson_private.json_array_t", "json");
}

template json_to_string(string json_)
{
	enum json_to_string = jansson.jansson_private.container_of!(json_, "jansson.jansson_private.json_string_t", "json");
}

template json_to_real(string json_)
{
	enum json_to_real = jansson.jansson_private.container_of!(json_, "jansson.jansson_private.json_real_t", "json");
}

template json_to_integer(string json_)
{
	enum json_to_integer = jansson.jansson_private.container_of!(json_, "jansson.jansson_private.json_integer_t", "json");
}

/* Create a string by taking ownership of an existing buffer */
alias jsonp_stringn_nocheck_own = jansson.value.jsonp_stringn_nocheck_own;

/* Error message formatting */
alias jsonp_error_init = jansson.error.jsonp_error_init;
alias jsonp_error_set_source = jansson.error.jsonp_error_set_source;
alias jsonp_error_set = jansson.error.jsonp_error_set;
alias jsonp_error_vset = jansson.error.jsonp_error_vset;

/* Locale independent string<.double conversions */
alias jsonp_strtod = jansson.strconv.jsonp_strtod;
alias jsonp_dtostr = jansson.strconv.jsonp_dtostr;

/* Wrappers for custom memory functions */
public alias jsonp_malloc = jansson.memory.jsonp_malloc;
public alias jsonp_free = jansson.memory.jsonp_free;

alias jsonp_strndup = jansson.memory.jsonp_strndup;

alias jsonp_strdup = jansson.memory.jsonp_strdup;

/* Circular reference check*/
/* Space for "0x", double the sizeof a pointer for the hex and a terminator. */
enum LOOP_KEY_LEN = 2 + ((jansson.jansson.json_t*).sizeof * 2) + 1;
alias jsonp_loop_check = jansson.value.jsonp_loop_check;

/* Windows compatibility */
version (Windows) {
	static if (__traits(compiles, core.stdcpp.xutility._MSC_VER)) {
		/* MS compiller */

		static if ((core.stdcpp.xutility._MSC_VER < 1900) && (!__traits(compiles, core.stdc.stdio.snprintf))) {
			alias snprintf = core.stdc.stdio._snprintf;
		} else {
			alias snprintf = core.stdc.stdio.snprintf;
		}

		static if ((core.stdcpp.xutility._MSC_VER < 1500) && (!__traits(compiles, core.stdc.stdio.vsnprintf))) {
			alias vsnprintf = core.stdc.stdio._vsnprintf;
		} else {
			alias vsnprintf = core.stdc.stdio.vsnprintf;
		}
	} else {
		/* Other Windows compiller, old definition */
		alias snprintf = core.stdc.stdio._snprintf;
		alias vsnprintf = core.stdc.stdio._vsnprintf;
	}
} else {
	alias snprintf = core.stdc.stdio.snprintf;
	alias vsnprintf = core.stdc.stdio.vsnprintf;
}

