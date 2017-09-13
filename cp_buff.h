
#ifndef cp_buff_h
#define cp_buff_h

#include <stdint.h>

typedef struct {
	uint32_t cp;
	size_t loc;
	size_t len;
} cp_tok;

size_t cp_tok_max_range(cp_tok tok);

typedef struct {
	cp_tok *begin;
	size_t len;
	size_t cap;
} cp_buff;

cp_buff * cp_buff_new(size_t cap);

void cp_buff_free(cp_buff * st);

void cp_buff_append(cp_buff * st, cp_tok item);

cp_tok cp_buff_item_at(cp_buff * st, size_t idx);

cp_tok * cp_buff_first(cp_buff * st);

cp_tok * cp_buff_last(cp_buff * st);

#endif /* cp_buff_h */
