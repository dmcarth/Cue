
#ifndef inlines_h
#define inlines_h

#include <stdint.h>
#include <stddef.h>

#include "parser.h"
#include "Scanner.h"
#include "Walker.h"

struct DelimiterToken
{
	ASTNodeType type;
	int can_open;
	SRange range;
	WalkerEvent event;
};

struct DelimiterStack
{
	DelimiterToken *first;
	size_t lb;
	size_t len;
	size_t cap;
};

DelimiterToken delimiter_token_init(ASTNodeType type,
									int can_open,
									uint32_t location,
									uint32_t length);

DelimiterStack *delimiter_stack_new(void);

void delimiter_stack_free(DelimiterStack *st);

void parse_inlines_for_node(CueParser *parser,
							ASTNode *node,
							int handle_parens);

#endif /* inlines_h */
