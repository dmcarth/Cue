
#include "stack.h"
#include "mem.h"
#include <assert.h>
#include <string.h>

stack *stack_new(size_t cap, size_t esize) {
	stack *st = c_malloc(sizeof(stack));
	
	st->first = c_malloc(cap * esize);
	st->esize = esize;
	st->cap = cap;
	st->len = 0;
	
	return st;
}

void stack_free(stack *st) {
	free(st->first);
	
	free(st);
}

void stack_resize(stack *st, size_t target) {
	st->first = c_realloc(st->first, target * st->esize);
	
	st->cap = target;
}

void stack_append(stack *st, const void *item) {
	if (st->len >= st->cap)
		stack_resize(st, st->cap * 2);
	
	memcpy(st->first + st->len++ * st->esize, item, st->esize);
}

void stack_remove_last(stack *st, size_t items) {
	assert(items <= st->len);
	
	st->len -= items;
}
