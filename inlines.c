
#include "inlines.h"
#include "mem.h"
#include <stdio.h>

d_tok d_tok_init(s_node_type type, int can_open, uint32_t start, uint32_t end) {
	d_tok tok = {
		type,
		can_open,
		start,
		end,
		EVENT_NONE
	};
	
	return tok;
}

int d_tok_can_close(d_tok tok) {
	return tok.type == S_NODE_EMPHASIS || tok.type == S_NODE_STRONG || !tok.can_open;
}

delim_stack *delim_stack_new() {
	delim_stack *st = c_malloc(sizeof(delim_stack));
	
	size_t cap = 8;
	
	st->first = c_malloc(cap * sizeof(d_tok));
	st->lb = 0;
	st->len = 0;
	st->cap = cap;
	
	return st;
}

void delim_stack_free(delim_stack *st) {
	free(st->first);
	
	free(st);
}

void delim_stack_resize(delim_stack *st, size_t target) {
	st->first = c_realloc(st->first, target * sizeof(d_tok));
	
	st->cap = target;
}

void delim_stack_push(delim_stack *st, d_tok tok) {
	if (st->len >= st->cap)
		delim_stack_resize(st, st->cap * 2);
	
	st->first[st->len++] = tok;
}

void delim_stack_reset(delim_stack *st) {
	st->len = 0;
	st->lb = 0;
}

#define delim_stack_peek_at(st, idx) st->first + idx

int delim_stack_scan_for_last_matchable_tok(delim_stack *st, size_t *idx, d_tok tok) {
	size_t i = st->len;
	
	while (i > st->lb) {
		d_tok *p = delim_stack_peek_at(st, --i);
		
		if (p->type == tok.type && p->can_open && p->event == EVENT_NONE) {
			*idx = i;
			return 1;
		} else if (p->type > tok.type) {
			break;
		}
	}
	
	return 0;
}

void scan_for_tokens(Scanner *s, int handle_parens) {
	delim_stack_reset(s->tokens);
	delim_stack *st = s->tokens;
	
	d_tok tok;
	while (scan_d_tok(s, &tok, handle_parens)) {
		// If comment, add appropriate tokens to stack and break the loop. Comments take up the rest of a line.
		if (tok.type == S_NODE_COMMENT) {
			d_tok ctok = d_tok_init(S_NODE_COMMENT, 0, s->ewc, s->ewc);
			tok.event = EVENT_ENTER;
			ctok.event = EVENT_EXIT;
			delim_stack_push(st, tok);
			delim_stack_push(st, ctok);
			break;
		}
		
		// Scan stack backward for last matchable ptok with precedence > tok. If none found but tok can open, push to stack
		size_t idx;
		if (delim_stack_scan_for_last_matchable_tok(st, &idx, tok)) {
			// Found match. Set tokens to enter and exit.
			d_tok *ptok = delim_stack_peek_at(st, idx);
			ptok->event = EVENT_ENTER;
			tok.event = EVENT_EXIT;
			delim_stack_push(st, tok);
			
			// If idx was the stack's lower bound, advance lower bound to next unmatched token
			if (idx == st->lb) {
				for (; st->lb<st->len; ++st->lb) {
					d_tok *atok = delim_stack_peek_at(st, st->lb);
					
					if (atok->event == EVENT_NONE)
						break;
				}
			}
		} else if (tok.can_open) {
			delim_stack_push(st, tok);
		}
	}
}

void construct_ast(Scanner *s, pool *p, s_node *node, uint32_t ewc) {
	delim_stack *st = s->tokens;
	
	s_node *active_parent = node;
	uint32_t last_idx = node->range.start;
	
	for (size_t i = 0; i < st->len; ++i) {
		d_tok *tok = delim_stack_peek_at(st, i);
		
		if (tok->event == EVENT_NONE)
			continue;
		
		if (tok->start > last_idx) {
			s_node *literal = pool_create_node(p, S_NODE_LITERAL, last_idx, tok->start);
			s_node_add_child(active_parent, literal);
		}
		
		if (tok->event == EVENT_ENTER) {
			s_node *tnode = pool_create_node(p, tok->type, tok->start, tok->end);
			s_node_add_child(active_parent, tnode);
			active_parent = tnode;
			last_idx = tok->end;
		} else if (tok->event == EVENT_EXIT) {
			active_parent->range.end = tok->end;
			active_parent = active_parent->parent;
			last_idx = tok->end;
		}
	}
	
	// If any space is left over from the stack, fill with a literal node
	if (last_idx < node->range.end) {
		s_node *literal = pool_create_node(p, S_NODE_LITERAL, last_idx, ewc);
		s_node_add_child(active_parent, literal);
	}
}

void parse_inlines_for_node(Scanner *s, pool *p, s_node *node, int handle_parens) {
	s->loc = node->range.start;
	s->wc = node->range.start;
	s->ewc = node->range.end;
	
	scan_for_tokens(s, handle_parens);
	
	construct_ast(s, p, node, s->ewc);
}
