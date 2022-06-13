/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 * Copyright (c) 2011-2012 Basile Starynkevitch <basile@starynkevitch.net>
 *
 * Jansson is free software; you can redistribute it and/or modify it
 * under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.memory;


package:

private static import core.stdc.stdlib;
private static import core.stdc.string;
private static import jansson_d.jansson;

/* memory function pointers */
//private
__gshared jansson_d.jansson.json_malloc_t do_malloc = &core.stdc.stdlib.malloc;

//private
__gshared jansson_d.jansson.json_free_t do_free = &core.stdc.stdlib.free;

//nodiscard
nothrow @trusted @nogc
package void* jsonp_malloc(size_t size)

	do
	{
		if (size == 0) {
			return null;
		}

		return .do_malloc(size);
	}

nothrow @trusted @nogc
package void jsonp_free(scope void* ptr_)

	do
	{
		if (ptr_ == null) {
			return;
		}

		.do_free(ptr_);
	}

//nodiscard
nothrow @trusted @nogc
char* jsonp_strdup(scope const char* str)

	do
	{
		return .jsonp_strndup(str, core.stdc.string.strlen(str));
	}

//nodiscard
nothrow @trusted @nogc
char* jsonp_strndup(scope const char* str, size_t len)

	do
	{
		char* new_str = cast(char*)(.jsonp_malloc(len + 1));

		if (new_str == null) {
			return null;
		}

		core.stdc.string.memcpy(new_str, str, len);
		new_str[len] = '\0';

		return new_str;
	}

///
extern (C)
nothrow @trusted @nogc @live
public void json_set_alloc_funcs(jansson_d.jansson.json_malloc_t malloc_fn, jansson_d.jansson.json_free_t free_fn)

	do
	{
		.do_malloc = malloc_fn;
		.do_free = free_fn;
	}

///
extern (C)
nothrow @trusted @nogc @live
public void json_get_alloc_funcs(jansson_d.jansson.json_malloc_t* malloc_fn, jansson_d.jansson.json_free_t* free_fn)

	do
	{
		if (malloc_fn != null) {
			*malloc_fn = .do_malloc;
		}

		if (free_fn != null) {
			*free_fn = .do_free;
		}
	}
