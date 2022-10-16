/*
 * Simple example of parsing and printing JSON using jansson.
 *
 * SYNOPSIS:
 * $ examples/simple_parse
 * Type some JSON > [true, false, null, 1, 0.0, -0.0, "", {"name": "barney"}]
 * JSON Array of 8 elements:
 *   JSON True
 *   JSON False
 *   JSON Null
 *   JSON Integer: "1"
 *   JSON Real: 0.000000
 *   JSON Real: -0.000000
 *   JSON String: ""
 *   JSON Object of 1 pair:
 *     JSON Key: "name"
 *     JSON String: "barney"
 *
 * Copyright (c) 2014 Robert Poor <rdpoor@gmail.com>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */


private static import core.stdc.config;
private static import core.stdc.stdio;
private static import core.stdc.stdlib;
private static import jansson.jansson;

nothrow @nogc @live
void print_json(scope jansson.jansson.json_t* root)

	do
	{
		.print_json_aux(root, 0);
	}

nothrow @nogc @live
void print_json_aux(scope jansson.jansson.json_t* element, size_t indent)

	do
	{
		switch (mixin (jansson.jansson.json_typeof!("element"))) {
			case jansson.jansson.json_type.JSON_OBJECT:
				.print_json_object(element, indent);

				break;

			case jansson.jansson.json_type.JSON_ARRAY:
				.print_json_array(element, indent);

				break;

			case jansson.jansson.json_type.JSON_STRING:
				.print_json_string(element, indent);

				break;

			case jansson.jansson.json_type.JSON_INTEGER:
				.print_json_integer(element, indent);

				break;

			case jansson.jansson.json_type.JSON_REAL:
				.print_json_real(element, indent);

				break;

			case jansson.jansson.json_type.JSON_TRUE:
				.print_json_true(element, indent);

				break;

			case jansson.jansson.json_type.JSON_FALSE:
				.print_json_false(element, indent);

				break;

			case jansson.jansson.json_type.JSON_NULL:
				.print_json_null(element, indent);

				break;

			default:
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "unrecognized JSON type %d\n", mixin (jansson.jansson.json_typeof!("element")));

				break;
		}
	}

nothrow @nogc @live
void print_json_indent(size_t indent)

	do
	{
		for (size_t i = 0; i < indent; i++) {
			core.stdc.stdio.putchar(' ');
		}
	}

pure nothrow @safe @nogc @live
immutable (char)* json_plural(size_t count)

	do
	{
		return (count == 1) ? ("\0") : ("s");
	}

nothrow @nogc @live
void print_json_object(scope jansson.jansson.json_t* element, size_t indent)

	do
	{
		.print_json_indent(indent);
		size_t size = jansson.jansson.json_object_size(element);

		core.stdc.stdio.printf("JSON Object of %zd pair%s:\n", size, .json_plural(size));

		foreach (child_obj; jansson.jansson.json_object_foreach(element)) {
			.print_json_indent(indent + 2);
			core.stdc.stdio.printf("JSON Key: \"%s\"\n", child_obj.key);
			.print_json_aux(child_obj.value, indent + 2);
		}
	}

nothrow @nogc @live
void print_json_array(scope jansson.jansson.json_t* element, size_t indent)

	do
	{
		size_t size = jansson.jansson.json_array_size(element);
		.print_json_indent(indent);

		core.stdc.stdio.printf("JSON Array of %zd element%s:\n", size, .json_plural(size));

		for (size_t i = 0; i < size; i++) {
			.print_json_aux(jansson.jansson.json_array_get(element, i), indent + 2);
		}
	}

nothrow @nogc @live
void print_json_string(scope jansson.jansson.json_t* element, size_t indent)

	do
	{
		.print_json_indent(indent);
		core.stdc.stdio.printf("JSON String: \"%s\"\n", jansson.jansson.json_string_value(element));
	}

nothrow @nogc @live
void print_json_integer(scope jansson.jansson.json_t* element, size_t indent)

	do
	{
		.print_json_indent(indent);
		core.stdc.stdio.printf("JSON Integer: \"%" ~ jansson.jansson.JSON_INTEGER_FORMAT ~ "\"\n", jansson.jansson.json_integer_value(element));
	}

nothrow @nogc @live
void print_json_real(scope jansson.jansson.json_t* element, size_t indent)

	do
	{
		.print_json_indent(indent);
		core.stdc.stdio.printf("JSON Real: %f\n", jansson.jansson.json_real_value(element));
	}

nothrow @nogc @live
void print_json_true(scope jansson.jansson.json_t* element, size_t indent)

	do
	{
		.print_json_indent(indent);
		core.stdc.stdio.printf("JSON True\n");
	}

nothrow @nogc @live
void print_json_false(scope jansson.jansson.json_t* element, size_t indent)

	do
	{
		.print_json_indent(indent);
		core.stdc.stdio.printf("JSON False\n");
	}

nothrow @nogc @live
void print_json_null(scope jansson.jansson.json_t* element, size_t indent)

	do
	{
		.print_json_indent(indent);
		core.stdc.stdio.printf("JSON Null\n");
	}

/*
 * Parse text into a JSON object. If text is valid JSON, returns a
 * jansson.jansson.json_t structure, otherwise prints and error and returns null.
 */
nothrow @nogc
jansson.jansson.json_t* load_json(scope const char* text)

	do
	{
		jansson.jansson.json_error_t error = void;

		jansson.jansson.json_t* root = jansson.jansson.json_loads(text, 0, &error);

		if (root != null) {
			return root;
		} else {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "json error on line %d: %s\n", error.line, &(error.text[0]));

			return null;
		}
	}

/*
 * Print a prompt and return (by reference) a null-terminated line of
 * text.  Returns null on eof or some error.
 */
nothrow @nogc @live
char* read_line(char* line, int max_chars)

	do
	{
		core.stdc.stdio.printf("Type some JSON > ");
		core.stdc.stdio.fflush(core.stdc.stdio.stdout);

		return core.stdc.stdio.fgets(line, max_chars, core.stdc.stdio.stdin);
	}

/*
 * main
 */

enum MAX_CHARS = 4096;

nothrow @nogc @live
int main(string[] argv)

	do
	{
		if (argv.length != 1) {
			core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "Usage: %s\n", &(argv[0][0]));
			core.stdc.stdlib.exit(-1);
		}

		char[.MAX_CHARS] line = void;

		while ((.read_line(&(line[0]), line.length) != null) && (!((line[0] == '\n') && (line[1] == '\0'))) && (!((line[0] == '\r') && (line[1] == '\n') && (line[2] == '\0')))) {
			/* parse text into JSON structure */
			jansson.jansson.json_t* root = .load_json(&(line[0]));

			scope (exit) {
				jansson.jansson.json_decref(root);
			}

			if (root != null) {
				/* print and release the JSON structure */
				.print_json(root);
			}
		}

		return 0;
	}
