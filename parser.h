
#ifndef parser_h
#define parser_h

#include <stdint.h>
#include "pool.h"
#include "nodes.h"
#include "Scanner.h"
#include "inlines.h"

struct CueParser
{
	Pool *node_allocator;
	CueNode *root;
	Scanner *scanner;
	DelimiterStack *delimiter_stack;
	
	/** This data is currently being stored in `scanner` and should probably
	 * be used from here instead.
	 */
	uint32_t bol, eol;
	uint32_t first_nonspace, last_nonspace;
};

#endif /* parser_h */
