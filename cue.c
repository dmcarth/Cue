
#include "cue.h"
#include "utf16.h"
#include "mem.h"
#include "scanners.h"
#include "inlines.h"
#include <stdio.h>

cue_document *cue_document_new(size_t len) {
	s_node *root = s_node_new(S_NODE_DOCUMENT, 0, len);
	
	cue_document *doc = c_malloc(sizeof(cue_document));
	
	doc->root = root;
	
	return doc;
}

void cue_document_free(cue_document *doc) {
	s_node_free(doc->root);
	
	free(doc);
}

s_node *block_for_line(scanner *s) {
	scanner_trim_whitespace(s);
	
	s_node *block;
	if ((block = scan_for_thematic_break(s)) ||
			(block = scan_for_forced_header(s)) ||
			(block = scan_for_header(s)) ||
			(block = scan_for_end(s)) ||
			(block = scan_for_facsimile(s)) ||
			(block = scan_for_lyric_line(s)) ||
			(block = scan_for_cue(s))) {
		return block;
	}
	
	block = s_node_description_init(s->bol, s->wc, s->ewc, s->eol);
	
	return block;
}

s_node *appropriate_container_for_block(scanner *s, s_node *block, cue_document *doc) {
	s_node *root = doc->root;
	
	switch (block->type) {
		case S_NODE_HEADER:
		case S_NODE_DESCRIPTION:
		case S_NODE_END:
		case S_NODE_THEMATIC_BREAK:
			return root;
		case S_NODE_CUE:
			if (!block->data.cue.isDual) {
				return s_node_add_child(root, S_NODE_SIMULTANEOUS_CUES, block->range.start, block->range.end);
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
				block->type = S_NODE_LINE;
				
				s_node_unlink(block->first_child);
				
				s_node_free(block->first_child);
				
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
	s_node_free(block);
	
	block = s_node_description_init(s->bol, s->wc, s->ewc, s->eol);
	
	return root;
}

void process_line(cue_document *doc, scanner *s) {
	s_node *block = block_for_line(s);
	
	s_node *container = appropriate_container_for_block(s, block, doc);
	s_node_add(container, block);
	
	switch (block->type) {
		case S_NODE_DESCRIPTION:
		case S_NODE_LINE:
			parse_inlines_for_node(s, block->first_child, 0);
			break;
		case S_NODE_FACSIMILE:
			parse_inlines_for_node(s, block->first_child->first_child, 0);
			break;
		case S_NODE_HEADER: {
			s_node *title = block->data.header.title;
			if (title) {
				parse_inlines_for_node(s, title->first_child, 0);
			}
			break;
		}
		case S_NODE_CUE: {
			s_node *dir = block->data.cue.direction;
			
			s_node *newdir;
			s->loc = dir->range.start;
			if ((newdir = scan_for_lyric_line(s))) {
				dir = newdir;
				dir->type = S_NODE_LYRIC_DIRECTION;
				
				s_node *line = s_node_line_init(dir->range.start, dir->range.end);
				s_node_add(dir, line);
				
				parse_inlines_for_node(s, line->first_child, 1);
			} else {
				s_node *stream = s_node_new(S_NODE_STREAM, dir->range.start, dir->range.end);
				s_node_add(dir, stream);
				
				parse_inlines_for_node(s, stream, 1);
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
