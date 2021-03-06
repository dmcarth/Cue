
#include "inlines.h"
#include "mem.h"

DelimiterToken delimiter_token_init(ASTNodeType type,
									int can_open,
									uint32_t location,
									uint32_t length)
{
    SRange range = { location, length };
    
	DelimiterToken tok = {
		type,
		can_open,
		range,
		EVENT_NONE
	};
	
	return tok;
}

int DelimiterToken_can_close(DelimiterToken tok)
{
	return tok.type == S_NODE_EMPHASIS || tok.type == S_NODE_STRONG || !tok.can_open;
}

DelimiterStack *delimiter_stack_new()
{
	DelimiterStack *st = c_malloc(sizeof(DelimiterStack));
	
	size_t cap = 8;
	
	st->first = c_malloc(cap * sizeof(DelimiterToken));
	st->lb = 0;
	st->len = 0;
	st->cap = cap;
	
	return st;
}

void delimiter_stack_free(DelimiterStack *st)
{
	free(st->first);
	
	free(st);
}

void delimiter_stack_resize(DelimiterStack *st,
                            size_t target)
{
	st->first = c_realloc(st->first, target * sizeof(DelimiterToken));
	
	st->cap = target;
}

void delimiter_stack_push(DelimiterStack *st,
                          DelimiterToken tok)
{
	if (st->len >= st->cap)
		delimiter_stack_resize(st, st->cap * 1.5);
	
	st->first[st->len++] = tok;
}

void delimiter_stack_reset(DelimiterStack *st)
{
	st->len = 0;
	st->lb = 0;
}

#define delimiter_stack_peek_at(st, idx) st->first + idx

int delimiter_stack_scan_for_last_matchable_tok(DelimiterStack *st,
												size_t *idx,
												DelimiterToken tok)
{
	size_t i = st->len;
	
	while (i > st->lb) {
		DelimiterToken *p = delimiter_stack_peek_at(st, --i);
		
		if (p->type == tok.type && p->can_open && p->event == EVENT_NONE) {
			*idx = i;
			return 1;
		} else if (p->type > tok.type) {
			break;
		}
	}
	
	return 0;
}

void scan_for_tokens(CueParser *parser,
                     int handle_parens)
{
	DelimiterStack *st = parser->delimiter_stack;
	delimiter_stack_reset(st);
	
	Scanner *s = parser->scanner;
	
	DelimiterToken tok;
	while (scan_delimiter_token(parser->scanner, handle_parens, &tok)) {
		// If comment, add appropriate tokens to stack and break the loop. Comments take up the rest of a line.
		if (tok.type == S_NODE_COMMENT) {
			DelimiterToken ctok = delimiter_token_init(S_NODE_COMMENT, 0, s->ewc, 0);
			tok.event = EVENT_ENTER;
			ctok.event = EVENT_EXIT;
			delimiter_stack_push(st, tok);
			delimiter_stack_push(st, ctok);
			break;
		}
		
		// Scan stack backward for last matchable ptok with precedence > tok. If none found but tok can open, push to stack
		size_t idx;
		if (delimiter_stack_scan_for_last_matchable_tok(st, &idx, tok)) {
			// Found match. Set tokens to enter and exit.
			DelimiterToken *ptok = delimiter_stack_peek_at(st, idx);
			ptok->event = EVENT_ENTER;
			tok.event = EVENT_EXIT;
			delimiter_stack_push(st, tok);
			
			// If idx was the stack's lower bound, advance lower bound to next unmatched token
			if (idx == st->lb) {
				for (; st->lb<st->len; ++st->lb) {
					DelimiterToken *atok = delimiter_stack_peek_at(st, st->lb);
					
					if (atok->event == EVENT_NONE)
						break;
				}
			}
		} else if (tok.can_open) {
			delimiter_stack_push(st, tok);
		}
	}
}

void construct_ast(CueParser *parser, ASTNode *node, uint32_t ewc)
{
	DelimiterStack *st = parser->delimiter_stack;
	
	ASTNode *active_parent = node;
	uint32_t last_idx = node->range.location;
	
	for (size_t i = 0; i < st->len; ++i) {
		DelimiterToken *tok = delimiter_stack_peek_at(st, i);
		
		if (tok->event == EVENT_NONE)
			continue;
		
		if (tok->range.location > last_idx) {
			ASTNode *literal = ast_node_new(parser->node_allocator, S_NODE_LITERAL, last_idx, tok->range.location - last_idx);
			ast_node_add_child(active_parent, literal);
		}
		
		if (tok->event == EVENT_ENTER) {
			ASTNode *tnode = ast_node_new(parser->node_allocator, tok->type, tok->range.location, tok->range.length);
			ast_node_add_child(active_parent, tnode);
			active_parent = tnode;
			last_idx = s_range_max(tok->range);
		} else if (tok->event == EVENT_EXIT) {
            active_parent->range.length = s_range_max(tok->range) - active_parent->range.location;
			active_parent = active_parent->parent;
			last_idx = s_range_max(tok->range);
		}
	}
	
	// If any space is left over from the stack, fill with a literal node
	if (last_idx < s_range_max(node->range)) {
		ASTNode *literal = ast_node_new(parser->node_allocator, S_NODE_LITERAL, last_idx, ewc - last_idx);
		ast_node_add_child(active_parent, literal);
	}
}

void parse_inlines_for_node(CueParser *parser,
                            ASTNode *node,
							int handle_parens)
{
	Scanner *s = parser->scanner;
	s->loc = node->range.location;
	s->wc = s->loc;
	s->ewc = s_range_max(node->range);
	
	scan_for_tokens(parser, handle_parens);
	
	construct_ast(parser, node, s->ewc);
}
