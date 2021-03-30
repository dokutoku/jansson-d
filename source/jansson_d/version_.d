/*
 * Copyright (c) 2019 Sean Bright <sean.bright@gmail.com>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.version_;


package:

private static import jansson_d.jansson;

///
extern (C)
pure nothrow @safe @nogc @live
public immutable (char)* jansson_version_str()

	do
	{
		return jansson_d.jansson.JANSSON_VERSION;
	}

///
extern (C)
pure nothrow @safe @nogc @live
public int jansson_version_cmp(int major, int minor, int micro)

	do
	{
		int diff = jansson_d.jansson.JANSSON_MAJOR_VERSION - major;

		if (diff) {
			return diff;
		}

		diff = jansson_d.jansson.JANSSON_MINOR_VERSION - minor;

		if (diff) {
			return diff;
		}

		return jansson_d.jansson.JANSSON_MICRO_VERSION - micro;
	}
