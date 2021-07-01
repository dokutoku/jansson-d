/*
 * Generate uint.sizeof bytes of as random data as possible to seed
 * the hash function.
 */
/**
 * License: MIT
 */
module jansson_d.hashtable_seed;


package:

private static import core.stdc.config;
private static import core.stdc.stdio;
private static import core.stdc.time;
private static import core.sys.posix.fcntl;
private static import core.sys.posix.sched;
private static import core.sys.posix.sys.time;
private static import core.sys.posix.unistd;
private static import core.sys.posix.unistd;
private static import core.sys.windows.basetsd;
private static import core.sys.windows.winbase;
private static import core.sys.windows.wincrypt;
private static import core.sys.windows.windef;
private static import core.sys.windows.winnt;

pure nothrow @trusted @nogc @live
private uint buf_to_uint32(scope const char* data)

	in
	{
		assert(data != null);
	}

	do
	{
		uint result = 0;

		for (size_t i = 0; i < uint.sizeof; i++) {
			result = (result << 8) | cast(ubyte)(data[i]);
		}

		return result;
	}

/* /dev/urandom */
version (Posix)
nothrow @nogc @live
private int seed_from_urandom(scope uint* seed)

	in
	{
		assert(seed != null);
	}

	do
	{
		/*
		 * Use unbuffered I/O if we have open(), close() and read(). Otherwise
		 * fall back to fopen()
		 */

		char[uint.sizeof] data = void;
		int ok = void;

		static if ((__traits(compiles, core.sys.posix.fcntl.open)) && (__traits(compiles, core.sys.posix.unistd.read)) && (__traits(compiles, core.sys.posix.unistd.close))) {
			int urandom = core.sys.posix.fcntl.open("/dev/urandom", core.sys.posix.fcntl.O_RDONLY);

			if (urandom == -1) {
				return 1;
			}

			ok = core.sys.posix.unistd.read(urandom, &(data[0]), uint.sizeof) == uint.sizeof;
			core.sys.posix.unistd.close(urandom);
		} else {
			core.stdc.stdio.FILE* urandom = core.stdc.stdio.fopen("/dev/urandom", "rb");

			if (urandom == null) {
				return 1;
			}

			ok = core.stdc.stdio.fread(&(data[0]), 1, uint.sizeof, urandom) == uint.sizeof;
			core.stdc.stdio.fclose(urandom);
		}

		if (!ok) {
			return 1;
		}

		*seed = .buf_to_uint32(&(data[0]));

		return 0;
	}

/* Windows Crypto API */
version (Windows) {
	alias CRYPTACQUIRECONTEXTA = extern (Windows) nothrow @nogc @live core.sys.windows.windef.BOOL function(core.sys.windows.wincrypt.HCRYPTPROV* phProv, core.sys.windows.winnt.LPCSTR pszContainer, core.sys.windows.winnt.LPCSTR pszProvider, core.sys.windows.windef.DWORD dwProvType, core.sys.windows.windef.DWORD dwFlags);
	alias CRYPTGENRANDOM = extern (Windows) nothrow @nogc @live core.sys.windows.windef.BOOL function(core.sys.windows.wincrypt.HCRYPTPROV hProv, core.sys.windows.windef.DWORD dwLen, core.sys.windows.windef.BYTE* pbBuffer);
	alias CRYPTRELEASECONTEXT = extern (Windows) nothrow @nogc @live core.sys.windows.windef.BOOL function(core.sys.windows.wincrypt.HCRYPTPROV hProv, core.sys.windows.windef.DWORD dwFlags);

	nothrow @nogc @live
	private bool seed_from_windows_cryptoapi(scope uint* seed)

		in
		{
			assert(seed != null);
		}

		do
		{
			core.sys.windows.windef.HINSTANCE hAdvAPI32 = core.sys.windows.winbase.GetModuleHandleA("advapi32.dll");

			if (hAdvAPI32 == null) {
				return false;
			}

			.CRYPTACQUIRECONTEXTA pCryptAcquireContext = cast(.CRYPTACQUIRECONTEXTA)(core.sys.windows.winbase.GetProcAddress(hAdvAPI32, "CryptAcquireContextA"));

			if (pCryptAcquireContext == null) {
				return false;
			}

			.CRYPTGENRANDOM pCryptGenRandom = cast(.CRYPTGENRANDOM)(core.sys.windows.winbase.GetProcAddress(hAdvAPI32, "CryptGenRandom"));

			if (pCryptGenRandom == null) {
				return false;
			}

			.CRYPTRELEASECONTEXT pCryptReleaseContext = cast(.CRYPTRELEASECONTEXT)(core.sys.windows.winbase.GetProcAddress(hAdvAPI32, "CryptReleaseContext"));

			if (pCryptReleaseContext == null) {
				return false;
			}

			core.sys.windows.wincrypt.HCRYPTPROV hCryptProv = 0;

			if (!pCryptAcquireContext(&hCryptProv, null, null, core.sys.windows.wincrypt.PROV_RSA_FULL, core.sys.windows.wincrypt.CRYPT_VERIFYCONTEXT)) {
				return false;
			}

			core.sys.windows.windef.BYTE[uint.sizeof] data = void;
			int ok = pCryptGenRandom(hCryptProv, uint.sizeof, &(data[0]));
			pCryptReleaseContext(hCryptProv, 0);

			if (!ok) {
				return false;
			}

			*seed = .buf_to_uint32(cast(char*)(&(data[0])));

			return true;
		}
}

/* gettimeofday() and getpid() */
nothrow @nogc @live
private int seed_from_timestamp_and_pid(scope uint* seed)

	in
	{
		assert(seed != null);
	}

	do
	{
		static if (__traits(compiles, core.sys.posix.sys.time.gettimeofday)) {
			/* XOR of seconds and microseconds */
			core.sys.posix.sys.time.timeval tv = void;
			core.sys.posix.sys.time.gettimeofday(&tv, null);
			*seed = cast(uint)(tv.tv_sec) ^ cast(uint)(tv.tv_usec);
		} else {
			/* Seconds only */
			*seed = cast(uint)(core.stdc.time.time(null));
		}

		/* XOR with PID for more randomness */
		version (Windows) {
			*seed ^= cast(uint)(core.sys.windows.winbase.GetCurrentProcessId());
		} else static if (__traits(compiles, core.sys.posix.unistd.getpid)) {
			*seed ^= cast(uint)(core.sys.posix.unistd.getpid());
		}

		return 0;
	}

nothrow @nogc @live
private uint generate_seed()

	do
	{
		uint seed = 0;
		bool done = false;

		version (Windows) {
			if (.seed_from_windows_cryptoapi(&seed)) {
				done = true;
			}
		} else {
			if (.seed_from_urandom(&seed) == 0) {
				done = true;
			}
		}

		if (!done) {
			/*
			 * Fall back to timestamp and PID if no better randomness is
			 * available
			 */
			.seed_from_timestamp_and_pid(&seed);
		}

		/* Make sure the seed is never zero */
		if (seed == 0) {
			seed = 1;
		}

		return seed;
	}

/* volatile */
package __gshared uint hashtable_seed = 0;

//Posix
static if ((__traits(compiles, __atomic_test_and_set)) && (__traits(compiles, __ATOMIC_RELAXED)) && (__traits(compiles, __atomic_store_n)) && (__traits(compiles, __ATOMIC_RELEASE)) && (__traits(compiles, __atomic_load_n)) && (__traits(compiles, __ATOMIC_ACQUIRE))) {
	version (Windows) {
		static assert (false);
	}

	/* volatile */
	//private
	__gshared char seed_initialized = 0;

	///
	extern (C)
	nothrow @nogc @live
	public void json_object_seed(size_t seed)

		do
		{
			uint new_seed = cast(uint)(seed);

			if (.hashtable_seed == 0) {
				if (__atomic_test_and_set(&.seed_initialized, __ATOMIC_RELAXED) == 0) {
					/* Do the seeding ourselves */
					if (new_seed == 0) {
						new_seed = .generate_seed();
					}

					__atomic_store_n(&.hashtable_seed, new_seed, __ATOMIC_RELEASE);
				} else {
					/* Wait for another thread to do the seeding */
					do {
						static if (__traits(compiles, core.sys.posix.sched.sched_yield)) {
							core.sys.posix.sched.sched_yield();
						}
					} while (__atomic_load_n(&.hashtable_seed, __ATOMIC_ACQUIRE) == 0);
				}
			}
		}
} else static if (__traits(compiles, __sync_bool_compare_and_swap)) {
	version (Windows) {
		static assert (false);
	}

	///
	extern (C)
	nothrow @nogc @live
	public void json_object_seed(size_t seed)

		do
		{
			uint new_seed = cast(uint)(seed);

			if (.hashtable_seed == 0) {
				if (new_seed == 0) {
					/*
					 * Explicit synchronization fences are not supported by the
					 *    __sync builtins, so every thread getting here has to
					 *    generate the seed value.
					 */
					new_seed = .generate_seed();
				}

				do {
					if (__sync_bool_compare_and_swap(&.hashtable_seed, 0, new_seed)) {
						/* We were the first to seed */
						break;
					} else {
						/* Wait for another thread to do the seeding */
						static if (__traits(compiles, core.sys.posix.sched.sched_yield)) {
							core.sys.posix.sched.sched_yield();
						}
					}
				} while (.hashtable_seed == 0);
			}
		}
} else version (Win32) {
	private __gshared core.sys.windows.windef.LONG seed_initialized = 0;

	///
	extern (C)
	nothrow @nogc @live
	public void json_object_seed(size_t seed)

		do
		{
			uint new_seed = cast(uint)(seed);

			if (.hashtable_seed == 0) {
				if (core.sys.windows.winbase.InterlockedIncrement(&.seed_initialized) == 1) {
					/* Do the seeding ourselves */
					if (new_seed == 0) {
						new_seed = .generate_seed();
					}

					.hashtable_seed = new_seed;
				} else {
					/* Wait for another thread to do the seeding */
					do {
						core.sys.windows.winbase.SwitchToThread();
					} while (.hashtable_seed == 0);
				}
			}
		}
} else {
	/* Fall back to a thread-unsafe version */
	///
	extern (C)
	nothrow @nogc @live
	public void json_object_seed(size_t seed)

		do
		{
			uint new_seed = cast(uint)(seed);

			if (.hashtable_seed == 0) {
				if (new_seed == 0) {
					new_seed = .generate_seed();
				}

				.hashtable_seed = new_seed;
			}
		}
}
