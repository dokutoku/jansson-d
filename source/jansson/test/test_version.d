/*
 * Copyright (c) 2019 Sean Bright <sean.bright@gmail.com>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.test_version;


private static import core.stdc.string;
private static import jansson.jansson;
private static import jansson.test.util;
private static import jansson.version_;

//test_version_str
unittest
{
	jansson.test.util.init_unittest();
	assert(core.stdc.string.strcmp(jansson.version_.jansson_version_str(), jansson.jansson.JANSSON_VERSION) == 0, "jansson_version_str returned invalid version string");
}

//test_version_cmp
unittest
{
	jansson.test.util.init_unittest();
	assert(!jansson.version_.jansson_version_cmp(jansson.jansson.JANSSON_MAJOR_VERSION, jansson.jansson.JANSSON_MINOR_VERSION, jansson.jansson.JANSSON_MICRO_VERSION), "jansson_version_cmp equality check failed");

	assert(jansson.version_.jansson_version_cmp(jansson.jansson.JANSSON_MAJOR_VERSION - 1, 0, 0) > 0, "jansson_version_cmp less than check failed");

	if (jansson.jansson.JANSSON_MINOR_VERSION) {
		assert(jansson.version_.jansson_version_cmp(jansson.jansson.JANSSON_MAJOR_VERSION, jansson.jansson.JANSSON_MINOR_VERSION - 1, jansson.jansson.JANSSON_MICRO_VERSION) > 0, "jansson_version_cmp less than check failed");
	}

	if (jansson.jansson.JANSSON_MICRO_VERSION) {
		assert(jansson.version_.jansson_version_cmp(jansson.jansson.JANSSON_MAJOR_VERSION, jansson.jansson.JANSSON_MINOR_VERSION, jansson.jansson.JANSSON_MICRO_VERSION - 1) > 0, "jansson_version_cmp less than check failed");
	}

	assert(jansson.version_.jansson_version_cmp(jansson.jansson.JANSSON_MAJOR_VERSION + 1, jansson.jansson.JANSSON_MINOR_VERSION, jansson.jansson.JANSSON_MICRO_VERSION) < 0, "jansson_version_cmp greater than check failed");

	assert(jansson.version_.jansson_version_cmp(jansson.jansson.JANSSON_MAJOR_VERSION, jansson.jansson.JANSSON_MINOR_VERSION + 1, jansson.jansson.JANSSON_MICRO_VERSION) < 0, "jansson_version_cmp greater than check failed");

	assert(jansson.version_.jansson_version_cmp(jansson.jansson.JANSSON_MAJOR_VERSION, jansson.jansson.JANSSON_MINOR_VERSION, jansson.jansson.JANSSON_MICRO_VERSION + 1) < 0, "jansson_version_cmp greater than check failed");
}
