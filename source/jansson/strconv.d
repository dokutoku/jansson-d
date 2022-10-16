/**
 * License: MIT
 */
module jansson.strconv;


package:

private static import core.stdc.errno;
private static import core.stdc.math;
private static import core.stdc.stdlib;
private static import core.stdc.string;
private static import jansson.jansson_config;
private static import jansson.jansson_private;
private static import jansson.strbuffer;

static if (jansson.jansson_config.JSON_HAVE_LOCALECONV) {
	private static import core.stdc.locale;

	/*
	 * - This code assumes that the decimal separator is exactly one
	 *  character.
	 *
	 * - If setlocale() is called by another thread between the call to
	 *  localeconv() and the call to sprintf() or strtod(), the result may
	 *  be wrong. setlocale() is not thread-safe and should not be used
	 *  this way. Multi-threaded programs should use uselocale() instead.
	 */

	nothrow @trusted @nogc
	private void to_locale(scope jansson.strbuffer.strbuffer_t* strbuffer)

		in
		{
			assert(strbuffer != null);
		}

		do
		{
			const char* point = core.stdc.locale.localeconv().decimal_point;

			if (*point == '.') {
				/* No conversion needed */
				return;
			}

			char* pos = core.stdc.string.strchr(strbuffer.value, '.');

			if (pos != null) {
				*pos = *point;
			}
		}

	nothrow @trusted @nogc
	private void from_locale(scope char* buffer)

		in
		{
			assert(buffer != null);
		}

		do
		{
			const char* point = core.stdc.locale.localeconv().decimal_point;

			if (*point == '.') {
				/* No conversion needed */
				return;
			}

			char* pos = core.stdc.string.strchr(buffer, *point);

			if (pos != null) {
				*pos = '.';
			}
		}
}

nothrow @trusted @nogc
bool jsonp_strtod(scope jansson.strbuffer.strbuffer_t* strbuffer, scope double* out_)

	in
	{
		assert(strbuffer != null);
		assert(out_ != null);
	}

	do
	{
		static if (jansson.jansson_config.JSON_HAVE_LOCALECONV) {
			.to_locale(strbuffer);
		}

		core.stdc.errno.errno = 0;
		char* end = null;
		double value = core.stdc.stdlib.strtod(strbuffer.value, &end);
		assert(end == (strbuffer.value + strbuffer.length_));

		if (((value == core.stdc.math.HUGE_VAL) || (value == -core.stdc.math.HUGE_VAL)) && (core.stdc.errno.errno == core.stdc.errno.ERANGE)) {
			/* Overflow */
			return false;
		}

		*out_ = value;

		return true;
	}

nothrow @trusted @nogc
int jsonp_dtostr(scope char* buffer, size_t size, double value, int precision)

	in
	{
		assert(buffer != null);
	}

	do
	{
		if (precision == 0) {
			precision = 17;
		}

		int ret = jansson.jansson_private.snprintf(buffer, size, "%.*g", precision, value);

		if (ret < 0) {
			return -1;
		}

		size_t length_ = cast(size_t)(ret);

		if (length_ >= size) {
			return -1;
		}

		static if (jansson.jansson_config.JSON_HAVE_LOCALECONV) {
			.from_locale(buffer);
		}

		/*
		 * Make sure there's a dot or 'e' in the output. Otherwise
		 * a real is converted to an integer when decoding
		 */
		if ((core.stdc.string.strchr(buffer, '.') == null) && (core.stdc.string.strchr(buffer, 'e') == null)) {
			if ((length_ + 3) >= size) {
				/* No space to append ".0" */
				return -1;
			}

			buffer[length_] = '.';
			buffer[length_ + 1] = '0';
			buffer[length_ + 2] = '\0';
			length_ += 2;
		}

		/*
		 * Remove leading '+' from positive exponent. Also remove leading
		 * zeros from exponents (added by some printf() implementations)
		 */
		char* start = core.stdc.string.strchr(buffer, 'e');

		if (start != null) {
			start++;
			char* end = start + 1;

			if (*start == '-') {
				start++;
			}

			for (; *end == '0'; end++) {
			}

			if (end != start) {
				core.stdc.string.memmove(start, end, length_ - cast(size_t)(end - buffer));
				length_ -= cast(size_t)(end - start);
			}
		}

		return cast(int)(length_);
	}
