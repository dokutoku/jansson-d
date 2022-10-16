/**
 * License: MIT
 */
module jansson_d.test.test_sprintf;


private static import core.stdc.string;
private static import jansson_d.jansson;
private static import jansson_d.test.util;
private static import jansson_d.value;

//test_sprintf
unittest
{
	jansson_d.test.util.init_unittest();

	{
		jansson_d.jansson.json_t* s = jansson_d.value.json_sprintf("foo bar %d", 42);

		scope (exit) {
			jansson_d.jansson.json_decref(s);
		}

		assert(s != null, "json_sprintf returned null");

		assert(mixin (jansson_d.jansson.json_is_string!("s")), "json_sprintf didn't return a JSON string");

		assert(!core.stdc.string.strcmp(jansson_d.value.json_string_value(s), "foo bar 42"), "json_sprintf generated an unexpected string");
	}

	{
		jansson_d.jansson.json_t* s = jansson_d.value.json_sprintf("%s", &("\0"[0]));

		scope (exit) {
			jansson_d.jansson.json_decref(s);
		}

		assert(s != null, "json_sprintf returned null");

		assert(mixin (jansson_d.jansson.json_is_string!("s")), "json_sprintf didn't return a JSON string");

		assert(jansson_d.value.json_string_length(s) == 0, "string is not empty");
	}

	assert(jansson_d.value.json_sprintf("%s", &("\xff\xff\0"[0])) == null, "json_sprintf unexpected success with invalid UTF");
}
