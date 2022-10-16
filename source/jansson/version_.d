/*
 * Copyright (c) 2019 Sean Bright <sean.bright@gmail.com>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.version_;


package:

private static import jansson.jansson;

///
extern (C)
pure nothrow @safe @nogc @live
public immutable (char)* jansson_version_str()

	do
	{
		return jansson.jansson.JANSSON_VERSION;
	}

///
extern (C)
pure nothrow @safe @nogc @live
public int jansson_version_cmp(int major, int minor, int micro)

	do
	{
		int diff = jansson.jansson.JANSSON_MAJOR_VERSION - major;

		if (diff) {
			return diff;
		}

		diff = jansson.jansson.JANSSON_MINOR_VERSION - minor;

		if (diff) {
			return diff;
		}

		return jansson.jansson.JANSSON_MICRO_VERSION - micro;
	}
