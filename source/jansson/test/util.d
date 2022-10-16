/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson.test.util;


private static import core.stdc.stdio;
private static import core.stdc.stdlib;
private static import core.stdc.string;
private static import jansson.hashtable_seed;
private static import jansson.jansson;
private static import jansson.memory;

//#define failhdr core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "%s:%d: ", __FILE__, __LINE__)

//#define fail(msg) do { failhdr; core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "%s\n", msg); core.stdc.stdlib.exit(1); } while (0)

nothrow @nogc @live
package void check_errors(scope const ref jansson.jansson.json_error_t error, jansson.jansson.json_error_code_t code_, scope immutable (char)* texts_, size_t num_, scope immutable (char)* source_, int line_, int column_, int position_)

	do
	{
		if (jansson.jansson.json_error_code(&error) != code_) {
			//failhdr;
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "code: %d != %d\n", jansson.jansson.json_error_code(&error), code_);
			assert(false);
		}

		bool found_ = false;

		for (size_t i_ = 0; i_ < num_; i_++) {
			if (core.stdc.string.strcmp(&(error.text[0]), &(texts_[i_])) == 0) {
				found_ = true;

				break;
			}
		}

		if (!found_) {
			//failhdr;

			if (num_ == 1) {
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "text: \"%s\" != \"%s\"\n", &(error.text[0]), &(texts_[0]));
			} else {
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "text: \"%s\" does not match\n", &(error.text[0]));
			}

			assert(false);
		}

		if (core.stdc.string.strcmp(&(error.source[0]), source_) != 0) {
			//failhdr;
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "source: \"%s\" != \"%s\"\n", &(error.source[0]), source_);
			assert(false);
		}

		if (error.line != line_) {
			//failhdr;
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "line: %d != %d\n", error.line, line_);
			assert(false);
		}

		if (error.column != column_) {
			//failhdr;
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "column: %d != %d\n", error.column, column_);
			assert(false);
		}

		if (error.position != position_) {
			//failhdr;
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "position: %d != %d\n", error.position, position_);
			assert(false);
		}
	}

nothrow @nogc @live
package void check_error(scope const ref jansson.jansson.json_error_t error, jansson.jansson.json_error_code_t code_, scope immutable (char)* text_, scope immutable (char)* source_, int line_, int column_, int position_)

	do
	{
		.check_errors(error, code_, text_, 1, source_, line_, column_, position_);
	}

nothrow @nogc @live
package void init_unittest()

	do
	{
		jansson.hashtable_seed.hashtable_seed = 0;

		static if ((__traits(compiles, __atomic_test_and_set)) && (__traits(compiles, __ATOMIC_RELAXED)) && (__traits(compiles, __atomic_store_n)) && (__traits(compiles, __ATOMIC_RELEASE)) && (__traits(compiles, __atomic_load_n)) && (__traits(compiles, __ATOMIC_ACQUIRE))) {
			jansson.hashtable_seed.seed_initialized = 0;
		} else version (Win32) {
			jansson.hashtable_seed.seed_initialized = 0;
		}

		jansson.memory.do_malloc = &core.stdc.stdlib.malloc;
		jansson.memory.do_free = &core.stdc.stdlib.free;
	}
