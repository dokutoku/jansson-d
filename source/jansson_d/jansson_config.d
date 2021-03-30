/*
 * Copyright (c) 2010-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 *
 *
 * This file specifies a part of the site-specific configuration for
 * Jansson, namely those things that affect the public API in
 * jansson.h.
 *
 * The configure script copies this file to jansson_config.h and
 * replaces @var@ substitutions by values that fit your system. If you
 * cannot run the configure script, you can do the value substitution
 * by hand.
 */
/**
 * License: MIT
 */
module jansson_d.jansson_config;


private static import core.stdc.config;
private static import core.stdc.locale;
private static import core.stdc.stdlib;

/*
 * If your compiler supports the inline keyword in C, JSON_INLINE is
 * defined to `inline', otherwise empty. In C++, the inline is always
 * supported.
 */
//#define JSON_INLINE inline

/**
 * If your compiler supports the `core.stdc.config.cpp_longlong` type and the core.stdc.stdlib.strtoll()
 * library function, JSON_INTEGER_IS_LONG_LONG is defined to true,
 * otherwise to false.
 */
enum JSON_INTEGER_IS_LONG_LONG = (__traits(compiles, core.stdc.config.cpp_longlong)) && (__traits(compiles, core.stdc.stdlib.strtoll));

/**
 * If locale.h and core.stdc.locale.localeconv() are available, define to true,
 * otherwise to false.
 */
enum JSON_HAVE_LOCALECONV = __traits(compiles, core.stdc.locale.localeconv);

/**
 * If __atomic builtins are available they will be used to manage
 * reference counts of json_t.
 */
enum JSON_HAVE_ATOMIC_BUILTINS = false;

/**
 * If __atomic builtins are not available we try using __sync builtins
 * to manage reference counts of json_t.
 */
enum JSON_HAVE_SYNC_BUILTINS = false;

/**
 * Maximum recursion depth for parsing JSON input.
 * This limits the depth of e.g. array-within-array constructions.
 */
enum JSON_PARSER_MAX_DEPTH = 2048;
