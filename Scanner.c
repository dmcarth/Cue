
#include "Scanner.h"
#include "inlines.h"
#include "mem.h"

Scanner *scanner_new(const char *buff, uint32_t len)
{
	Scanner *s = c_calloc(1, sizeof(Scanner));
	
	s->buff = buff;
	s->len = len;
	s->tokens = delimiter_stack_new();
	
	return s;
}

void scanner_free(Scanner *s)
{
	delimiter_stack_free(s->tokens);
	
	free(s);
}

int scanner_is_at_eol(Scanner *s)
{
	// For scanning purposes, ewc == eol
	return s->loc == s->ewc;
}

/* true if buff[loc - 1] == '\' */
static int scanner_loc_is_escaped(Scanner *s)
{
	return s->loc && (s->buff[s->loc-1] == '\\');
}

/*	Cue ignores whitespace so we can safely ignore the "\r\n" case (the parser will interpret '\n' as an empty line and discard it). */
static inline int is_newline(char c)
{
	return c == '\n' || c == 11 || c == 12 || c == '\r';
}

static inline int is_whitespace(char c)
{
	return c == ' ' || c == '\t' || is_newline(c);
}

uint32_t scanner_advance_to_next_line(Scanner *s)
{
	s->bol = s->eol;
	s->loc = s->bol;
	
	while (s->eol < s->len) {
		uint32_t bt = s->eol++;
		if (is_newline(s->buff[bt]))
			break;
	}
	
	scanner_trim_whitespace(s);
	
	return s->bol;
}

uint32_t scanner_advance_to_first_nonspace(Scanner *s)
{
	while (s->loc < s->ewc) {
		if (is_whitespace(s->buff[s->loc]))
			++(s->loc);
		else
			break;
	}
	
	return s->loc;
}

uint32_t scanner_advance_to_hyphen(Scanner *s)
{
	while (s->loc < s->ewc) {
		if (s->buff[s->loc] == '-' && !scanner_loc_is_escaped(s))
			break;
		else
			++(s->loc);
	}
	
	return s->loc;
}

uint32_t scanner_backtrack_to_first_nonspace(Scanner *s)
{
	while (s->loc > s->wc) {
		uint32_t bt = s->loc - 1;
		
		if (is_whitespace(s->buff[bt]))
			s->loc = bt;
		else
			break;
	}
	
	return s->loc;
}

uint32_t scanner_advance_to_colon(Scanner *s, uint32_t bound)
{
	uint32_t start = s->loc;
	
	while (s->loc < s->ewc) {
		if (s->loc - start > bound)
			break;
		
		if (s->buff[s->loc] == ':' && !scanner_loc_is_escaped(s))
			break;
		else
			++(s->loc);
	}
	
	return s->loc;
}

void scanner_trim_whitespace(Scanner *s)
{
	// trim left
	scanner_advance_to_first_nonspace(s);
	s->wc = s->loc;
	
	// trim right
	s->loc = s->eol;
	scanner_backtrack_to_first_nonspace(s);
	s->ewc = s->loc;
	
	// reset loc
	s->loc = s->wc;
}

/* The following functions all advance the scanner if they match at the scanner's current location. If no match is found, they return 0 and do not advance the scanner. */

int scan_for_act(Scanner *s)
{
	if (s->ewc - s->loc < 3)
		return 0;
	
	uint32_t loc = s->loc;
	if (s->buff[loc++] == 'A' &&
		s->buff[loc++] == 'c' &&
		s->buff[loc++] == 't') {
		s->loc = loc;
		
		return 1;
	}
	
	return 0;
}

int scan_for_scene(Scanner *s)
{
	if (s->ewc - s->loc < 5)
		return 0;
	
	uint32_t loc = s->loc;
	if (s->buff[loc++] == 'S' &&
		s->buff[loc++] == 'c' &&
		s->buff[loc++] == 'e' &&
		s->buff[loc++] == 'n' &&
		s->buff[loc++] == 'e') {
		s->loc = loc;
		
		return 1;
	}
	
	return 0;
}

int scan_for_page(Scanner *s)
{
	if (s->ewc - s->loc < 4)
		return 0;
	
	uint32_t loc = s->loc;
	if (s->buff[loc++] == 'P' &&
		s->buff[loc++] == 'a' &&
		s->buff[loc++] == 'g' &&
		s->buff[loc++] == 'e') {
		s->loc = loc;
		
		return 1;
	}
	
	return 0;
}

int scan_for_frame(Scanner *s)
{
	if (s->ewc - s->loc < 5)
		return 0;
	
	uint32_t loc = s->loc;
	if (s->buff[loc++] == 'F' &&
		s->buff[loc++] == 'r' &&
		s->buff[loc++] == 'a' &&
		s->buff[loc++] == 'm' &&
		s->buff[loc++] == 'e') {
		s->loc = loc;
		
		return 1;
	}
	
	return 0;
}

/* The following are node factories. If scanning succeeds, they construct a node for the AST. */

CueNode *scan_for_thematic_break(Scanner *s, Pool *p)
{
	if (s->ewc - s->loc < 3)
		return NULL;
	
	uint32_t loc = s->loc;
	while (loc < s->ewc) {
		if (s->buff[loc] == '-' && !scanner_loc_is_escaped(s))
			++loc;
		else
			break;
	}
	
	if (loc - s->loc < 3)
		return NULL;
	
	scanner_advance_to_first_nonspace(s);
	
	if (!scanner_is_at_eol(s)) {
		s->loc = loc;
		
		return NULL;
	}
	
	return pool_create_node(p, S_NODE_THEMATIC_BREAK, s->bol, s->eol);
}

CueNode *scan_title(Scanner *s, Pool *p)
{
	CueNode *title = NULL;
	
	if (!scanner_is_at_eol(s)) {
		uint32_t tstart = scanner_advance_to_first_nonspace(s);
		
		title = pool_create_node(p, S_NODE_TITLE, tstart, s->ewc);
	}
	
	return title;
}

CueNode *scan_for_forced_header(Scanner *s, Pool *p)
{
	if (s->ewc - s->loc < 1 || s->buff[s->loc] != '.')
		return NULL;
	
	uint32_t kstart = ++(s->loc);
	uint32_t hstart = scanner_advance_to_hyphen(s);
	uint32_t kend = scanner_backtrack_to_first_nonspace(s);
	s->loc = hstart + 1;
	
	CueNode *head = pool_create_node(p, S_NODE_HEADER, s->bol, s->eol);
	
	CueNode *key = pool_create_node(p, S_NODE_KEYWORD, kstart, kend);
	cue_node_add_child(head, key);
	
	CueNode *title = scan_title(s, p);
	cue_node_add_child(head, title);
	
	head->data.header.type = HEADER_FORCED;
	head->data.header.keyword = key;
	head->data.header.title = title;
	
	return head;
}

CueNode *scan_for_header(Scanner *s, Pool *p)
{
	HeaderType type;
	uint32_t kstart = s->loc;
	uint32_t kend = s->loc;
	
	if (scan_for_act(s)) {
		type = HEADER_ACT;
		kend += 3;
	} else if (scan_for_scene(s)) {
		type = HEADER_SCENE;
		kend += 5;
	} else if (scan_for_page(s)) {
		type = HEADER_PAGE;
		kend += 4;
	} else if (scan_for_frame(s)) {
		type = HEADER_FRAME;
		kend += 5;
	} else {
		return NULL;
	}
	uint32_t istart = scanner_advance_to_first_nonspace(s);
	
	if (scanner_is_at_eol(s))
		return NULL;
	
	uint32_t hstart = scanner_advance_to_hyphen(s);
	uint32_t iend = scanner_backtrack_to_first_nonspace(s);
	
	s->loc = hstart + 1;
	
	CueNode *head = pool_create_node(p, S_NODE_HEADER, s->bol, s->eol);
	
	CueNode *key = pool_create_node(p, S_NODE_KEYWORD, kstart, kend);
	cue_node_add_child(head, key);
	
	CueNode *id = NULL;
	if (istart < iend) {
		id = pool_create_node(p, S_NODE_IDENTIFIER, istart, iend);
		cue_node_add_child(head, id);
	}
	
	CueNode *title = scan_title(s, p);
	cue_node_add_child(head, title);
	
	head->data.header.type = type;
	head->data.header.keyword = key;
	head->data.header.id = id;
	head->data.header.title = title;
	
	return head;
}

CueNode *scan_for_end(Scanner *s, Pool *p)
{
	if (s->ewc - s->loc != 7)
		return NULL;
	
	uint32_t loc = s->loc;
	if (s->buff[loc++] == 'T' &&
		s->buff[loc++] == 'h' &&
		s->buff[loc++] == 'e' &&
		s->buff[loc++] == ' ' &&
		s->buff[loc++] == 'E' &&
		s->buff[loc++] == 'n' &&
		s->buff[loc++] == 'd') {
		s->loc = loc;
		
		return pool_create_node(p, S_NODE_END, s->bol, s->eol);
	}
	
	return NULL;
}

CueNode *scan_for_facsimile(Scanner *s, Pool *p)
{
	if (scanner_is_at_eol(s))
		return NULL;
	
	if (s->buff[s->loc] == '>' && !scanner_loc_is_escaped(s)) {
		uint32_t bstart = scanner_advance_to_first_nonspace(s);
		
		CueNode *facs = pool_create_node(p, S_NODE_FACSIMILE, s->bol, s->eol);
		CueNode *line = pool_create_node(p, S_NODE_LINE, bstart, s->ewc);
		cue_node_add_child(facs, line);
		
		return facs;
	}
	
	return NULL;
}

CueNode *scan_for_lyric_line(Scanner *s, Pool *p)
{
	if (scanner_is_at_eol(s))
		return NULL;
	
	if (s->buff[s->loc] == '~' && !scanner_loc_is_escaped(s)) {
		++(s->loc);
		uint32_t bstart = scanner_advance_to_first_nonspace(s);
		
		CueNode *line = pool_create_node(p, S_NODE_LINE, bstart, s->ewc);
		
		return line;
	}
	
	return NULL;
}

CueNode *scan_for_cue(Scanner *s, Pool *p)
{
	if (scanner_is_at_eol(s))
		return NULL;
	
	uint32_t bt = s->loc;
	int isDual = 0;
	if (s->buff[s->loc] == '^' && !scanner_loc_is_escaped(s)) {
		isDual = 1;
		++(s->loc);
	}
	
	uint32_t nstart = s->loc;
	uint32_t nend = scanner_advance_to_colon(s, 24);
	
	if (scanner_is_at_eol(s)){
		s->loc = bt;
		return NULL;
	}
	
	++(s->loc);
	uint32_t dstart = scanner_advance_to_first_nonspace(s);
	uint32_t dend = s->ewc;
	
	CueNode *cue = pool_create_node(p, S_NODE_CUE, s->bol, s->eol);
	
	CueNode *name = pool_create_node(p, S_NODE_NAME, nstart, nend);
	cue_node_add_child(cue, name);
	
	CueNode *dir = pool_create_node(p, S_NODE_PLAIN_DIRECTION, dstart, dend);
	cue_node_add_child(cue, dir);
	
	cue->data.cue.isDual = isDual;
	cue->data.cue.name = name;
	cue->data.cue.direction = dir;
	
	return cue;
}

int scan_delimiter_token(Scanner *s, int handle_parens, DelimiterToken *out)
{
	for (; s->loc < s->ewc; ++s->loc) {
		if (scanner_loc_is_escaped(s))
			continue;
		
		switch (s->buff[s->loc]) {
			case '*': {
				*out = delimiter_token_init(S_NODE_EMPHASIS, 1, s->loc, ++s->loc);
				if (!scanner_is_at_eol(s) && s->buff[s->loc] == '*') {
					out->type = S_NODE_STRONG;
					out->end = ++s->loc;
				}
				return 1;
			}
			case '(':
				if (handle_parens) {
					*out = delimiter_token_init(S_NODE_PARENTHETICAL, 1, s->loc, ++s->loc);
					return 1;
				}
				break;
			case ')':
				if (handle_parens) {
					*out = delimiter_token_init(S_NODE_PARENTHETICAL, 0, s->loc, ++s->loc);
					return 1;
				}
				break;
			case '[':
				*out = delimiter_token_init(S_NODE_REFERENCE, 1, s->loc, ++s->loc);
				return 1;
			case ']':
				*out = delimiter_token_init(S_NODE_REFERENCE, 0, s->loc, ++s->loc);
				return 1;
			case '/': {
				uint32_t bt = s->loc++;
				if (!scanner_is_at_eol(s) && s->buff[s->loc] == '/') {
					scanner_advance_to_first_nonspace(s);
					*out = delimiter_token_init(S_NODE_COMMENT, 1, bt, s->loc);
					s->loc = s->ewc;
					return 1;
				}
				s->loc = bt;
				break;
			}
			default:
				break;
		}
	}
	
	return 0;
}
