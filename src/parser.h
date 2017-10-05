
#ifndef parser_h
#define parser_h

#include <stdint.h>

#include "nodes.h"
#include "Scanner.h"
#include "inlines.h"

typedef struct {
	NodeAllocator *node_allocator;
	ASTNode *root;
	Scanner *scanner;
	DelimiterStack *delimiter_stack;
	
	/** This data is currently being stored in `scanner` and should probably
	 * be used from here instead.
	 */
	uint32_t bol, eol;
	uint32_t first_nonspace, last_nonspace;
} CueParser;

#endif /* parser_h */
