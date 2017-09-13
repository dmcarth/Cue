
#ifndef stack_h
#define stack_h

#include <stddef.h>

typedef struct {
	void *first;
	size_t esize;
	size_t cap;
	size_t len;
} stack;

stack *stack_new(size_t cap, size_t esize);

void stack_free(stack *st);

void stack_append(stack *st, const void *item);

void stack_remove_last(stack *st, size_t items);

#define stack_peek_at(st, idx) (st->first + st->esize * idx)

#define stack_iter_begin(st) st->first

#define stack_iter_end(st) st->first + st->esize * st->len

#endif /* stack_h */
