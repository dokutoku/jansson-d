/**
 * License: MIT
 */
module jansson.test.test_sprintf;


private static import core.stdc.string;
private static import jansson.jansson;
private static import jansson.test.util;
private static import jansson.value;

//test_sprintf
unittest
{
	jansson.test.util.init_unittest();

	{
		jansson.jansson.json_t* s = jansson.value.json_sprintf("foo bar %d", 42);

		scope (exit) {
			jansson.jansson.json_decref(s);
		}

		assert(s != null, "json_sprintf returned null");

		assert(mixin (jansson.jansson.json_is_string!("s")), "json_sprintf didn't return a JSON string");

		assert(core.stdc.string.strcmp(jansson.value.json_string_value(s), "foo bar 42") == 0, "json_sprintf generated an unexpected string");
	}

	{
		jansson.jansson.json_t* s = jansson.value.json_sprintf("%s", &("\0"[0]));

		scope (exit) {
			jansson.jansson.json_decref(s);
		}

		assert(s != null, "json_sprintf returned null");

		assert(mixin (jansson.jansson.json_is_string!("s")), "json_sprintf didn't return a JSON string");

		assert(jansson.value.json_string_length(s) == 0, "string is not empty");
	}

	assert(jansson.value.json_sprintf("%s", &("\xff\xff\0"[0])) == null, "json_sprintf unexpected success with invalid UTF");
}
