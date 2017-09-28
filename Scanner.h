
#ifndef scanner_h
#define scanner_h

#include <stdint.h>
#include "nodes.h"
#include "pool.h"

typedef struct d_tok d_tok;

typedef struct delim_stack delim_stack;

typedef struct {
	const char *buff;
	uint32_t len;
	uint32_t bol, eol, loc;
	uint32_t wc, ewc;
	delim_stack *tokens;
} Scanner;

Scanner *scanner_new(const char *buff, uint32_t len);

void scanner_free(Scanner *s);

int scanner_is_at_eol(Scanner *s);

uint32_t scanner_advance_to_next_line(Scanner *s);

void scanner_trim_whitespace(Scanner *s);

s_node *scan_for_thematic_break(Scanner *s, pool *p);

s_node *scan_for_forced_header(Scanner *s, pool *p);

s_node *scan_for_header(Scanner *s, pool *p);

s_node *scan_for_end(Scanner *s, pool *p);

s_node *scan_for_facsimile(Scanner *s, pool *p);

s_node *scan_for_lyric_line(Scanner *s, pool *p);

s_node *scan_for_cue(Scanner *s, pool *p);

int scan_d_tok(Scanner *s, d_tok *out, int handle_parens);

#endif /* scanner_h */
