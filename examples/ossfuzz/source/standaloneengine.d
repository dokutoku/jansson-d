/**
 * License: MIT
 */
module ossfuzz.standaloneengine;


private static import core.memory;
private static import core.stdc.stdio;
private static import ossfuzz.json_load_dump_fuzzer;
private static import std.string;

/**
 * Main procedure for standalone fuzzing engine.
 *
 * Reads filenames from the argument array. For each filename, read the file
 * into memory and then call the fuzzing interface with the data.
 */
void main(string[] argv)

	do
	{
		for (size_t ii = 1; ii < argv.length; ii++) {
			core.stdc.stdio.printf("[%s] ", std.string.toStringz(argv[ii]));

			/* Try and open the file. */
			core.stdc.stdio.FILE* infile = core.stdc.stdio.fopen(std.string.toStringz(argv[ii]), "rb");

			if (infile != null) {
				ubyte* buffer = null;

				core.stdc.stdio.printf("Opened.. ");

				/* Get the length of the file. */
				core.stdc.stdio.fseek(infile, 0L, core.stdc.stdio.SEEK_END);
				size_t buffer_len = core.stdc.stdio.ftell(infile);

				/* Reset the file indicator to the beginning of the file. */
				core.stdc.stdio.fseek(infile, 0L, core.stdc.stdio.SEEK_SET);

				/* Allocate a buffer for the file contents. */
				buffer = cast(ubyte*)(core.memory.pureCalloc(buffer_len, ubyte.sizeof));

				if (buffer != null) {
					/* Read all the text from the file into the buffer. */
					core.stdc.stdio.fread(buffer, ubyte.sizeof, buffer_len, infile);
					core.stdc.stdio.printf("Read %zu bytes, fuzzing.. ", buffer_len);

					/* Call the fuzzer with the data. */
					ossfuzz.json_load_dump_fuzzer.LLVMFuzzerTestOneInput(buffer, buffer_len);

					core.stdc.stdio.printf("complete !!");

					/* Free the buffer as it's no longer needed. */
					core.memory.pureFree(buffer);
				} else {
					core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "[%s] Failed to allocate %zu bytes \n", std.string.toStringz(argv[ii]), buffer_len);
				}

				/* Close the file as it's no longer needed. */
				core.stdc.stdio.fclose(infile);
				infile = null;
			} else {
				/* Failed to open the file. Maybe wrong name or wrong permissions? */
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "[%s] Open failed. \n", std.string.toStringz(argv[ii]));
			}

			core.stdc.stdio.printf("\n");
		}
	}
