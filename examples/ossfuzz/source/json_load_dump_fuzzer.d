/**
 * License: MIT
 */
module ossfuzz.json_load_dump_fuzzer;


private static import core.memory;
private static import core.stdc.stdio;
private static import core.stdc.stdlib;
private static import jansson.jansson;
private static import jansson.jansson_private;

private __gshared bool enable_diags;

pragma(inline, true)
nothrow @nogc @live
void FUZZ_DEBUG(F ...)(immutable char* fmt, F f)

	do
	{
		if (.enable_diags) {
			static if (f.length != 0) {
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, fmt, f[0 .. $]);
			} else {
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, fmt, f[0]);
			}

			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "\n");
		}
	}

extern (C)
pure nothrow @trusted @nogc @live
private int json_dump_counter(scope const char* buffer, size_t size, scope void* data)

	do
	{
		ulong* counter = cast(ulong*)(data);
		*counter += size;

		return 0;
	}

private enum NUM_COMMAND_BYTES = size_t.sizeof + size_t.sizeof + 1;

private enum FUZZ_DUMP_CALLBACK = 0x00;
private enum FUZZ_DUMP_STRING = 0x01;

extern (C)
int LLVMFuzzerTestOneInput(scope const ubyte* data, size_t size)

	do
	{
		// Enable or disable diagnostics based on the FUZZ_VERBOSE environment flag.
		.enable_diags = core.stdc.stdlib.getenv("FUZZ_VERBOSE") != null;

		.FUZZ_DEBUG("Input data length: %zd", size);

		if (size < .NUM_COMMAND_BYTES) {
			return 0;
		}

		const (ubyte)* data_temp = cast(const (ubyte)*)(data);

		// Use the first size_t.sizeof bytes as load flags.
		size_t load_flags = *(cast(const size_t*)(data_temp));
		data_temp += size_t.sizeof;

		.FUZZ_DEBUG("load_flags: 0x%zx\n& JSON_REJECT_DUPLICATES =  0x%zx\n& JSON_DECODE_ANY =         0x%zx\n& JSON_DISABLE_EOF_CHECK =  0x%zx\n& JSON_DECODE_INT_AS_REAL = 0x%zx\n& JSON_ALLOW_NUL =          0x%zx\n", load_flags, load_flags & jansson.jansson.JSON_REJECT_DUPLICATES, load_flags & jansson.jansson.JSON_DECODE_ANY, load_flags & jansson.jansson.JSON_DISABLE_EOF_CHECK, load_flags & jansson.jansson.JSON_DECODE_INT_AS_REAL, load_flags & jansson.jansson.JSON_ALLOW_NUL);

		// Use the next size_t.sizeof bytes as dump flags.
		size_t dump_flags = *(cast(const size_t*)(data_temp));
		data_temp += size_t.sizeof;

		.FUZZ_DEBUG("dump_flags: 0x%zx\n& JSON_MAX_INDENT =     0x%zx\n& JSON_COMPACT =        0x%zx\n& JSON_ENSURE_ASCII =   0x%zx\n& JSON_SORT_KEYS =      0x%zx\n& JSON_PRESERVE_ORDER = 0x%zx\n& JSON_ENCODE_ANY =     0x%zx\n& JSON_ESCAPE_SLASH =   0x%zx\n& JSON_REAL_PRECISION = 0x%zx\n& JSON_EMBED =          0x%zx\n", dump_flags, dump_flags & jansson.jansson.JSON_MAX_INDENT, dump_flags & jansson.jansson.JSON_COMPACT, dump_flags & jansson.jansson.JSON_ENSURE_ASCII, dump_flags & jansson.jansson.JSON_SORT_KEYS, dump_flags & jansson.jansson.JSON_PRESERVE_ORDER, dump_flags & jansson.jansson.JSON_ENCODE_ANY, dump_flags & jansson.jansson.JSON_ESCAPE_SLASH, ((dump_flags >> 11) & 0x1F) << 11, dump_flags & jansson.jansson.JSON_EMBED);

		// Use the next byte as the dump mode.
		ubyte dump_mode = data_temp[0];
		data_temp++;

		.FUZZ_DEBUG("dump_mode: 0x%x", cast(uint)(dump_mode));

		// Remove the command bytes from the size total.
		size -= .NUM_COMMAND_BYTES;

		// Attempt to load the remainder of the data with the given load flags.
		const char* text = cast(const char*)(data_temp);
		jansson.jansson.json_error_t error = void;
		jansson.jansson.json_t* jobj = jansson.jansson.json_loadb(text, size, load_flags, &error);

		if (jobj == null) {
			return 0;
		}

		scope (exit) {
			jansson.jansson.json_decref(jobj);
		}

		if (dump_mode & .FUZZ_DUMP_STRING) {
			// Dump as a string. Remove indents so that we don't run out of memory.
			char* out_ = jansson.jansson.json_dumps(jobj, dump_flags & ~jansson.jansson.JSON_MAX_INDENT);

			if (out_ != null) {
				jansson.jansson.json_free_t free_func;
				jansson.jansson.json_get_alloc_funcs(null, &free_func);
				free_func(out_);
			}
		} else {
			// Default is callback mode.
			//
			// Attempt to dump the loaded json object with the given dump flags.
			ulong counter = 0;

			jansson.jansson.json_dump_callback(jobj, &.json_dump_counter, &counter, dump_flags);
			.FUZZ_DEBUG("Counter function counted %llu bytes.", counter);
		}

		return 0;
	}
