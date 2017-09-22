
#include "cue.h"
#include "utf16.h"
#include "mem.h"
#include "scanners.h"
#include "inlines.h"
#include <stdio.h>

struct cue_document {
	pool *mem;
	s_node *root;
};

cue_document *cue_document_new(size_t len) {
	cue_document *doc = c_malloc(sizeof(cue_document));
	
	doc->mem = pool_new(16);
	doc->root = pool_create_node(doc->mem, S_NODE_DOCUMENT, 0, len);;
	
	return doc;
}

void cue_document_free(cue_document *doc) {
	pool_free(doc->mem);
	
	free(doc);
}

s_node *cue_document_get_root(cue_document *doc) {
	return doc->root;
}

s_node *s_node_description_init(pool *p, size_t start, size_t wc, size_t ewc, size_t end) {
	s_node *desc = pool_create_node(p, S_NODE_DESCRIPTION, start, end);
	s_node *stream = pool_create_node(p, S_NODE_STREAM, wc, ewc);
	s_node_add_child(desc, stream);

	return desc;
}

s_node *block_for_line(scanner *s, pool *p) {
	scanner_trim_whitespace(s);
	
	s_node *block;
	if ((block = scan_for_thematic_break(s, p)) ||
			(block = scan_for_forced_header(s, p)) ||
			(block = scan_for_header(s, p)) ||
			(block = scan_for_end(s, p)) ||
			(block = scan_for_facsimile(s, p)) ||
			(block = scan_for_lyric_line(s, p)) ||
			(block = scan_for_cue(s, p))) {
		return block;
	}
	
	block = s_node_description_init(p, s->bol, s->wc, s->ewc, s->eol);
	
	return block;
}

s_node *appropriate_container_for_block(scanner *s, s_node *block, cue_document *doc) {
	s_node *root = doc->root;
	pool *p = doc->mem;
	
	switch (block->type) {
		case S_NODE_HEADER:
		case S_NODE_DESCRIPTION:
		case S_NODE_END:
		case S_NODE_THEMATIC_BREAK:
			return root;
		case S_NODE_CUE:
			if (!block->data.cue.isDual) {
				s_node *scues = pool_create_node(p, S_NODE_SIMULTANEOUS_CUES, block->range.start, block->range.end);
				s_node_add_child(root, scues);
				
				return scues;
			}
			
			s_node *last = root->last_child;
			if (s_node_is_type(last, S_NODE_SIMULTANEOUS_CUES)) {
				s_node_extend_length_to_include_child(last, block);
				return last;
			}
			
			break;
		case S_NODE_FACSIMILE: {
			s_node *last = root->last_child;
			
			// If last child of root is a facsimile, then change current block to a line and prepare it to be added to to the last child.
			if (s_node_is_type(last, S_NODE_FACSIMILE)) {
				s_node *line = block->first_child;
				s_node *stream = line->first_child;
				
				block->type = S_NODE_LINE;
				
				line->type = S_NODE_STREAM;
				line->range = stream->range;
				
				s_node_unlink(stream);
				
				pool_release_node(p, stream);
				
				s_node_extend_length_to_include_child(last, block);
				return last;
			}
			
			// First line. Add to root.
			return root;
		}
		case S_NODE_LINE: {
			s_node *scues = root->last_child;
			if (!s_node_is_type(scues, S_NODE_SIMULTANEOUS_CUES))
				break;
			
			s_node *cue = scues->last_child;
			if (!s_node_is_type(cue, S_NODE_CUE))
				break;
			
			s_node *dir = cue->data.cue.direction;
			if (!s_node_is_type(dir, S_NODE_LYRIC_DIRECTION))
				break;
			
			s_node_extend_length_to_include_child(dir, block);
			s_node_extend_length_to_include_child(cue, dir);
			s_node_extend_length_to_include_child(scues, cue);
			
			return dir;
		}
		default:
			break;
	}
	
	// invalid syntax, fail gracefully
	
	s_node_unlink(block);
	
	pool_release_node(p, block);
	
	block = s_node_description_init(p, s->bol, s->wc, s->ewc, s->eol);
	
	return root;
}

void process_line(cue_document *doc, scanner *s) {
	pool *p = doc->mem;
	s_node *block = block_for_line(s, p);
	
	s_node *container = appropriate_container_for_block(s, block, doc);
	s_node_add_child(container, block);
	
	switch (block->type) {
		case S_NODE_DESCRIPTION:
		case S_NODE_LINE:
			parse_inlines_for_node(s, p, block->first_child, 0);
			break;
		case S_NODE_FACSIMILE:
			parse_inlines_for_node(s, p, block->first_child->first_child, 0);
			break;
		case S_NODE_HEADER: {
			s_node *title = block->data.header.title;
			if (title) {
				parse_inlines_for_node(s, p, title->first_child, 0);
			}
			break;
		}
		case S_NODE_CUE: {
			s_node *dir = block->data.cue.direction;
			
			s_node *newdir;
			s->loc = dir->range.start;
			if ((newdir = scan_for_lyric_line(s, p))) {
				dir = newdir;
				dir->type = S_NODE_LYRIC_DIRECTION;
				
				s_node *line = pool_create_node(p, S_NODE_LINE, dir->range.start, dir->range.end);
				s_node_add_child(dir, line);
				
				parse_inlines_for_node(s, p, line->first_child, 1);
			} else {
				s_node *stream = pool_create_node(p, S_NODE_STREAM, dir->range.start, dir->range.end);
				s_node_add_child(dir, stream);
				
				parse_inlines_for_node(s, p, stream, 1);
			}
			break;
		}
		default:
			break;
	}
	
	return;
}

cue_document *cue_document_from_utf16(uint16_t *buff, size_t len) {
	cue_document *doc = cue_document_new(len);
	
	scanner *s = scanner_new(buff, len);
	
	// Enumerate lines
	while (scanner_advance_to_next_line(s) < len) {
		if (!scanner_is_at_eol(s)) {
			process_line(doc, s);
		}
	}
	
	scanner_free(s);
	
	return doc;
}
