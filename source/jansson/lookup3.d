/*
 * lookup3.c, by Bob Jenkins, May 2006, Public Domain.
 * 
 * These are functions for producing 32-bit hashes for hash table lookup.
 * hashword(), hashlittle(), hashlittle2(), hashbig(), mix(), and final_()
 * are externally useful functions.  Routines to test the hash are included
 * if SELF_TEST is defined.  You can use this free for any purpose.  It's in
 * the public domain.  It has no warranty.
 * 
 * You probably want to use hashlittle().  hashlittle() and hashbig()
 * hash byte arrays.  hashlittle() is is faster than hashbig() on
 * little-endian machines.  Intel and AMD are little-endian machines.
 * On second thought, you probably want hashlittle2(), which is identical to
 * hashlittle() except it returns two 32-bit hashes for the price of one.
 * You could implement hashbig2() if you wanted but I haven't bothered here.
 * 
 * If you want to find a hash of, say, exactly 7 integers, do
 *   a = i1; b = i2; c = i3;
 *   mixin (mix!("a", "b", "c"));
 *   a += i4; b += i5; c += i6;
 *   mixin (mix!("a", "b", "c"));
 *   a += i7;
 *   final_(a, b, c);
 * then use c as the hash value.  If you have a variable length array of
 * 4-byte integers to hash, use hashword().  If you have a byte array (like
 * a character string), use hashlittle().  If you have several byte arrays, or
 * a mix of things, see the comments above hashlittle().
 * 
 * Why is this so big?  I read 12 bytes at a time into 3 4-byte integers,
 * then mix those integers.  This is fast (you can do a lot more thorough
 * mixing with (12 * 3) instructions on 3 integers than you can with 3 instructions
 * on 1 byte), but shoehorning those bytes into integers efficiently is messy.
 */
/**
 * License: MIT
 */
module jansson.lookup3;


package:

/* Detect Valgrind or AddressSanitizer */
version (VALGRIND) {
	version = NO_MASKING_TRICK;
} else {
	//#if defined(__has_feature)  /* Clang */
		//#if __has_feature(address_sanitizer)  /* is ASAN enabled? */
			//version = NO_MASKING_TRICK;
		//#endif
	//#else
		//#if defined(__SANITIZE_ADDRESS__)  /* GCC 4.8.x, is ASAN enabled? */
			//version = NO_MASKING_TRICK;
		//#endif
	//#endif
}

/*
 * My best guess at if you are big-endian or little-endian.  This may
 * need adjustment.
 */
version (LittleEndian) {
	enum HASH_LITTLE_ENDIAN = 1;
	enum HASH_BIG_ENDIAN = 0;
} else version (BigEndian) {
	enum HASH_LITTLE_ENDIAN = 0;
	enum HASH_BIG_ENDIAN = 1;
} else {
	enum HASH_LITTLE_ENDIAN = 0;
	enum HASH_BIG_ENDIAN = 0;
}

template hashsize(string n)
{
	enum hashsize = "(cast(size_t)(1) << (" ~ n ~ "))";
}

template hashmask(string n)
{
	enum hashmask = "(" ~ jansson.lookup3.hashsize!(n) ~ " - 1)";
}

template rot(string x, string k)
{
	enum rot = "(((" ~ x ~ ") << (" ~ k ~ ")) | ((" ~ x ~ ") >> (32 - (" ~ k ~ "))))";
}

/*
 * mix -- mix 3 32-bit values reversibly.
 * 
 * This is reversible, so any information in (a, b, c) before mix() is
 * still in (a, b, c) after mix().
 * 
 * If four pairs of (a, b, c) inputs are run through mix(), or through
 * mix() in reverse, there are at least 32 bits of the output that
 * are sometimes the same for one pair and different for another pair.
 * This was tested for:
 * * pairs that differed by one bit, by two bits, in any combination
 *   of top bits of (a, b, c), or in any combination of bottom bits of
 *   (a, b, c).
 * * "differ" is defined as +, -, ^, or ~^.  For + and -, I transformed
 *   the output delta to a Gray code (a^(a>>1)) so a string of 1's (as
 *   is commonly produced by subtraction) look like a single 1-bit
 *   difference.
 * * the base values were pseudorandom, all zero but one bit set, or
 *   all zero plus a counter that starts at zero.
 * 
 * Some k values for my "a-=c; a^=rot(c, k); c+=b;" arrangement that
 * satisfy this are
 *     4  6  8 16 19  4
 *     9 15  3 18 27 15
 *    14  9  3  7 17  3
 * Well, "9 15 3 18 27 15" didn't quite get 32 bits diffing
 * for "differ" defined as + with a one-bit base and a two-bit delta.  I
 * used http://burtleburtle.net/bob/hash/avalanche.html to choose
 * the operations, constants, and arrangements of the variables.
 * 
 * This does not achieve avalanche.  There are input bits of (a, b, c)
 * that fail to affect some output bits of (a, b, c), especially of a.  The
 * most thoroughly mixed value is c, but it doesn't really even achieve
 * avalanche in c.
 * 
 * This allows some parallelism.  Read-after-writes are good at doubling
 * the number of bits affected, so the goal of mixing pulls in the opposite
 * direction as the goal of parallelism.  I did what I could.  Rotates
 * seem to cost as much as shifts on every machine I could lay my hands
 * on, and rotates are much kinder to the top and bottom bits, so I used
 * rotates.
 */
template mix(string a, string b, string c)
{
	enum mix = "{ " ~ a ~ " -= " ~ c ~ "; " ~ a ~ " ^= " ~ jansson.lookup3.rot!(c, "4") ~ "; " ~ c ~ " += " ~ b ~ "; " ~ b ~ " -= " ~ a ~ "; " ~ b ~ " ^= " ~ jansson.lookup3.rot!(a, "6") ~ "; " ~ a ~ " += " ~ c ~ "; " ~ c ~ " -= " ~ b ~ "; " ~ c ~ " ^= " ~ jansson.lookup3.rot!(b, "8") ~ "; " ~ b ~ " += " ~ a ~ "; " ~ a ~ " -= " ~ c ~ "; " ~ a ~ " ^= " ~ jansson.lookup3.rot!(c, "16") ~ "; " ~ c ~ " += " ~ b ~ "; " ~ b ~ " -= " ~ a ~ "; " ~ b ~ " ^= " ~ jansson.lookup3.rot!(a, "19") ~ "; " ~ a ~ " += " ~ c ~ "; " ~ c ~ " -= " ~ b ~ "; " ~ c ~ " ^= " ~ jansson.lookup3.rot!(b, "4") ~ "; " ~ b ~ " += " ~ a ~ "; }";
}

/*
 * final_ -- final mixing of 3 32-bit values (a, b, c) into c
 * 
 * Pairs of (a, b, c) values differing in only a few bits will usually
 * produce values of c that look totally different.  This was tested for
 * * pairs that differed by one bit, by two bits, in any combination
 *   of top bits of (a, b, c), or in any combination of bottom bits of
 *   (a, b, c).
 * * "differ" is defined as +, -, ^, or ~^.  For + and -, I transformed
 *   the output delta to a Gray code (a^(a>>1)) so a string of 1's (as
 *   is commonly produced by subtraction) look like a single 1-bit
 *   difference.
 * * the base values were pseudorandom, all zero but one bit set, or
 *   all zero plus a counter that starts at zero.
 * 
 * These constants passed:
 *  14 11 25 16 4 14 24
 *  12 14 25 16 4 14 24
 * and these came close:
 *   4  8 15 26 3 22 24
 *  10  8 15 26 3 22 24
 *  11  8 15 26 3 22 24
 */
template final_(string a, string b, string c)
{
	enum final_ = "{ " ~ c ~ " ^= " ~ b ~ "; " ~ c ~ " -= " ~ jansson.lookup3.rot!(b, "14") ~ "; " ~ a ~ " ^= " ~ c ~ "; " ~ a ~ " -= " ~ jansson.lookup3.rot!(c, "11") ~ "; " ~ b ~ " ^= " ~ a ~ "; " ~ b ~ " -= " ~ jansson.lookup3.rot!(a, "25") ~ "; " ~ c ~ " ^= " ~ b ~ "; " ~ c ~ " -= " ~ jansson.lookup3.rot!(b, "16") ~ "; " ~ a ~ " ^= " ~ c ~ "; " ~ a ~ " -= " ~ jansson.lookup3.rot!(c, "4") ~ "; " ~ b ~ " ^= " ~ a ~ "; " ~ b ~ " -= " ~ jansson.lookup3.rot!(a, "14") ~ "; " ~ c ~ " ^= " ~ b ~ "; " ~ c ~ " -= " ~ jansson.lookup3.rot!(b, "24") ~ "; }";
}

//#define final_(a, b, c) { c ^= b; c -= rot(b, 14); a ^= c; a -= rot(c, 11); b ^= a; b -= rot(a, 25); c ^= b; c -= rot(b, 16); a ^= c; a -= rot(c, 4); b ^= a; b -= rot(a, 14); c ^= b; c -= rot(b, 24); }

/*
 * hashlittle() -- hash a variable-length key into a 32-bit value
 * 
 * The best hash table sizes are powers of 2.  There is no need to do
 * mod a prime (mod is sooo slow!).  If you need less than 32 bits,
 * use a bitmask.  For example, if you need only 10 bits, do
 *   h = (h & hashmask(10));
 * In which case, the hash table should have hashsize(10) elements.
 * 
 * If you are hashing n strings cast(ubyte**)(k), do it like this:
 *   for (i = 0, h = 0; i < n; ++i) { h = hashlittle(k[i], len[i], h); }
 * 
 * By Bob Jenkins, 2006.  bob_jenkins@burtleburtle.net.  You may use this
 * code any way you wish, private, educational, or commercial.  It's free.
 * 
 * Use for hash table lookup, or anything where one collision in 2^^32 is
 * acceptable.  Do NOT use for cryptographic purposes.
 */
/**
 * hash a variable-length key into a 32-bit value
 *
 * Params:
 *      key = the key (the unaligned variable-length array of bytes)
 *      length_ = the length of the key, counting by bytes
 *      initval = can be any 4-byte value
 *
 * Returns: a 32-bit value.  Every bit of the key affects every bit of the return value. Two keys differing by one or two bits will have totally different hash values.
 */
pure nothrow @nogc @live
package uint hashlittle(scope const void* key, size_t length_, uint initval)

	in
	{
		assert(key != null);
	}

	do
	{
		/* needed for Mac Powerbook G4 */
		union u_
		{
			const (void)* ptr_;
			size_t i;
		}

		/* Set up the internal state */
		uint c = 0xDEADBEEF + (cast(uint)(length_)) + initval;
		uint b = c;
		uint a = c;

		u_ u = void;
		u.ptr_ = key;

		if ((.HASH_LITTLE_ENDIAN) && ((u.i & 0x03) == 0)) {
			/* read 32-bit chunks */
			const (uint)* k = cast(const (uint)*)(key);

			/*------ all but last block: aligned reads and affect 32 bits of (a, b, c) */
			for (; length_ > 12; length_ -= 12, k += 3) {
				a += k[0];
				b += k[1];
				c += k[2];
				mixin (.mix!("a", "b", "c"));
			}

			/*----------------------------- handle the last (probably partial) block */
			/*
			 * "k[2]&0xFFFFFF" actually reads beyond the end of the string, but
			 * then masks off the part it's not allowed to read.  Because the
			 * string is aligned, the masked-off tail is in the same word as the
			 * rest of the string.  Every machine with memory protection I've seen
			 * does it on word boundaries, so is OK with this.  But VALGRIND will
			 * still catch it and complain.  The masking trick does make the hash
			 * noticeably faster for short strings (like English words).
			 */
			version (NO_MASKING_TRICK) {
				const ubyte* k8 = cast(const (ubyte)*)(k);

				switch (length_) {
					case 12:
						c += k[2];
						b += k[1];
						a += k[0];

						break;

					case 11:
						c += cast(uint)(k8[10]) << 16;

						/* fall through */
						goto case;

					case 10:
						c += cast(uint)(k8[9]) << 8;

						/* fall through */
						goto case;

					case 9 :
						c += k8[8];

						/* fall through */
						goto case;

					case 8 :
						b += k[1];
						a += k[0];

						break;

					case 7 :
						b += cast(uint)(k8[6]) << 16;

						/* fall through */
						goto case;

					case 6 :
						b += cast(uint)(k8[5]) << 8;

						/* fall through */
						goto case;

					case 5 :
						b += k8[4];

						/* fall through */
						goto case;

					case 4 :
						a += k[0];

						break;

					case 3 :
						a += cast(uint)(k8[2]) << 16;

						/* fall through */
						goto case;

					case 2 :
						a += cast(uint)(k8[1]) << 8;

						/* fall through */
						goto case;

					case 1 :
						a += k8[0];

						break;

					case 0 :
						return c;
				}
			} else {
				switch (length_) {
					case 12:
						c += k[2];
						b += k[1];
						a += k[0];

						break;

					case 11:
						c += k[2] & 0xFFFFFF;
						b += k[1];
						a += k[0];

						break;

					case 10:
						c += k[2] & 0xFFFF;
						b += k[1];
						a += k[0];

						break;

					case 9 :
						c += k[2] & 0xFF;
						b += k[1];
						a += k[0];

						break;

					case 8 :
						b += k[1];
						a += k[0];

						break;

					case 7 :
						b += k[1] & 0xFFFFFF;
						a += k[0];

						break;

					case 6 :
						b += k[1] & 0xFFFF;
						a += k[0];

						break;

					case 5 :
						b += k[1] & 0xFF;
						a += k[0];

						break;

					case 4 :
						a += k[0];

						break;

					case 3 :
						a += k[0] & 0xFFFFFF;

						break;

					case 2 :
						a += k[0] & 0xFFFF;

						break;

					case 1 :
						a += k[0] & 0xFF;

						break;

					case 0 :
						/* zero length strings require no mixing */
						return c;

					default:
						break;
				}
			}
		} else if ((.HASH_LITTLE_ENDIAN) && ((u.i & 0x01) == 0)) {
			/* read 16-bit chunks */
			const (ushort)* k = cast(const (ushort)*)(key);

			/*--------------- all but last block: aligned reads and different mixing */
			for (; length_ > 12; length_ -= 12, k += 6) {
				a += k[0] + (cast(uint)(k[1]) << 16);
				b += k[2] + (cast(uint)(k[3]) << 16);
				c += k[4] + (cast(uint)(k[5]) << 16);
				mixin (.mix!("a", "b", "c"));
			}

			/*----------------------------- handle the last (probably partial) block */
			const ubyte* k8 = cast(const ubyte*)(k);

			switch (length_) {
				case 12:
					c += k[4] + (cast(uint)(k[5]) << 16);
					b += k[2] + (cast(uint)(k[3]) << 16);
					a += k[0] + (cast(uint)(k[1]) << 16);

					break;

				case 11:
					c += cast(uint)(k8[10]) << 16;

					/* fall through */
					goto case;

				case 10:
					c += k[4];
					b += k[2] + (cast(uint)(k[3]) << 16);
					a += k[0] + (cast(uint)(k[1]) << 16);

					break;

				case 9 :
					c += k8[8];

					/* fall through */
					goto case;

				case 8 :
					b += k[2] + (cast(uint)(k[3]) << 16);
					a += k[0] + (cast(uint)(k[1]) << 16);

					break;

				case 7 :
					b += cast(uint)(k8[6]) << 16;

					/* fall through */
					goto case;

				case 6 :
					b += k[2];
					a += k[0] + (cast(uint)(k[1]) << 16);

					break;

				case 5 :
					b += k8[4];

					/* fall through */
					goto case;

				case 4 :
					a += k[0] + (cast(uint)(k[1]) << 16);

					break;

				case 3 :
					a += cast(uint)(k8[2]) << 16;

					/* fall through */
					goto case;

				case 2 :
					a += k[0];

					break;

				case 1 :
					a += k8[0];

					break;

				case 0 :
					/* zero length requires no mixing */
					return c;

				default:
					break;
			}
		} else {                        /* need to read the key one byte at a time */
			const (ubyte)* k = cast(const ubyte*)(key);

			/*--------------- all but the last block: affect some 32 bits of (a, b, c) */
			for (; length_ > 12; length_ -= 12, k += 12) {
				a += k[0];
				a += cast(uint)(k[1]) << 8;
				a += cast(uint)(k[2]) << 16;
				a += cast(uint)(k[3]) << 24;
				b += k[4];
				b += cast(uint)(k[5]) << 8;
				b += cast(uint)(k[6]) << 16;
				b += cast(uint)(k[7]) << 24;
				c += k[8];
				c += cast(uint)(k[9]) << 8;
				c += cast(uint)(k[10]) << 16;
				c += cast(uint)(k[11]) << 24;
				mixin (.mix!("a", "b", "c"));
			}

			/*-------------------------------- last block: affect all 32 bits of (c) */
			switch (length_) {                /* all the case statements fall through */
				case 12:
					c += cast(uint)(k[11]) << 24;

					/* fall through */
					goto case;

				case 11:
					c += cast(uint)(k[10]) << 16;

					/* fall through */
					goto case;

				case 10:
					c += cast(uint)(k[9]) << 8;

					/* fall through */
					goto case;

				case 9 :
					c += k[8];

					/* fall through */
					goto case;

				case 8 :
					b += cast(uint)(k[7]) << 24;

					/* fall through */
					goto case;

				case 7 :
					b += cast(uint)(k[6]) << 16;

					/* fall through */
					goto case;

				case 6 :
					b += cast(uint)(k[5]) << 8;

					/* fall through */
					goto case;

				case 5 :
					b += k[4];

					/* fall through */
					goto case;

				case 4 :
					a += cast(uint)(k[3]) << 24;

					/* fall through */
					goto case;

				case 3 :
					a += cast(uint)(k[2]) << 16;

					/* fall through */
					goto case;

				case 2 :
					a += cast(uint)(k[1]) << 8;

					/* fall through */
					goto case;

				case 1 :
					a += k[0];

					break;

				case 0 :
					return c;

				default:
					break;
			}
		}

		mixin (.final_!("a", "b", "c"));

		return c;
	}
