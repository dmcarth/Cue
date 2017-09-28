
#ifndef scanners_h
#define scanners_h

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
} scanner;

scanner *scanner_new(const char *buff, uint32_t len);

void scanner_free(scanner *s);

int scanner_is_at_eol(scanner *s);

uint32_t scanner_advance_to_next_line(scanner *s);

void scanner_trim_whitespace(scanner *s);

s_node *scan_for_thematic_break(scanner *s, pool *p);

s_node *scan_for_forced_header(scanner *s, pool *p);

s_node *scan_for_header(scanner *s, pool *p);

s_node *scan_for_end(scanner *s, pool *p);

s_node *scan_for_facsimile(scanner *s, pool *p);

s_node *scan_for_lyric_line(scanner *s, pool *p);

s_node *scan_for_cue(scanner *s, pool *p);

int scan_d_tok(scanner *s, d_tok *out, int handle_parens);

#endif /* scanners_h */
