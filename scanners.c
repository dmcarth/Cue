
#include "scanners.h"
#include "inlines.h"
#include "mem.h"

scanner *scanner_new(uint16_t *buff, size_t len) {
	scanner *s = c_calloc(1, sizeof(scanner));
	
	s->buff = buff;
	s->len = len;
	s->tokens = delim_stack_new(8);
	
	return s;
}

void scanner_free(scanner *s) {
	delim_stack_free(s->tokens);
	
	free(s);
}

int scanner_is_at_eol(scanner *s) {
	// For scanning purposes, ewc == eol
	return s->loc == s->ewc;
}

/* true if buff[loc - 1] == '\' */
static int scanner_loc_is_escaped(scanner *s) {
	return s->loc && (s->buff[s->loc-1] == '\\');
}

/*	Cue ignores whitespace so we can ignore the CRLF case (the parser will interpret LF as an empty line and discard it).
	LS is ignored for now. */
static inline int is_newline(uint16_t c) {
	return c == 10 || c == 11 || c == 12 || c == 13 || c == 133 || c == 8233;
}

static inline int is_whitespace(uint16_t c) {
	return c == ' ' || c == '\t' || is_newline(c);
}

size_t scanner_advance_to_next_line(scanner *s) {
	s->bol = s->eol;
	s->loc = s->bol;
	
	while (s->eol < s->len) {
		size_t bt = s->eol++;
		if (is_newline(s->buff[bt]))
			break;
	}
	
	s->wc = s->bol;
	s->ewc = s->eol;
	
	return s->bol;
}

size_t scanner_advance_to_first_nonspace(scanner *s) {
	while (s->loc < s->ewc) {
		if (is_whitespace(s->buff[s->loc]))
			++(s->loc);
		else
			break;
	}
	
	return s->loc;
}

size_t scanner_advance_to_hyphen(scanner *s) {
	while (s->loc < s->ewc) {
		if (s->buff[s->loc] == '-' && !scanner_loc_is_escaped(s))
			break;
		else
			++(s->loc);
	}
	
	return s->loc;
}

size_t scanner_backtrack_to_first_nonspace(scanner *s) {
	while (s->loc > s->wc) {
		size_t bt = s->loc - 1;
		
		if (is_whitespace(s->buff[bt]))
			s->loc = bt;
		else
			break;
	}
	
	return s->loc;
}

size_t scanner_advance_to_colon(scanner *s, size_t bound) {
	size_t start = s->loc;
	
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

void scanner_trim_whitespace(scanner *s) {
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

int scan_for_act(scanner *s) {
	if (s->ewc - s->loc < 3)
		return 0;
	
	size_t loc = s->loc;
	if (s->buff[loc++] == 'A' &&
		s->buff[loc++] == 'c' &&
		s->buff[loc++] == 't') {
		s->loc = loc;
		
		return 1;
	}
	
	return 0;
}

int scan_for_chapter(scanner *s) {
	if (s->ewc - s->loc < 7)
		return 0;
	
	size_t loc = s->loc;
	if (s->buff[loc++] == 'C' &&
		s->buff[loc++] == 'h' &&
		s->buff[loc++] == 'a' &&
		s->buff[loc++] == 'p' &&
		s->buff[loc++] == 't' &&
		s->buff[loc++] == 'e' &&
		s->buff[loc++] == 'r') {
		s->loc = loc;
		
		return 1;
	}
	
	return 0;
}

int scan_for_scene(scanner *s) {
	if (s->ewc - s->loc < 5)
		return 0;
	
	size_t loc = s->loc;
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

int scan_for_page(scanner *s) {
	if (s->ewc - s->loc < 4)
		return 0;
	
	size_t loc = s->loc;
	if (s->buff[loc++] == 'P' &&
		s->buff[loc++] == 'a' &&
		s->buff[loc++] == 'g' &&
		s->buff[loc++] == 'e') {
		s->loc = loc;
		
		return 1;
	}
	
	return 0;
}

/* The following are node factories. If scanning succeeds, they construct a node for the AST. */

s_node *scan_for_thematic_break(scanner *s, pool *p) {
	if (s->ewc - s->loc < 3)
		return NULL;
	
	size_t loc = s->loc;
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

s_node *scan_title(scanner *s, pool *p) {
	s_node *title = NULL;
	
	if (!scanner_is_at_eol(s)) {
		size_t tstart = scanner_advance_to_first_nonspace(s);
		
		title = pool_create_node(p, S_NODE_TITLE, tstart, s->ewc);
	}
	
	return title;
}

s_node *scan_for_forced_header(scanner *s, pool *p) {
	if (s->ewc - s->loc < 1 || s->buff[s->loc] != '.')
		return NULL;
	
	size_t kstart = ++(s->loc);
	size_t hstart = scanner_advance_to_hyphen(s);
	size_t kend = scanner_backtrack_to_first_nonspace(s);
	s->loc = hstart + 1;
	
	s_node *head = pool_create_node(p, S_NODE_HEADER, s->bol, s->eol);
	
	s_node *key = pool_create_node(p, S_NODE_KEYWORD, kstart, kend);
	s_node_add_child(head, key);
	
	s_node *title = scan_title(s, p);
	s_node_add_child(head, title);
	
	head->data.header.type = HEADER_FORCED;
	head->data.header.keyword = key;
	head->data.header.title = title;
	
	return head;
}

s_node *scan_for_header(scanner *s, pool *p) {
	header_type type;
	size_t kstart = s->loc;
	size_t kend = s->loc;
	
	if (scan_for_act(s)) {
		type = HEADER_ACT;
		kend += 3;
	} else if (scan_for_scene(s)) {
		type = HEADER_SCENE;
		kend += 5;
	} else if (scan_for_chapter(s)) {
		type = HEADER_CHAPTER;
		kend += 7;
	} else if (scan_for_page(s)) {
		type = HEADER_PAGE;
		kend += 4;
	} else {
		return NULL;
	}
	size_t istart = scanner_advance_to_first_nonspace(s);
	
	if (scanner_is_at_eol(s))
		return NULL;
	
	size_t hstart = scanner_advance_to_hyphen(s);
	size_t iend = scanner_backtrack_to_first_nonspace(s);
	
	s->loc = hstart + 1;
	
	s_node *head = pool_create_node(p, S_NODE_HEADER, s->bol, s->eol);
	
	s_node *key = pool_create_node(p, S_NODE_KEYWORD, kstart, kend);
	s_node_add_child(head, key);
	
	s_node *id = NULL;
	if (istart < iend) {
		id = pool_create_node(p, S_NODE_IDENTIFIER, istart, iend);
		s_node_add_child(head, id);
	}
	
	s_node *title = scan_title(s, p);
	s_node_add_child(head, title);
	
	head->data.header.type = type;
	head->data.header.keyword = key;
	head->data.header.id = id;
	head->data.header.title = title;
	
	return head;
}

s_node *scan_for_end(scanner *s, pool *p) {
	if (s->ewc - s->loc != 7)
		return NULL;
	
	size_t loc = s->loc;
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

s_node *scan_for_facsimile(scanner *s, pool *p) {
	if (scanner_is_at_eol(s))
		return NULL;
	
	if (s->buff[s->loc] == '>' && !scanner_loc_is_escaped(s)) {
		size_t bstart = scanner_advance_to_first_nonspace(s);
		
		s_node *facs = pool_create_node(p, S_NODE_FACSIMILE, s->bol, s->eol);
		s_node *line = pool_create_node(p, S_NODE_LINE, bstart, s->ewc);
		s_node_add_child(facs, line);
		
		return facs;
	}
	
	return NULL;
}

s_node *scan_for_lyric_line(scanner *s, pool *p) {
	if (scanner_is_at_eol(s))
		return NULL;
	
	if (s->buff[s->loc] == '~' && !scanner_loc_is_escaped(s)) {
		++(s->loc);
		size_t bstart = scanner_advance_to_first_nonspace(s);
		
		s_node *line = pool_create_node(p, S_NODE_LINE, bstart, s->ewc);
		
		return line;
	}
	
	return NULL;
}

s_node *scan_for_cue(scanner *s, pool *p) {
	if (scanner_is_at_eol(s))
		return NULL;
	
	size_t bt = s->loc;
	int isDual = 0;
	if (s->buff[s->loc] == '^' && !scanner_loc_is_escaped(s)) {
		isDual = 1;
		++(s->loc);
	}
	
	size_t nstart = s->loc;
	size_t nend = scanner_advance_to_colon(s, 24);
	
	if (scanner_is_at_eol(s)){
		s->loc = bt;
		return NULL;
	}
	
	++(s->loc);
	size_t dstart = scanner_advance_to_first_nonspace(s);
	size_t dend = s->ewc;
	
	s_node *cue = pool_create_node(p, S_NODE_CUE, s->bol, s->eol);
	
	s_node *name = pool_create_node(p, S_NODE_NAME, nstart, nend);
	s_node_add_child(cue, name);
	
	s_node *dir = pool_create_node(p, S_NODE_PLAIN_DIRECTION, dstart, dend);
	s_node_add_child(cue, dir);
	
	cue->data.cue.isDual = isDual;
	cue->data.cue.name = name;
	cue->data.cue.direction = dir;
	
	return cue;
}

int scan_d_tok(scanner *s, d_tok *out, int handle_parens) {
	for (; s->loc < s->ewc; ++s->loc) {
		if (scanner_loc_is_escaped(s))
			continue;
		
		switch (s->buff[s->loc]) {
			case '*': {
				*out = d_tok_init(S_NODE_EMPHASIS, 1, s->loc, ++s->loc);
				if (!scanner_is_at_eol(s) && s->buff[s->loc] == '*') {
					out->type = S_NODE_STRONG;
					out->end = ++s->loc;
				}
				return 1;
			}
			case '(':
				if (handle_parens) {
					*out = d_tok_init(S_NODE_PARENTHETICAL, 1, s->loc, ++s->loc);
					return 1;
				}
				break;
			case ')':
				if (handle_parens) {
					*out = d_tok_init(S_NODE_PARENTHETICAL, 0, s->loc, ++s->loc);
					return 1;
				}
				break;
			case '[':
				*out = d_tok_init(S_NODE_REFERENCE, 1, s->loc, ++s->loc);
				return 1;
			case ']':
				*out = d_tok_init(S_NODE_REFERENCE, 0, s->loc, ++s->loc);
				return 1;
			case '/': {
				size_t bt = s->loc++;
				if (!scanner_is_at_eol(s) && s->buff[s->loc] == '/') {
					scanner_advance_to_first_nonspace(s);
					*out = d_tok_init(S_NODE_COMMENT, 1, bt, s->loc);
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
