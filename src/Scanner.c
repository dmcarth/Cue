
#include "Scanner.h"
#include "inlines.h"
#include "mem.h"

Scanner *scanner_new(const char *source,
                     uint32_t length)
{
	Scanner *s = c_calloc(1, sizeof(Scanner));
	
	s->source = source;
	s->length = length;
	
	return s;
}

void scanner_free(Scanner *s)
{
	free(s);
}

int scanner_is_at_eol(Scanner *s)
{
	// For scanning purposes, ewc == eol
	return s->loc == s->ewc;
}

/* true if source[loc - 1] == '\' */
static int scanner_loc_is_escaped(Scanner *s)
{
	return s->loc && (s->source[s->loc-1] == '\\');
}

/*	Cue ignores whitespace so we can safely ignore the "\r\n" case (the parser will interpret '\n' as an empty line and discard it). */
static inline int is_newline(const char c)
{
	return c == '\n' || c == 11 || c == 12 || c == '\r';
}

static inline int is_whitespace(const char c)
{
	return c == ' ' || c == '\t' || is_newline(c);
}

uint32_t scanner_advance_to_next_line(Scanner *s)
{
	s->bol = s->eol;
	s->loc = s->bol;
	
	for (uint32_t i = s->eol; i < s->length; ++i) {
		s->eol++;
		if (is_newline(s->source[i]))
			break;
	}
	
	scanner_trim_whitespace(s);
	
	return s->bol;
}

uint32_t scanner_advance_to_first_nonspace(Scanner *s)
{
	while (s->loc < s->ewc) {
		if (is_whitespace(s->source[s->loc]))
			++(s->loc);
		else
			break;
	}
	
	return s->loc;
}

uint32_t scanner_advance_to_hyphen(Scanner *s)
{
	for (; s->loc < s->ewc; ++s->loc) {
		if (s->source[s->loc] == '-' && !scanner_loc_is_escaped(s))
			break;
	}
	
	return s->loc;
}

uint32_t scanner_backtrack_to_first_nonspace(Scanner *s)
{
	while (s->loc > s->wc) {
		uint32_t bt = s->loc - 1;
		
		if (is_whitespace(s->source[bt]))
			s->loc = bt;
		else
			break;
	}
	
	return s->loc;
}

uint32_t scanner_advance_to_colon(Scanner *s,
                                  uint32_t bound)
{
	uint32_t start = s->loc;
	
	while (s->loc < s->ewc) {
		if (s->loc - start > bound)
			break;
		
		if (s->source[s->loc] == ':' && !scanner_loc_is_escaped(s))
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
	if (s->source[loc++] == 'A' &&
		s->source[loc++] == 'c' &&
		s->source[loc++] == 't') {
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
	if (s->source[loc++] == 'S' &&
		s->source[loc++] == 'c' &&
		s->source[loc++] == 'e' &&
		s->source[loc++] == 'n' &&
		s->source[loc++] == 'e') {
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
	if (s->source[loc++] == 'P' &&
		s->source[loc++] == 'a' &&
		s->source[loc++] == 'g' &&
		s->source[loc++] == 'e') {
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
	if (s->source[loc++] == 'F' &&
		s->source[loc++] == 'r' &&
		s->source[loc++] == 'a' &&
		s->source[loc++] == 'm' &&
		s->source[loc++] == 'e') {
		s->loc = loc;
		
		return 1;
	}
	
	return 0;
}

/* The following are node factories. If scanning succeeds, they construct a node for the AST. */

ASTNode *scan_for_thematic_break(Scanner *s,
								 NodeAllocator *node_allocator)
{
	if (s->ewc - s->loc < 3)
		return NULL;
	
	uint32_t loc = s->loc;
	while (loc < s->ewc) {
		if (s->source[loc] == '-' && !scanner_loc_is_escaped(s))
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
	
	return ast_node_new(node_allocator, S_NODE_THEMATIC_BREAK, s->bol, s->eol - s->bol);
}

ASTNode *scan_title(Scanner *s,
					NodeAllocator *node_allocator)
{
	ASTNode *title = NULL;
	
	if (!scanner_is_at_eol(s)) {
		uint32_t tstart = scanner_advance_to_first_nonspace(s);
		
		title = ast_node_new(node_allocator, S_NODE_TITLE, tstart, s->ewc - tstart);
	}
	
	return title;
}

ASTNode *scan_for_forced_header(Scanner *s,
								NodeAllocator *node_allocator)
{
	if (s->ewc - s->loc < 1 || s->source[s->loc] != '.')
		return NULL;
	
	uint32_t kstart = ++(s->loc);
	uint32_t hstart = scanner_advance_to_hyphen(s);
	uint32_t kend = scanner_backtrack_to_first_nonspace(s);
	s->loc = hstart;
	if (!scanner_is_at_eol(s)) {
		++s->loc;
	}
	
	ASTNode *head = ast_node_new(node_allocator, S_NODE_HEADER, s->bol, s->eol - s->bol);
	
	ASTNode *key = ast_node_new(node_allocator, S_NODE_KEYWORD, kstart, kend - kstart);
	ast_node_add_child(head, key);
	
	ASTNode *title = scan_title(s, node_allocator);
	if (title) {
		ast_node_add_child(head, title);
	}
	
	head->as.header.type = HEADER_FORCED;
	head->as.header.keyword = key;
	head->as.header.title = title;
	
	return head;
}

ASTNode *scan_for_header(Scanner *s,
						 NodeAllocator *node_allocator)
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
	
	s->loc = hstart;
	if (!scanner_is_at_eol(s)) {
		++s->loc;
	}
	
	ASTNode *head = ast_node_new(node_allocator, S_NODE_HEADER, s->bol, s->eol - s->bol);
	
	ASTNode *key = ast_node_new(node_allocator, S_NODE_KEYWORD, kstart, kend - kstart);
	ast_node_add_child(head, key);
	
	ASTNode *id = NULL;
	if (istart < iend) {
		id = ast_node_new(node_allocator, S_NODE_IDENTIFIER, istart, iend - istart);
		ast_node_add_child(head, id);
	}
	
	ASTNode *title = scan_title(s, node_allocator);
	if (title) {
		ast_node_add_child(head, title);
	}
	
	head->as.header.type = type;
	head->as.header.keyword = key;
	head->as.header.id = id;
	head->as.header.title = title;
	
	return head;
}

ASTNode *scan_for_end(Scanner *s,
					  NodeAllocator *node_allocator)
{
	if (s->ewc - s->loc != 7)
		return NULL;
	
	uint32_t loc = s->loc;
	if (s->source[loc++] == 'T' &&
		s->source[loc++] == 'h' &&
		s->source[loc++] == 'e' &&
		s->source[loc++] == ' ' &&
		s->source[loc++] == 'E' &&
		s->source[loc++] == 'n' &&
		s->source[loc++] == 'd') {
		s->loc = loc;
		
		return ast_node_new(node_allocator, S_NODE_END, s->bol, s->eol - s->bol);
	}
	
	return NULL;
}

ASTNode *scan_for_facsimile(Scanner *s,
							NodeAllocator *node_allocator)
{
	if (scanner_is_at_eol(s))
		return NULL;
	
	if (s->source[s->loc] == '>' && !scanner_loc_is_escaped(s)) {
		uint32_t bstart = scanner_advance_to_first_nonspace(s);
		
		ASTNode *facs = ast_node_new(node_allocator, S_NODE_FACSIMILE, s->bol, s->eol - s->bol);
		ASTNode *line = ast_node_new(node_allocator, S_NODE_LINE, bstart, s->ewc - bstart);
		ast_node_add_child(facs, line);
		
		return facs;
	}
	
	return NULL;
}

ASTNode *scan_for_lyric_line(Scanner *s,
							 NodeAllocator *node_allocator)
{
	if (scanner_is_at_eol(s))
		return NULL;
	
	if (s->source[s->loc] == '~' && !scanner_loc_is_escaped(s)) {
		++(s->loc);
		uint32_t bstart = scanner_advance_to_first_nonspace(s);
		
		ASTNode *line = ast_node_new(node_allocator, S_NODE_LINE, bstart, s->ewc - bstart);
		
		return line;
	}
	
	return NULL;
}

ASTNode *scan_for_cue(Scanner *s,
					  NodeAllocator *node_allocator)
{
	if (scanner_is_at_eol(s))
		return NULL;
	
	uint32_t bt = s->loc;
	int isDual = 0;
	if (s->source[s->loc] == '^' && !scanner_loc_is_escaped(s)) {
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
	
	ASTNode *cue = ast_node_new(node_allocator, S_NODE_CUE, s->bol, s->eol - s->bol);
	
	ASTNode *name = ast_node_new(node_allocator, S_NODE_NAME, nstart, nend - nstart);
	ast_node_add_child(cue, name);
	
	ASTNode *dir = ast_node_new(node_allocator, S_NODE_PLAIN_DIRECTION, dstart, dend - dstart);
	ast_node_add_child(cue, dir);
	
	cue->as.cue.isDual = isDual;
	cue->as.cue.name = name;
	cue->as.cue.direction = dir;
	
	return cue;
}

int scan_delimiter_token(Scanner *s,
                         int handle_parens,
                         DelimiterToken *out)
{
	for (; s->loc < s->ewc; ++s->loc) {
		if (scanner_loc_is_escaped(s))
			continue;
		
		switch (s->source[s->loc]) {
			case '*': {
				*out = delimiter_token_init(S_NODE_EMPHASIS, 1, s->loc++, 1);
				if (!scanner_is_at_eol(s) && s->source[s->loc] == '*') {
					out->type = S_NODE_STRONG;
                    out->range.length = 2;
                    ++s->loc;
				}
				return 1;
			}
			case '(':
				if (handle_parens) {
					*out = delimiter_token_init(S_NODE_PARENTHETICAL, 1, s->loc++, 1);
					return 1;
				}
				break;
			case ')':
				if (handle_parens) {
					*out = delimiter_token_init(S_NODE_PARENTHETICAL, 0, s->loc++, 1);
					return 1;
				}
				break;
			case '[':
				*out = delimiter_token_init(S_NODE_REFERENCE, 1, s->loc++, 1);
				return 1;
			case ']':
				*out = delimiter_token_init(S_NODE_REFERENCE, 0, s->loc++, 1);
				return 1;
			case '/': {
				uint32_t bt = s->loc++;
				if (!scanner_is_at_eol(s) && s->source[s->loc] == '/') {
					scanner_advance_to_first_nonspace(s);
					*out = delimiter_token_init(S_NODE_COMMENT, 1, bt, s->loc - bt);
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
