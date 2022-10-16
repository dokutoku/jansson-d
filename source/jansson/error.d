/**
 * License: MIT
 */
module jansson.error;


package:

private static import core.stdc.stdio;
private static import core.stdc.string;
private static import jansson.jansson;
private static import jansson.jansson_private;

pure nothrow @trusted @nogc @live
void jsonp_error_init(scope jansson.jansson.json_error_t* error, scope const char* source)

	do
	{
		if (error != null) {
			error.text[0] = '\0';
			error.line = -1;
			error.column = -1;
			error.position = 0;

			if (source != null) {
				jsonp_error_set_source(error, source);
			} else {
				error.source[0] = '\0';
			}
		}
	}

pure nothrow @trusted @nogc @live
void jsonp_error_set_source(scope jansson.jansson.json_error_t* error, scope const char* source)

	do
	{
		if ((error == null) || (source == null)) {
			return;
		}

		size_t length_ = core.stdc.string.strlen(source);

		if (length_ < jansson.jansson.JSON_ERROR_SOURCE_LENGTH) {
			core.stdc.string.strncpy(&(error.source[0]), source, length_ + 1);
		} else {
			size_t extra = length_ - jansson.jansson.JSON_ERROR_SOURCE_LENGTH + 4;
			error.source[0] = '.';
			error.source[1] = '.';
			error.source[2] = '.';
			core.stdc.string.strncpy(&(error.source[0]) + 3, source + extra, length_ - extra + 1);
		}
	}

nothrow @nogc @live
void jsonp_error_set(F ...)(scope jansson.jansson.json_error_t* error, int line, int column, size_t position, jansson.jansson.json_error_code_t code, scope const char* msg, F f)

	in
	{
		assert(error != null);
		assert(msg != null);
	}

	do
	{
		static if (f.length != 0) {
			jsonp_error_vset(error, line, column, position, code, msg, f[0 .. $]);
		} else {
			jsonp_error_vset(error, line, column, position, code, msg);
		}
	}

nothrow @nogc @live
void jsonp_error_vset(F ...)(scope jansson.jansson.json_error_t* error, int line, int column, size_t position, jansson.jansson.json_error_code_t code, scope const char* msg, F f)

	do
	{
		if (error == null) {
			return;
		}

		if (error.text[0] != '\0') {
			/* error already set */
			return;
		}

		error.line = line;
		error.column = column;
		error.position = cast(int)(position);

		static if (f.length != 0) {
			jansson.jansson_private.snprintf(&(error.text[0]), error.text.length - 1, msg, f[0 .. $]);
		} else {
			jansson.jansson_private.snprintf(&(error.text[0]), error.text.length - 1, msg);
		}

		error.text[error.text.length - 2] = '\0';
		error.text[error.text.length - 1] = cast(char)(code);
	}
