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
private static import core.stdc.stdio;
private static import core.stdc.string;
private static import etc.c.curl;
private static import jansson.jansson;
private static import jansson.jansson_private;
private static import std.string;

/* 256 KB */
enum BUFFER_SIZE = 256 * 1024;

enum URL_FORMAT = "https://api.github.com/repos/%s/%s/commits";
enum URL_SIZE = 256;

/*
 * Return the offset of the first newline in text or the length of
 * text if there's no newline
 */
pure nothrow @trusted @nogc @live
private int newline_offset(const scope char* text)

	do
	{
		const char* newline = core.stdc.string.strchr(text, '\n');

		if (newline == null) {
			return cast(int)(core.stdc.string.strlen(text));
		} else {
			return cast(int)(newline - text);
		}
	}

struct write_result_
{
	char* data;
	int pos;
}

extern (C)
nothrow @nogc @live
private size_t write_response(scope void* ptr_, size_t size, size_t nmemb, scope void* stream)

	do
	{
		.write_result_* result = cast(.write_result_*)(stream);

		if ((result.pos + (size * nmemb)) >= (.BUFFER_SIZE - 1)) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "error: too small buffer\n");

			return 0;
		}

		core.stdc.string.memcpy(result.data + result.pos, ptr_, size * nmemb);
		result.pos += size * nmemb;

		return size * nmemb;
	}

private char* request(scope const char* url)

	do
	{
		enum error_ = `
		if (data != null) {
			core.memory.pureFree(data);
		}`;

		etc.c.curl.curl_global_init(etc.c.curl.CurlGlobal.all);

		scope (exit) {
			etc.c.curl.curl_global_cleanup();
		}

		etc.c.curl.CURL* curl = etc.c.curl.curl_easy_init();

		if (curl == null) {
			return null;
		}

		scope (exit) {
			assert(curl != null);
			etc.c.curl.curl_easy_cleanup(curl);
			curl = null;
		}

		char* data = cast(char*)(core.memory.pureMalloc(.BUFFER_SIZE));

		if (data == null) {
			mixin (error_);

			return null;
		}

		.write_result_ write_result =
		{
			data: data,
			pos: 0,
		};

		etc.c.curl.curl_easy_setopt(curl, etc.c.curl.CurlOption.url, url);

		/* GitHub commits API v3 requires a User-Agent header */
		etc.c.curl.curl_slist* headers = null;
		headers = etc.c.curl.curl_slist_append(headers, "User-Agent: Jansson-Tutorial");

		scope (exit) {
			if (headers != null) {
				etc.c.curl.curl_slist_free_all(headers);
			}
		}

		etc.c.curl.curl_easy_setopt(curl, etc.c.curl.CurlOption.httpheader, headers);

		etc.c.curl.curl_easy_setopt(curl, etc.c.curl.CurlOption.writefunction, &.write_response);

		etc.c.curl.curl_easy_setopt(curl, etc.c.curl.CurlOption.writedata, &write_result);

		etc.c.curl.CURLcode status = etc.c.curl.curl_easy_perform(curl);

		if (status != 0) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "error: unable to request data from %s:\n", url);
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "%s\n", etc.c.curl.curl_easy_strerror(status));

			mixin (error_);

			return null;
		}

		core.stdc.config.c_long code = void;
		etc.c.curl.curl_easy_getinfo(curl, etc.c.curl.CurlInfo.response_code, &code);

		if (code != 200) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "error: server responded with code %ld\n", code);

			mixin (error_);

			return null;
		}

		/* zero-terminate the result */
		data[write_result.pos] = '\0';

		return data;
	}

int main(string[] argv)

	do
	{
		if (argv.length != 3) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "usage: %s USER REPOSITORY\n\n", std.string.toStringz(argv[0]));
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "List commits at USER's REPOSITORY.\n\n");

			return 2;
		}

		char[.URL_SIZE] url = void;
		core.stdc.stdio.snprintf(&(url[0]), url.length, .URL_FORMAT, std.string.toStringz(argv[1]), std.string.toStringz(argv[2]));

		char* text = .request(&(url[0]));

		if (text == null) {
			return 1;
		}

		jansson.jansson.json_error_t error = void;
		jansson.jansson.json_t* root = jansson.jansson.json_loads(text, 0, &error);
		core.memory.pureFree(text);

		if (root == null) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "error: on line %d: %s\n", error.line, &(error.text[0]));

			return 1;
		}

		if (!mixin (jansson.jansson.json_is_array!("root"))) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "error: root is not an array\n");
			jansson.jansson.json_decref(root);

			return 1;
		}

		for (size_t i = 0; i < jansson.jansson.json_array_size(root); i++) {
			jansson.jansson.json_t* data = jansson.jansson.json_array_get(root, i);

			if (!mixin (jansson.jansson.json_is_object!("data"))) {
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "error: commit data %d is not an object\n", cast(int)(i + 1));
				jansson.jansson.json_decref(root);

				return 1;
			}

			jansson.jansson.json_t* sha = jansson.jansson.json_object_get(data, "sha");

			if (!mixin (jansson.jansson.json_is_string!("sha"))) {
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "error: commit %d: sha is not a string\n", cast(int)(i + 1));
				jansson.jansson.json_decref(root);

				return 1;
			}

			jansson.jansson.json_t* commit = jansson.jansson.json_object_get(data, "commit");

			if (!mixin (jansson.jansson.json_is_object!("commit"))) {
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "error: commit %d: commit is not an object\n", cast(int)(i + 1));
				jansson.jansson.json_decref(root);

				return 1;
			}

			jansson.jansson.json_t* message = jansson.jansson.json_object_get(commit, "message");

			if (!mixin (jansson.jansson.json_is_string!("message"))) {
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "error: commit %d: message is not a string\n", cast(int)(i + 1));
				jansson.jansson.json_decref(root);

				return 1;
			}

			const char* message_text = jansson.jansson.json_string_value(message);
			core.stdc.stdio.printf("%.8s %.*s\n", jansson.jansson.json_string_value(sha), .newline_offset(message_text), message_text);
		}

		jansson.jansson.json_decref(root);

		return 0;
	}
