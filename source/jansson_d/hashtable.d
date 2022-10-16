/*
 * Copyright (c) 2009-2016 Petri Lehtinen <petri@digip.org>
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */
/**
 * License: MIT
 */
module jansson_d.hashtable;


package:

private static import core.stdc.string;
private static import jansson_d.hashtable_seed;
private static import jansson_d.jansson;
private static import jansson_d.jansson_private;
private static import jansson_d.lookup3;

enum INITIAL_HASHTABLE_ORDER = 3;

struct hashtable_list
{
	.hashtable_list* prev;
	.hashtable_list* next;
}

/*
 * "pair" may be a bit confusing a name, but think of it as a
 * key-value pair. In this case, it just encodes some extra data,
 * too
 */
struct hashtable_pair
{
	.hashtable_list list;
	.hashtable_list ordered_list;
	size_t hash;
	jansson_d.jansson.json_t* value;
	size_t key_len;

	/* dynamic array */
	char key = '\0';
}

struct hashtable_bucket
{
	.hashtable_list* first;
	.hashtable_list* last;
}

package struct hashtable
{
	size_t size;
	.hashtable_bucket* buckets;

	/* hashtable has pow(2, order) buckets */
	size_t order;

	.hashtable_list list;
	.hashtable_list ordered_list;
}

alias hashtable_t = .hashtable;

package template hashtable_key_to_iter(string key_)
{
	enum hashtable_key_to_iter = "(&(mixin (jansson_d.jansson_private.container_of!(\"" ~ key_ ~ "\", \"jansson_d.hashtable.hashtable_pair\", \"key\")).ordered_list))";
}

alias list_t = .hashtable_list;
alias pair_t = .hashtable_pair;
alias bucket_t = .hashtable_bucket;

template list_to_pair(string list_)
{
	enum list_to_pair = "(mixin (jansson_d.jansson_private.container_of!(\"" ~ list_ ~ "\", \"jansson_d.hashtable.pair_t\", \"list\")))";
}

template ordered_list_to_pair(string list_)
{
	enum ordered_list_to_pair = "(mixin (jansson_d.jansson_private.container_of!(\"" ~ list_ ~ "\", \"jansson_d.hashtable.pair_t\", \"ordered_list\")))";
}

template hash_str(string key, string len)
{
	enum hash_str = "(cast(size_t)(jansson_d.lookup3.hashlittle((" ~ key ~ "), (" ~ len ~ "), jansson_d.hashtable_seed.hashtable_seed)))";
}

pragma(inline, true)
pure nothrow @trusted @nogc @live
private void list_init(scope .list_t* list)

	in
	{
		assert(list != null);
	}

	do
	{
		list.next = list;
		list.prev = list;
	}

pragma(inline, true)
pure nothrow @trusted @nogc @live
private void list_insert(scope .list_t* list, scope .list_t* node)

	in
	{
		assert(list != null);
		assert(node != null);
	}

	do
	{
		node.next = list;
		node.prev = list.prev;
		list.prev.next = node;
		list.prev = node;
	}

pragma(inline, true)
pure nothrow @trusted @nogc @live
private void list_remove(scope .list_t* list)

	in
	{
		assert(list != null);
	}

	do
	{
		list.prev.next = list.next;
		list.next.prev = list.prev;
	}

pragma(inline, true)
pure nothrow @trusted @nogc @live
private int bucket_is_empty(scope .hashtable_t* hashtable_, scope .bucket_t* bucket)

	in
	{
		assert(hashtable_ != null);
		assert(bucket != null);
	}

	do
	{
		return (bucket.first == &hashtable_.list) && (bucket.first == bucket.last);
	}

pure nothrow @trusted @nogc @live
private void insert_to_bucket(scope .hashtable_t* hashtable_, scope .bucket_t* bucket, scope .list_t* list)

	in
	{
		assert(bucket != null);
	}

	do
	{
		if (.bucket_is_empty(hashtable_, bucket)) {
			.list_insert(&hashtable_.list, list);
			bucket.first = bucket.last = list;
		} else {
			.list_insert(bucket.first, list);
			bucket.first = list;
		}
	}

pure nothrow @trusted @nogc @live
private .pair_t* hashtable_find_pair(scope .hashtable_t* hashtable_, scope .bucket_t* bucket, scope const char* key, size_t key_len, size_t hash)

	in
	{
		assert(bucket != null);
	}

	do
	{
		if (.bucket_is_empty(hashtable_, bucket)) {
			return null;
		}

		for (.list_t* list = bucket.first; true; list = list.next) {
			assert(list != null);
			.pair_t* pair = mixin (.list_to_pair!("list"));

			if ((pair.hash == hash) && (pair.key_len == key_len) && (core.stdc.string.memcmp(&(pair.key), key, key_len) == 0)) {
				return pair;
			}

			if (list == bucket.last) {
				break;
			}
		}

		return null;
	}

/* returns 0 on success, -1 if key was not found */
nothrow @trusted @nogc
private int hashtable_do_del(scope .hashtable_t* hashtable_, scope const char* key, size_t key_len, size_t hash)

	in
	{
		assert(hashtable_ != null);
	}

	do
	{
		size_t index = hash & mixin (jansson_d.lookup3.hashmask!("hashtable_.order"));
		.bucket_t* bucket = &hashtable_.buckets[index];

		.pair_t* pair = .hashtable_find_pair(hashtable_, bucket, key, key_len, hash);

		if (pair == null) {
			return -1;
		}

		scope (exit) {
			jansson_d.jansson_private.jsonp_free(pair);
		}

		if ((&pair.list == bucket.first) && (&pair.list == bucket.last)) {
			bucket.first = bucket.last = &hashtable_.list;
		} else if (&pair.list == bucket.first) {
			bucket.first = pair.list.next;
		} else if (&pair.list == bucket.last) {
			bucket.last = pair.list.prev;
		}

		.list_remove(&pair.list);
		.list_remove(&pair.ordered_list);
		jansson_d.jansson.json_decref(pair.value);

		hashtable_.size--;

		return 0;
	}

nothrow @trusted @nogc
private void hashtable_do_clear(scope .hashtable_t* hashtable_)

	in
	{
		assert(hashtable_ != null);
	}

	do
	{
		.list_t* next = void;

		for (.list_t* list = hashtable_.list.next; list != &hashtable_.list; list = next) {
			assert(list != null);
			next = list.next;
			.pair_t* pair = mixin (.list_to_pair!("list"));
			jansson_d.jansson.json_decref(pair.value);
			jansson_d.jansson_private.jsonp_free(pair);
		}
	}

nothrow @trusted @nogc
private int hashtable_do_rehash(scope .hashtable_t* hashtable_)

	in
	{
		assert(hashtable_ != null);
	}

	do
	{
		size_t new_order = hashtable_.order + 1;
		size_t new_size = mixin (jansson_d.lookup3.hashsize!("new_order"));

		.hashtable_bucket* new_buckets = cast(.hashtable_bucket*)(jansson_d.jansson_private.jsonp_malloc(new_size * .bucket_t.sizeof));

		if (new_buckets == null) {
			return -1;
		}

		jansson_d.jansson_private.jsonp_free(hashtable_.buckets);
		hashtable_.buckets = new_buckets;
		hashtable_.order = new_order;

		for (size_t i = 0; i < mixin (jansson_d.lookup3.hashsize!("hashtable_.order")); i++) {
			hashtable_.buckets[i].last = &hashtable_.list;
			hashtable_.buckets[i].first = &hashtable_.list;
		}

		.list_t* list = hashtable_.list.next;
		.list_init(&hashtable_.list);

		for (.list_t* next = void; list != &hashtable_.list; list = next) {
			assert(list != null);
			next = list.next;
			.pair_t* pair = mixin (.list_to_pair!("list"));
			size_t index = pair.hash % new_size;
			.insert_to_bucket(hashtable_, &hashtable_.buckets[index], &pair.list);
		}

		return 0;
	}

/**
 * Initialize a hashtable object
 *
 * Params:
 *      hashtable_ = The (statically allocated) hashtable object
 *
 * Initializes a statically allocated hashtable object. The object
 * should be cleared with hashtable_close when it's no longer used.
 *
 * Returns: 0 on success, -1 on error (out of memory).
 */
//nodiscard
nothrow @trusted @nogc
int hashtable_init(scope .hashtable_t* hashtable_)

	in
	{
		assert(hashtable_ != null);
	}

	do
	{
		hashtable_.size = 0;
		hashtable_.order = .INITIAL_HASHTABLE_ORDER;
		hashtable_.buckets = cast(.hashtable_bucket*)(jansson_d.jansson_private.jsonp_malloc(mixin (jansson_d.lookup3.hashsize!("hashtable_.order")) * .bucket_t.sizeof));

		if (hashtable_.buckets == null) {
			return -1;
		}

		.list_init(&hashtable_.list);
		.list_init(&hashtable_.ordered_list);

		for (size_t i = 0; i < mixin (jansson_d.lookup3.hashsize!("hashtable_.order")); i++) {
			hashtable_.buckets[i].last = &hashtable_.list;
			hashtable_.buckets[i].first = &hashtable_.list;
		}

		return 0;
	}

/**
 * Release all resources used by a hashtable object
 *
 * Params:
 *      hashtable_ = The hashtable
 *
 * Destroys a statically allocated hashtable object.
 */
nothrow @trusted @nogc
void hashtable_close(scope .hashtable_t* hashtable_)

	in
	{
		assert(hashtable_ != null);
	}

	do
	{
		.hashtable_do_clear(hashtable_);
		jansson_d.jansson_private.jsonp_free(hashtable_.buckets);
		hashtable_.buckets = null;
	}

nothrow @trusted @nogc
private .pair_t* init_pair(scope jansson_d.jansson.json_t* value, scope const char* key, size_t key_len, size_t hash)

	do
	{
		/*
		 * offsetof(...) returns the size of pair_t without the last,
		 * flexible member. This way, the correct amount is
		 * allocated.
		 */

		if (key_len >= (size_t.max - .pair_t.key.offsetof)) {
			/* Avoid an overflow if the key is very long */
			return null;
		}

		.pair_t* pair = cast(.pair_t*)(jansson_d.jansson_private.jsonp_malloc(.pair_t.key.offsetof + key_len + 1));

		if (pair == null) {
			return null;
		}

		pair.hash = hash;
		core.stdc.string.memcpy(&(pair.key), key, key_len);
		*(cast(char*)((&(pair.key))) + key_len) = '\0';
		pair.key_len = key_len;
		pair.value = value;

		.list_init(&pair.list);
		.list_init(&pair.ordered_list);

		return pair;
	}

/**
 * Add/modify value in hashtable
 *
 * Params:
 *      hashtable_ = The hashtable object
 *      key = The key
 *      key_len = The length of key
 *      value = The value
 *
 * If a value with the given key already exists, its value is replaced
 * with the new value. Value is "stealed" in the sense that hashtable
 * doesn't increment its refcount but decreases the refcount when the
 * value is no longer needed.
 *
 * Returns: 0 on success, -1 on failure (out of memory).
 */
/*
 * Params:
 *      serial = For addition order of keys
 */
nothrow @trusted @nogc
int hashtable_set(scope .hashtable_t* hashtable_, scope const char* key, size_t key_len, scope jansson_d.jansson.json_t* value)

	in
	{
		assert(hashtable_ != null);
	}

	do
	{
		/* rehash if the load ratio exceeds 1 */
		if (hashtable_.size >= mixin (jansson_d.lookup3.hashsize!("hashtable_.order"))) {
			if (.hashtable_do_rehash(hashtable_)) {
				return -1;
			}
		}

		size_t hash = mixin (.hash_str!("key", "key_len"));
		size_t index = hash & mixin (jansson_d.lookup3.hashmask!("hashtable_.order"));
		.bucket_t* bucket = &hashtable_.buckets[index];
		.pair_t* pair = .hashtable_find_pair(hashtable_, bucket, key, key_len, hash);

		if (pair != null) {
			jansson_d.jansson.json_decref(pair.value);
			pair.value = value;
		} else {
			pair = .init_pair(value, key, key_len, hash);

			if (pair == null) {
				return -1;
			}

			.insert_to_bucket(hashtable_, bucket, &pair.list);
			.list_insert(&hashtable_.ordered_list, &pair.ordered_list);

			hashtable_.size++;
		}

		return 0;
	}

/**
 * Get a value associated with a key
 *
 * Params:
 *      hashtable_ = The hashtable object
 *      key = The key
 *      key_len = The length of key
 *
 * Returns: value if it is found, or null otherwise.
 */
nothrow @trusted @nogc @live
void* hashtable_get(scope .hashtable_t* hashtable_, scope const char* key, size_t key_len)

	in
	{
		assert(hashtable_ != null);
	}

	do
	{
		size_t hash = mixin (.hash_str!("key", "key_len"));
		.bucket_t* bucket = &hashtable_.buckets[hash & mixin (jansson_d.lookup3.hashmask!("hashtable_.order"))];

		.pair_t* pair = .hashtable_find_pair(hashtable_, bucket, key, key_len, hash);

		if (pair == null) {
			return null;
		}

		return pair.value;
	}

/**
 * Remove a value from the hashtable
 *
 * Params:
 *      hashtable_ = The hashtable object
 *      key = The key
 *      key_len = The length of key
 *
 * Returns: 0 on success, or -1 if the key was not found.
 */
nothrow @trusted @nogc
int hashtable_del(scope .hashtable_t* hashtable_, scope const char* key, size_t key_len)

	do
	{
		size_t hash = mixin (.hash_str!("key", "key_len"));

		return .hashtable_do_del(hashtable_, key, key_len, hash);
	}

/**
 * Clear hashtable
 *
 * Params:
 *      hashtable_ = The hashtable object
 *
 * Removes all items from the hashtable.
 */
nothrow @trusted @nogc
void hashtable_clear(scope .hashtable_t* hashtable_)

	in
	{
		assert(hashtable_ != null);
	}

	do
	{
		.hashtable_do_clear(hashtable_);

		for (size_t i = 0; i < mixin (jansson_d.lookup3.hashsize!("hashtable_.order")); i++) {
			hashtable_.buckets[i].first = hashtable_.buckets[i].last = &hashtable_.list;
		}

		.list_init(&hashtable_.list);
		.list_init(&hashtable_.ordered_list);
		hashtable_.size = 0;
	}

/**
 * Iterate over hashtable
 *
 * Params:
 *      hashtable_ = The hashtable object
 *
 * Returns an opaque iterator to the first element in the hashtable.
 * The iterator should be passed to hashtable_iter_* functions.
 * The hashtable items are not iterated over in any particular order.
 *
 * There's no need to free the iterator in any way. The iterator is
 * valid as long as the item that is referenced by the iterator is not
 * deleted. Other values may be added or deleted. In particular,
 * hashtable_iter_next() may be called on an iterator, and after that
 * the key/value pair pointed by the old iterator may be deleted.
 */
pure nothrow @trusted @nogc @live
void* hashtable_iter(scope .hashtable_t* hashtable_)

	in
	{
		assert(hashtable_ != null);
	}

	do
	{
		return .hashtable_iter_next(hashtable_, &hashtable_.ordered_list);
	}

/**
 * Return an iterator at a specific key
 *
 * Params:
 *      hashtable_ = The hashtable object
 *      key = The key that the iterator should point to
 *      key_len = The length of key
 *
 * Like hashtable_iter() but returns an iterator pointing to a
 * specific key.
 */
nothrow @trusted @nogc @live
void* hashtable_iter_at(scope .hashtable_t* hashtable_, scope const char* key, size_t key_len)

	in
	{
		assert(hashtable_ != null);
	}

	do
	{
		size_t hash = mixin (.hash_str!("key", "key_len"));
		.bucket_t* bucket = &hashtable_.buckets[hash & mixin (jansson_d.lookup3.hashmask!("hashtable_.order"))];

		.pair_t* pair = .hashtable_find_pair(hashtable_, bucket, key, key_len, hash);

		if (pair == null) {
			return null;
		}

		return &pair.ordered_list;
	}

/**
 * Advance an iterator
 *
 * Params:
 *      hashtable_ = The hashtable object
 *      iter = The iterator
 *
 * Returns: a new iterator pointing to the next element in the hashtable or null if the whole hastable has been iterated over.
 */
pure nothrow @trusted @nogc @live
void* hashtable_iter_next(scope .hashtable_t* hashtable_, scope void* iter)

	in
	{
		assert(hashtable_ != null);
		assert(iter != null);
	}

	do
	{
		.list_t* list = cast(.list_t*)(iter);

		if (list.next == &hashtable_.ordered_list) {
			return null;
		}

		return list.next;
	}

/**
 * Retrieve the key pointed by an iterator
 *
 * Params:
 *      iter = The iterator
 */
pure nothrow @trusted @nogc @live
void* hashtable_iter_key(scope void* iter)

	in
	{
		assert(iter != null);
	}

	do
	{
		.pair_t* pair = mixin (.ordered_list_to_pair!("cast(.list_t*)(iter)"));

		return &(pair.key);
	}

/**
 * Retrieve the key length pointed by an iterator
 *
 * Params:
 *      iter = The iterator
 */
pure nothrow @trusted @nogc @live
size_t hashtable_iter_key_len(scope void* iter)

	in
	{
		assert(iter != null);
	}

	do
	{
		.pair_t* pair = mixin (.ordered_list_to_pair!("cast(.list_t*)(iter)"));

		return pair.key_len;
	}

/**
 * Retrieve the value pointed by an iterator
 *
 * Params:
 *      iter = The iterator
 */
pure nothrow @trusted @nogc @live
void* hashtable_iter_value(scope void* iter)

	in
	{
		assert(iter != null);
	}

	do
	{
		.pair_t* pair = mixin (.ordered_list_to_pair!("cast(.list_t*)(iter)"));

		return pair.value;
	}

/**
 * Set the value pointed by an iterator
 *
 * Params:
 *      iter = The iterator
 *      value = The value to set
 */
nothrow @trusted @nogc
void hashtable_iter_set(scope void* iter, scope jansson_d.jansson.json_t* value)

	in
	{
		assert(iter != null);
	}

	do
	{
		.pair_t* pair = mixin (.ordered_list_to_pair!("cast(.list_t*)(iter)"));

		jansson_d.jansson.json_decref(pair.value);
		pair.value = value;
	}
