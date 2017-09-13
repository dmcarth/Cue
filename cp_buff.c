
#include "cp_buff.h"
#include <stdlib.h>

size_t cp_tok_max_range(cp_tok tok) {
	return tok.loc + tok.len;
}

cp_buff * cp_buff_new(size_t cap) {
	cp_tok * begin = malloc(cap * sizeof(cp_tok));
	
	cp_buff * st = malloc(sizeof(cp_buff));
	
	st->begin = begin;
	st->len = 0;
	st->cap = cap;
	
	return st;
}

void cp_buff_free(cp_buff * st) {
	if (!st)
		return;
	
	free(st->begin);
	
	free(st);
}

void cp_buff_resize(cp_buff * st, size_t target) {
	st->begin = realloc(st->begin, target*sizeof(cp_tok));
	
	st->cap = target;
}

void cp_buff_append(cp_buff * st, cp_tok item) {
	if (st->len >= st->cap)
		cp_buff_resize(st, st->cap * 2);
	
	st->begin[st->len] = item;
	
	st->len++;
}

cp_tok cp_buff_item_at(cp_buff * st, size_t idx) {
	return st->begin[idx];
}

cp_tok * cp_buff_first(cp_buff * st) {
	return st->begin;
}

cp_tok * cp_buff_last(cp_buff * st) {
	return st->begin + st->len - 1;
}
