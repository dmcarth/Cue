
#ifndef inlines_h
#define inlines_h

#include <stdint.h>
#include "Scanner.h"
#include "Walker.h"

struct d_tok {
	s_node_type type;
	int can_open;
	uint32_t start, end;
	WalkerEvent event;
};

struct delim_stack {
	d_tok *first;
	size_t lb;
	size_t len;
	size_t cap;
};

d_tok d_tok_init(s_node_type type, int can_open, uint32_t start, uint32_t end);

delim_stack *delim_stack_new(void);

void delim_stack_free(delim_stack *st);

void parse_inlines_for_node(Scanner *s, pool *p, s_node *node, int handle_parens);

#endif /* inlines_h */
