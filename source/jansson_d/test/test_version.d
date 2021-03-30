/*
 * Copyright (c) 2019 Sean Bright <sean.bright@gmail.com>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.test.test_version;


private static import core.stdc.string;
private static import jansson_d.jansson;
private static import jansson_d.version_;

//test_version_str
unittest
{
	assert(!core.stdc.string.strcmp(jansson_d.version_.jansson_version_str(), jansson_d.jansson.JANSSON_VERSION), "jansson_version_str returned invalid version string");
}

//test_version_cmp
unittest
{
	assert(!jansson_d.version_.jansson_version_cmp(jansson_d.jansson.JANSSON_MAJOR_VERSION, jansson_d.jansson.JANSSON_MINOR_VERSION, jansson_d.jansson.JANSSON_MICRO_VERSION), "jansson_version_cmp equality check failed");

	assert(jansson_d.version_.jansson_version_cmp(jansson_d.jansson.JANSSON_MAJOR_VERSION - 1, 0, 0) > 0, "jansson_version_cmp less than check failed");

	if (jansson_d.jansson.JANSSON_MINOR_VERSION) {
		assert(jansson_d.version_.jansson_version_cmp(jansson_d.jansson.JANSSON_MAJOR_VERSION, jansson_d.jansson.JANSSON_MINOR_VERSION - 1, jansson_d.jansson.JANSSON_MICRO_VERSION) > 0, "jansson_version_cmp less than check failed");
	}

	if (jansson_d.jansson.JANSSON_MICRO_VERSION) {
		assert(jansson_d.version_.jansson_version_cmp(jansson_d.jansson.JANSSON_MAJOR_VERSION, jansson_d.jansson.JANSSON_MINOR_VERSION, jansson_d.jansson.JANSSON_MICRO_VERSION - 1) > 0, "jansson_version_cmp less than check failed");
	}

	assert(jansson_d.version_.jansson_version_cmp(jansson_d.jansson.JANSSON_MAJOR_VERSION + 1, jansson_d.jansson.JANSSON_MINOR_VERSION, jansson_d.jansson.JANSSON_MICRO_VERSION) < 0, "jansson_version_cmp greater than check failed");

	assert(jansson_d.version_.jansson_version_cmp(jansson_d.jansson.JANSSON_MAJOR_VERSION, jansson_d.jansson.JANSSON_MINOR_VERSION + 1, jansson_d.jansson.JANSSON_MICRO_VERSION) < 0, "jansson_version_cmp greater than check failed");

	assert(jansson_d.version_.jansson_version_cmp(jansson_d.jansson.JANSSON_MAJOR_VERSION, jansson_d.jansson.JANSSON_MINOR_VERSION, jansson_d.jansson.JANSSON_MICRO_VERSION + 1) < 0, "jansson_version_cmp greater than check failed");
}
