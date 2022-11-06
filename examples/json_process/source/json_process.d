/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */


private static import core.memory;
private static import core.stdc.config;
private static import core.stdc.locale;
private static import core.stdc.stdio;
private static import core.stdc.stdlib;
private static import core.stdc.string;
private static import jansson.hashtable_seed;
private static import jansson.jansson;
private static import jansson.jansson_private;
private static import std.string;

version (Windows) {
	version (CRuntime_Microsoft) {
		extern (C)
		nothrow @nogc
		int _fileno(core.stdc.stdio.FILE*);
	} else {
		static assert(false, "Microsoft C runtime is required to build this program.");
	}

	static const char dir_sep = '\\';
} else {
	static const char dir_sep = '/';
}

struct config
{
	int indent;
	int compact;
	int preserve_order;
	int ensure_ascii;
	int sort_keys;
	int strip;
	int use_env;
	int have_hashseed;
	int hashseed;
	int precision;
}

__gshared .config conf;

template l_isspace(string c)
{
	enum l_isspace = "(((" ~ c ~ ") == ' ') || ((" ~ c ~ ") == '\\n') || ((" ~ c ~ ") == '\\r') || ((" ~ c ~ ") == '\\t'))";
}

/*
 * Return a pointer to the first non-whitespace character of str.
 * Modifies str so that all trailing whitespace characters are
 * replaced by '\0'.
 */
pure nothrow @trusted @nogc @live
private const (char)* strip(return scope char* str)

	in
	{
		assert(str != null);
	}

	do
	{
		char* result = str;

		for (; (*result != '\0') && (mixin (l_isspace!("*result"))); result++) {
		}

		size_t length_ = core.stdc.string.strlen(result);

		if (length_ == 0) {
			return result;
		}

		while (mixin (l_isspace!("result[length_ - 1]"))) {
			result[--length_] = '\0';
		}

		return result;
	}

nothrow @nogc
private char* loadfile(core.stdc.stdio.FILE* file)

	in
	{
		assert(file != null);
	}

	do
	{
		core.stdc.stdio.fseek(file, 0, core.stdc.stdio.SEEK_END);
		size_t fsize = core.stdc.stdio.ftell(file);
		core.stdc.stdio.fseek(file, 0, core.stdc.stdio.SEEK_SET);

		char* buf = cast(char*)(core.memory.pureMalloc(fsize + 1));
		size_t ret = core.stdc.stdio.fread(buf, 1, fsize, file);

		if (ret != fsize) {
			core.stdc.stdlib.exit(1);
		}

		buf[fsize] = '\0';

		return buf;
	}

nothrow @nogc @live
private void read_conf(core.stdc.stdio.FILE* conffile)

	in
	{
		assert(conffile != null);
	}

	do
	{
		char* buffer = .loadfile(conffile);

		scope (exit) {
			core.memory.pureFree(buffer);
		}

		for (char* line = core.stdc.string.strtok(buffer, "\r\n"); line != null; line = core.stdc.string.strtok(null, "\r\n")) {
			if (!core.stdc.string.strncmp(line, "export ", 7)) {
				continue;
			}

			char* val = core.stdc.string.strchr(line, '=');

			if (val == null) {
				core.stdc.stdio.printf("invalid configuration line\n");

				break;
			}

			*val++ = '\0';

			if (!core.stdc.string.strcmp(line, "JSON_INDENT")) {
				.conf.indent = core.stdc.stdlib.atoi(val);
			}

			if (!core.stdc.string.strcmp(line, "JSON_COMPACT")) {
				.conf.compact = core.stdc.stdlib.atoi(val);
			}

			if (!core.stdc.string.strcmp(line, "JSON_ENSURE_ASCII")) {
				.conf.ensure_ascii = core.stdc.stdlib.atoi(val);
			}

			if (!core.stdc.string.strcmp(line, "JSON_PRESERVE_ORDER")) {
				.conf.preserve_order = core.stdc.stdlib.atoi(val);
			}

			if (!core.stdc.string.strcmp(line, "JSON_SORT_KEYS")) {
				.conf.sort_keys = core.stdc.stdlib.atoi(val);
			}

			if (!core.stdc.string.strcmp(line, "JSON_REAL_PRECISION")) {
				.conf.precision = core.stdc.stdlib.atoi(val);
			}

			if (!core.stdc.string.strcmp(line, "STRIP")) {
				.conf.strip = core.stdc.stdlib.atoi(val);
			}

			if (!core.stdc.string.strcmp(line, "HASHSEED")) {
				.conf.have_hashseed = 1;
				.conf.hashseed = core.stdc.stdlib.atoi(val);
			} else {
				.conf.have_hashseed = 0;
			}
		}
	}

nothrow @nogc @live
private int cmpfile(scope const char* str, scope const char* path, scope const char* fname)

	do
	{
		char[1024] filename = void;
		core.stdc.stdio.sprintf(&(filename[0]), "%s%c%s", path, .dir_sep, fname);
		core.stdc.stdio.FILE* file = core.stdc.stdio.fopen(&(filename[0]), "rb");

		if (file == null) {
			if (.conf.strip) {
				core.stdc.string.strcat(&(filename[0]), ".strip");
			} else {
				core.stdc.string.strcat(&(filename[0]), ".normal");
			}

			file = core.stdc.stdio.fopen(&(filename[0]), "rb");
		}

		if (file == null) {
			core.stdc.stdio.printf("Error: test result file could not be opened.\n");
			core.stdc.stdlib.exit(1);
		}

		scope (exit) {
			core.stdc.stdio.fclose(file);
		}

		char* buffer = .loadfile(file);

		scope (exit) {
			core.memory.pureFree(buffer);
		}

		int ret = void;

		if (core.stdc.string.strcmp(buffer, str) != 0) {
			ret = 1;
		} else {
			ret = 0;
		}

		return ret;
	}

nothrow @nogc @live
int use_conf(scope const char* test_path)

	do
	{
		char[1024] filename = void;
		core.stdc.stdio.sprintf(&(filename[0]), "%s%cinput", test_path, .dir_sep);

		core.stdc.stdio.FILE* infile = core.stdc.stdio.fopen(&(filename[0]), "rb");

		if (infile == null) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "Could not open \"%s\"\n", &(filename[0]));

			return 2;
		}

		core.stdc.stdio.sprintf(&(filename[0]), "%s%cenv", test_path, .dir_sep);
		core.stdc.stdio.FILE* conffile = core.stdc.stdio.fopen(&(filename[0]), "rb");

		if (conffile != null) {
			.read_conf(conffile);
			core.stdc.stdio.fclose(conffile);
		}

		if ((.conf.indent < 0) || (.conf.indent > 31)) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "invalid value for JSON_INDENT: %d\n", .conf.indent);
			core.stdc.stdio.fclose(infile);

			return 2;
		}

		size_t flags = 0;

		if (.conf.indent) {
			flags |= mixin (jansson.jansson.JSON_INDENT!("conf.indent"));
		}

		if (.conf.compact) {
			flags |= jansson.jansson.JSON_COMPACT;
		}

		if (.conf.ensure_ascii) {
			flags |= jansson.jansson.JSON_ENSURE_ASCII;
		}

		if (.conf.preserve_order) {
			flags |= jansson.jansson.JSON_PRESERVE_ORDER;
		}

		if (.conf.sort_keys) {
			flags |= jansson.jansson.JSON_SORT_KEYS;
		}

		if ((.conf.precision < 0) || (.conf.precision > 31)) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "invalid value for JSON_REAL_PRECISION: %d\n", .conf.precision);
			core.stdc.stdio.fclose(infile);

			return 2;
		}

		if (.conf.precision) {
			flags |= mixin (jansson.jansson.JSON_REAL_PRECISION!("conf.precision"));
		}

		if (.conf.have_hashseed) {
			jansson.hashtable_seed.json_object_seed(.conf.hashseed);
		}

		jansson.jansson.json_t* json = void;
		char* buffer = void;
		jansson.jansson.json_error_t error = void;

		if (.conf.strip) {
			/* Load to memory, strip leading and trailing whitespace */
			buffer = .loadfile(infile);

			scope (exit) {
				core.memory.pureFree(buffer);
			}

			json = jansson.jansson.json_loads(.strip(buffer), 0, &error);
		} else {
			json = jansson.jansson.json_loadf(infile, 0, &error);
		}

		core.stdc.stdio.fclose(infile);

		int ret = void;

		if (json == null) {
			char[1024] errstr = void;
			core.stdc.stdio.sprintf(&(errstr[0]), "%d %d %d\n%s\n", error.line, error.column, error.position, &(error.text[0]));

			ret = .cmpfile(&(errstr[0]), test_path, "error");

			return ret;
		}

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		buffer = jansson.jansson.json_dumps(json, flags);

		scope (exit) {
			if (buffer != null) {
				jansson.jansson.json_free_t free_func;
				jansson.jansson.json_get_alloc_funcs(null, &free_func);
				free_func(buffer);
			}
		}

		ret = .cmpfile(buffer, test_path, "output");

		return ret;
	}

nothrow @nogc @live
private int getenv_int(scope const char* name)

	do
	{
		char* value = core.stdc.stdlib.getenv(name);

		if (value == null) {
			return 0;
		}

		char* end = null;
		core.stdc.config.c_long result = core.stdc.stdlib.strtol(value, &end, 10);

		if (*end != '\0') {
			return 0;
		}

		return cast(int)(result);
	}

nothrow @nogc @live
int use_env()

	do
	{
		version (Windows) {
			/*
			 * On Windows, set stdout and stderr to binary mode to avoid
			 * outputting DOS line terminators
			 */
			core.stdc.stdio._setmode(._fileno(core.stdc.stdio.stdout), core.stdc.stdio._O_BINARY);
			core.stdc.stdio._setmode(._fileno(core.stdc.stdio.stderr), core.stdc.stdio._O_BINARY);
		}

		int indent = .getenv_int("JSON_INDENT");

		if ((indent < 0) || (indent > 31)) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "invalid value for JSON_INDENT: %d\n", indent);

			return 2;
		}

		size_t flags = 0;

		if (indent > 0) {
			flags |= mixin (jansson.jansson.JSON_INDENT!("indent"));
		}

		if (.getenv_int("JSON_COMPACT") > 0) {
			flags |= jansson.jansson.JSON_COMPACT;
		}

		if (.getenv_int("JSON_ENSURE_ASCII")) {
			flags |= jansson.jansson.JSON_ENSURE_ASCII;
		}

		if (.getenv_int("JSON_PRESERVE_ORDER")) {
			flags |= jansson.jansson.JSON_PRESERVE_ORDER;
		}

		if (.getenv_int("JSON_SORT_KEYS")) {
			flags |= jansson.jansson.JSON_SORT_KEYS;
		}

		int precision = .getenv_int("JSON_REAL_PRECISION");

		if ((precision < 0) || (precision > 31)) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "invalid value for JSON_REAL_PRECISION: %d\n", precision);

			return 2;
		}

		if (core.stdc.stdlib.getenv("HASHSEED")) {
			jansson.hashtable_seed.json_object_seed(.getenv_int("HASHSEED"));
		}

		if (precision > 0) {
			flags |= mixin (jansson.jansson.JSON_REAL_PRECISION!("precision"));
		}

		jansson.jansson.json_t* json = void;
		jansson.jansson.json_error_t error = void;

		if (.getenv_int("STRIP")) {
			/* Load to memory, strip leading and trailing whitespace */

			char* buffer = null;
			
			scope (exit) {
				core.memory.pureFree(buffer);
			}

			for (size_t size = 128, used = 0; true; used += count, size = size * 2) {
				char* buf_ck = cast(char*)(core.memory.pureRealloc(buffer, size));

				if (buf_ck == null) {
					core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "Unable to allocate %d bytes\n", cast(int)(size));

					return 1;
				}

				buffer = buf_ck;

				size_t count = core.stdc.stdio.fread(buffer + used, 1, size - used, core.stdc.stdio.stdin);

				if (count < (size - used)) {
					buffer[used + count] = '\0';

					break;
				}
			}

			json = jansson.jansson.json_loads(.strip(buffer), 0, &error);
		} else {
			json = jansson.jansson.json_loadf(core.stdc.stdio.stdin, 0, &error);
		}

		if (json == null) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "%d %d %d\n%s\n", error.line, error.column, error.position, &(error.text[0]));

			return 1;
		}

		scope (exit) {
			jansson.jansson.json_decref(json);
		}

		jansson.jansson.json_dumpf(json, core.stdc.stdio.stdout, flags);

		return 0;
	}

int main(string[] argv)

	do
	{
		core.stdc.locale.setlocale(core.stdc.locale.LC_ALL, "\0");

		const (char)* test_path = null;

		if (argv.length < 2) {
			goto usage_;
		}

		for (int i = 1; i < argv.length; i++) {
			if (!core.stdc.string.strcmp(std.string.toStringz(argv[i]), "--strip")) {
				.conf.strip = 1;
			} else if (!core.stdc.string.strcmp(std.string.toStringz(argv[i]), "--env")) {
				.conf.use_env = 1;
			} else {
				test_path = std.string.toStringz(argv[i]);
			}
		}

		if (.conf.use_env) {
			return .use_env();
		} else {
			if (test_path == null) {
				goto usage_;
			}

			return .use_conf(test_path);
		}

	usage_:
		core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "argv.length =%zd\n", argv.length);
		core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "usage: %s [--strip] [--env] test_dir\n", std.string.toStringz(argv[0]));

		return 2;
	}
