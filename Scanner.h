
#ifndef scanner_h
#define scanner_h

#include <stdint.h>
#include "nodes.h"
#include "pool.h"

typedef struct DelimiterToken DelimiterToken;

typedef struct DelimiterStack DelimiterStack;

typedef struct
{
	const char *buff;
	uint32_t len;
	uint32_t bol, eol, loc;
	uint32_t wc, ewc;
} Scanner;

Scanner *scanner_new(const char *buff, uint32_t len);

void scanner_free(Scanner *s);

int scanner_is_at_eol(Scanner *s);

uint32_t scanner_advance_to_next_line(Scanner *s);

void scanner_trim_whitespace(Scanner *s);

CueNode *scan_for_thematic_break(Scanner *s, Pool *p);

CueNode *scan_for_forced_header(Scanner *s, Pool *p);

CueNode *scan_for_header(Scanner *s, Pool *p);

CueNode *scan_for_end(Scanner *s, Pool *p);

CueNode *scan_for_facsimile(Scanner *s, Pool *p);

CueNode *scan_for_lyric_line(Scanner *s, Pool *p);

CueNode *scan_for_cue(Scanner *s, Pool *p);

int scan_delimiter_token(Scanner *s, int handle_parens, DelimiterToken *out);

#endif /* scanner_h */
