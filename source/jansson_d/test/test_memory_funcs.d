/**
 * License: MIT
 */
module jansson_d.test.test_memory_funcs;


private static import core.memory;
private static import core.stdc.string;
private static import jansson_d.jansson;
private static import jansson_d.jansson_private;
private static import jansson_d.memory;
private static import jansson_d.pack_unpack;
private static import jansson_d.value;

private __gshared int malloc_called = 0;
private __gshared int free_called = 0;
private __gshared size_t malloc_used = 0;

/* helpers */
nothrow @nogc @live
private void create_and_free_complex_object()

	do
	{
		jansson_d.jansson.json_t* obj = jansson_d.pack_unpack.json_pack("{s:i,s:n,s:b,s:b,s:{s:s},s:[i,i,i]}", &("foo\0"[0]), 42, &("bar\0"[0]), &("baz\0"[0]), 1, &("qux\0"[0]), 0, &("alice\0"[0]), &("bar\0"[0]), &("baz\0"[0]), &("bob\0"[0]), 9, 8, 7);

		jansson_d.jansson.json_decref(obj);
	}

nothrow @nogc
private void create_and_free_object_with_oom()

	do
	{
		jansson_d.jansson.json_t* obj = jansson_d.value.json_object();

		char[4] key = void;

		for (size_t i = 0; i < 10; i++) {
			jansson_d.jansson_private.snprintf(&(key[0]), key.length, &("%d\0"[0]), i);
			jansson_d.value.json_object_set_new(obj, &(key[0]), jansson_d.value.json_integer(i));
		}

		jansson_d.jansson.json_decref(obj);
	}

extern (C)
nothrow @nogc
private void* my_malloc(size_t size)

	do
	{
		.malloc_called = 1;

		return core.memory.pureMalloc(size);
	}

extern (C)
nothrow @nogc
private void my_free(scope void* ptr_)

	do
	{
		.free_called = 1;
		core.memory.pureFree(ptr_);
	}

//test_simple
unittest
{
	jansson_d.jansson.json_malloc_t mfunc = null;
	jansson_d.jansson.json_free_t ffunc = null;

	jansson_d.memory.json_set_alloc_funcs(&.my_malloc, &.my_free);
	jansson_d.memory.json_get_alloc_funcs(&mfunc, &ffunc);
	.create_and_free_complex_object();

	assert((.malloc_called == 1) && (.free_called == 1) && (mfunc == &.my_malloc) && (ffunc == &.my_free), "Custom allocation failed");
}

extern (C)
nothrow @nogc
private void* oom_malloc(size_t size)

	do
	{
		if ((.malloc_used + size) > 800) {
			return null;
		}

		.malloc_used += size;

		return core.memory.pureMalloc(size);
	}

extern (C)
nothrow @nogc
private void oom_free(scope void* ptr_)

	do
	{
		.free_called++;
		core.memory.pureFree(ptr_);
	}

//test_oom
unittest
{
	.free_called = 0;
	jansson_d.memory.json_set_alloc_funcs(&.oom_malloc, &.oom_free);
	.create_and_free_object_with_oom();

	assert(.free_called != 0, "Allocation with OOM failed");
}

/*
 * Test the secure memory functions code given in the API reference
 * documentation, but by using plain memset instead of
 * guaranteed_memset().
 */

extern (C)
pure nothrow @nogc
private void* secure_malloc(size_t size)

	do
	{
		/* Store the memory area size in the beginning of the block */
		void* ptr_ = core.memory.pureMalloc(size + 8);
		*(cast(size_t*)(ptr_)) = size;

		return cast(char*)(ptr_) + 8;
	}

extern (C)
pure nothrow @nogc
private void secure_free(scope void* ptr_)

	do
	{
		ptr_ = cast(char*)(ptr_) - 8;
		size_t size = *(cast(size_t*)(ptr_));

		/* guaranteed_ */
		core.stdc.string.memset(ptr_, 0, size + 8);

		core.memory.pureFree(ptr_);
	}

//test_secure_funcs
unittest
{
	jansson_d.memory.json_set_alloc_funcs(&.secure_malloc, &.secure_free);
	.create_and_free_complex_object();
}

//test_bad_args
unittest
{
	/* The result of this test is not crashing. */
	jansson_d.memory.json_get_alloc_funcs(null, null);
}
