/**
 * License: MIT
 */
module jansson.test.test_chaos;


private static import core.memory;
private static import core.stdc.string;
private static import core.stdcpp.xutility;
private static import jansson.dump;
private static import jansson.jansson;
private static import jansson.jansson_private;
private static import jansson.load;
private static import jansson.memory;
private static import jansson.pack_unpack;
private static import jansson.test.util;
private static import jansson.value;

private __gshared int chaos_pos = 0;
private __gshared int chaos_fail = 0;
private enum CHAOS_MAX_FAILURE = 100;

extern (C)
nothrow @nogc
private void* chaos_malloc(size_t size)

	do
	{
		if (.chaos_pos == .chaos_fail) {
			return null;
		}

		.chaos_pos++;

		return core.memory.pureMalloc(size);
	}

extern (C)
nothrow @nogc
private void chaos_free(scope void* obj)

	do
	{
		if (obj != null) {
			core.memory.pureFree(obj);
		}
	}

/* Test all potential allocation failures. */
private template chaos_loop(string condition, string code, string cleanup)
{
	enum chaos_loop = "{ for (.chaos_fail = 0, .chaos_pos = 0; " ~ condition ~ "; .chaos_pos = 0, .chaos_fail++) { if (.chaos_fail > .CHAOS_MAX_FAILURE) assert(false, \"too many chaos failures\"); " ~ code ~" } " ~ cleanup ~" }";
}

private template chaos_loop_new_value(string json, string initcall)
{
	enum chaos_loop_new_value = "mixin (.chaos_loop!(\"!" ~ json ~ "\", \"" ~ json ~" = " ~ initcall~ ";\", \"jansson.jansson.json_decref(" ~ json ~ "); " ~ json ~" = null;\"));";
}

private int test_unpack()

	do
	{
		int ret = -1;
		jansson.jansson.json_error_t error = void;

		jansson.jansson.json_t* root = jansson.pack_unpack.json_pack("{s:i, s:i, s:i, s:i}", &("n1\0"[0]), 1, &("n2\0"[0]), 2, &("n3\0"[0]), 3, &("n4\0"[0]), 4);

		if (root == null) {
			return -1;
		}

		int v1 = void;
		int v2 = void;
		assert(jansson.pack_unpack.json_unpack_ex(root, &error, jansson.jansson.JSON_STRICT, "{s:i, s:i}", &("n1\0"[0]), &v1, &("n2\0"[0]), &v2), "Unexpected success");

		if (jansson.jansson.json_error_code(&error) != jansson.jansson.json_error_code_t.json_error_end_of_input_expected) {
			assert(jansson.jansson.json_error_code(&error) == jansson.jansson.json_error_code_t.json_error_out_of_memory, "Unexpected error code");

			goto out_;
		}

		if (core.stdc.string.strcmp(&(error.text[0]), "2 object item(s) left unpacked: n3, n4")) {
			goto out_;
		}

		ret = 0;

	out_:
		jansson.jansson.json_decref(root);

		return ret;
	}

extern (C)
nothrow @nogc
private int dump_chaos_callback(scope const char* buffer, size_t size, scope void* data)

	do
	{
		jansson.jansson.json_t* obj = jansson.value.json_object();

		if (obj == null) {
			return -1;
		}

		jansson.jansson.json_decref(obj);

		return 0;
	}

//test_chaos
unittest
{
	jansson.test.util.init_unittest();
	jansson.jansson.json_t* json = null;
	jansson.jansson.json_t* obj = jansson.value.json_object();
	jansson.jansson.json_t* arr1 = jansson.value.json_array();
	jansson.jansson.json_t* arr2 = jansson.value.json_array();
	jansson.jansson.json_t* txt = jansson.value.json_string("test");
	jansson.jansson.json_t* intnum = jansson.value.json_integer(1);
	jansson.jansson.json_t* dblnum = jansson.value.json_real(0.5);
	jansson.jansson.json_t* dumpobj = jansson.pack_unpack.json_pack("{s:[iiis], s:s}", &("key1\0"[0]), 1, 2, 3, &("txt\0"[0]), &("key2\0"[0]), &("v2\0"[0]));

	scope (exit) {
		jansson.jansson.json_decref(obj);
		jansson.jansson.json_decref(arr1);
		jansson.jansson.json_decref(arr2);
		jansson.jansson.json_decref(txt);
		jansson.jansson.json_decref(intnum);
		jansson.jansson.json_decref(dblnum);
		jansson.jansson.json_decref(dumpobj);
	}

	assert((obj != null) && (arr1 != null) && (arr2 != null) && (txt != null) && (intnum != null) && (dblnum != null) && (dumpobj != null), "failed to allocate basic objects");

	jansson.jansson.json_malloc_t orig_malloc = void;
	jansson.jansson.json_free_t orig_free = void;
	jansson.memory.json_get_alloc_funcs(&orig_malloc, &orig_free);
	jansson.memory.json_set_alloc_funcs(&.chaos_malloc, &.chaos_free);

	mixin (.chaos_loop_new_value!("json", "jansson.pack_unpack.json_pack(`{s:s}`, `key`.ptr, `value`.ptr)"));
	mixin (.chaos_loop_new_value!("json", "jansson.pack_unpack.json_pack(`{s:[]}`, `key`.ptr)"));
	mixin (.chaos_loop_new_value!("json", "jansson.pack_unpack.json_pack(`[biIf]`, 1, 1, cast(jansson.jansson.json_int_t)(1), 1.0)"));
	mixin (.chaos_loop_new_value!("json", "jansson.pack_unpack.json_pack(`[s*,s*]`, `v1`.ptr, `v2`.ptr)"));
	mixin (.chaos_loop_new_value!("json", "jansson.pack_unpack.json_pack(`o`, jansson.jansson.json_incref(txt))"));
	mixin (.chaos_loop_new_value!("json", "jansson.pack_unpack.json_pack(`O`, txt)"));
	mixin (.chaos_loop_new_value!("json", "jansson.pack_unpack.json_pack(`s++`, `a`.ptr, `long string to force realloc`.ptr, `another long string to force yet another reallocation of the string because that's what we are testing.`.ptr)"));

	mixin (.chaos_loop!(".test_unpack()", "", ""));

	mixin (.chaos_loop!("jansson.dump.json_dump_callback(dumpobj, &.dump_chaos_callback, null, mixin (jansson.jansson.JSON_INDENT!(`1`)))", "", ""));
	mixin (.chaos_loop!("jansson.dump.json_dump_callback(dumpobj, &.dump_chaos_callback, null, mixin (jansson.jansson.JSON_INDENT!(`1`)) | jansson.jansson.JSON_SORT_KEYS)", "", ""));

	{
		char* dumptxt = null;
		mixin (.chaos_loop!("dumptxt == null", "dumptxt = jansson.dump.json_dumps(dumpobj, jansson.jansson.JSON_COMPACT);", "jansson.jansson_private.jsonp_free(dumptxt); dumptxt = null;"));
	}

	mixin (.chaos_loop_new_value!("json", "jansson.value.json_copy(obj)"));
	mixin (.chaos_loop_new_value!("json", "jansson.value.json_deep_copy(obj)"));

	mixin (.chaos_loop_new_value!("json", "jansson.value.json_copy(arr1)"));
	mixin (.chaos_loop_new_value!("json", "jansson.value.json_deep_copy(arr1)"));

	mixin (.chaos_loop_new_value!("json", "jansson.value.json_copy(txt)"));
	mixin (.chaos_loop_new_value!("json", "jansson.value.json_copy(intnum)"));
	mixin (.chaos_loop_new_value!("json", "jansson.value.json_copy(dblnum)"));

	enum JSON_LOAD_TXT = "{\"n\":[1,2,3,4,5,6,7,8,9,10]}\0";
	mixin (.chaos_loop_new_value!("json", "jansson.load.json_loads(JSON_LOAD_TXT, 0, null)"));
	mixin (.chaos_loop_new_value!("json", "jansson.load.json_loadb(JSON_LOAD_TXT, core.stdc.string.strlen(JSON_LOAD_TXT), 0, null)"));

	mixin (.chaos_loop_new_value!("json", "jansson.value.json_sprintf(`%s`, `string`.ptr)"));

	for (size_t keyno = 0; keyno < 100; ++keyno) {
		static if ((!__traits(compiles, core.stdcpp.xutility._MSC_VER)) || (core.stdcpp.xutility._MSC_VER >= 1900)) {
			/* Skip this test on old Windows compilers. */
			char[10] testkey = void;

			jansson.jansson_private.snprintf(&(testkey[0]), testkey.length, "test%d", cast(int)(keyno));
			mixin (.chaos_loop!("jansson.value.json_object_set_new_nocheck(obj, &(testkey[0]), jansson.value.json_object())", "", ""));
		}

		mixin (.chaos_loop!("jansson.value.json_array_append_new(arr1, jansson.value.json_null())", "", ""));
		mixin (.chaos_loop!("jansson.value.json_array_insert_new(arr2, 0, jansson.value.json_null())", "", ""));
	}

	mixin (.chaos_loop!("jansson.value.json_array_extend(arr1, arr2)", "", ""));
	mixin (.chaos_loop!("jansson.value.json_string_set_nocheck(txt, `test`)", "", ""));

	jansson.memory.json_set_alloc_funcs(orig_malloc, orig_free);
}
