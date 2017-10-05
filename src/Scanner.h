
#ifndef scanner_h
#define scanner_h

#include <stdint.h>

#include "nodes.h"

typedef struct DelimiterToken DelimiterToken;

typedef struct DelimiterStack DelimiterStack;

typedef struct
{
	const char *source;
	uint32_t length;
	uint32_t bol, eol, loc;
	uint32_t wc, ewc;
} Scanner;

Scanner *scanner_new(const char *source,
					 uint32_t length);

void scanner_free(Scanner *s);

int scanner_is_at_eol(Scanner *s);

uint32_t scanner_advance_to_next_line(Scanner *s);

void scanner_trim_whitespace(Scanner *s);

ASTNode *scan_for_thematic_break(Scanner *s,
								 NodeAllocator *node_allocator);

ASTNode *scan_for_forced_header(Scanner *s,
								NodeAllocator *node_allocator);

ASTNode *scan_for_header(Scanner *s,
						 NodeAllocator *node_allocator);

ASTNode *scan_for_end(Scanner *s,
					  NodeAllocator *node_allocator);

ASTNode *scan_for_facsimile(Scanner *s,
							NodeAllocator *node_allocator);

ASTNode *scan_for_lyric_line(Scanner *s,
							 NodeAllocator *node_allocator);

ASTNode *scan_for_cue(Scanner *s,
					  NodeAllocator *node_allocator);

int scan_delimiter_token(Scanner *s,
						 int handle_parens,
						 DelimiterToken *out);

#endif /* scanner_h */
