
#include "cue.h"
#include "mem.h"
#include "Scanner.h"
#include "inlines.h"
#include <stdio.h>

struct CueDocument
{
	Pool *p;
	CueNode *root;
};

CueDocument *cue_document_new(uint32_t len)
{
	CueDocument *doc = c_malloc(sizeof(CueDocument));
	
	doc->p = pool_new();
	doc->root = pool_create_node(doc->p, S_NODE_DOCUMENT, 0, len);;
	
	return doc;
}

void cue_document_free(CueDocument *doc)
{
	pool_free(doc->p);
	
	free(doc);
}

CueNode *cue_document_get_root(CueDocument *doc)
{
	return doc->root;
}

CueNode *cue_node_description_init(Pool *p, uint32_t start, uint32_t wc,
							   uint32_t ewc, uint32_t end)
{
	CueNode *desc = pool_create_node(p, S_NODE_DESCRIPTION, start, end);
	CueNode *stream = pool_create_node(p, S_NODE_STREAM, wc, ewc);
	cue_node_add_child(desc, stream);

	return desc;
}

CueNode *block_for_line(Scanner *s, Pool *p)
{
	CueNode *block;
	
	if ((block = scan_for_thematic_break(s, p)) ||
			(block = scan_for_forced_header(s, p)) ||
			(block = scan_for_header(s, p)) ||
			(block = scan_for_end(s, p)) ||
			(block = scan_for_facsimile(s, p)) ||
			(block = scan_for_lyric_line(s, p)) ||
			(block = scan_for_cue(s, p))) {
		return block;
	}
	
	block = cue_node_description_init(p, s->bol, s->wc, s->ewc, s->eol);
	
	return block;
}

CueNode *appropriate_container_for_block(Scanner *s, CueNode *block,
									   CueDocument *doc)
{
	CueNode *root = doc->root;
	Pool *p = doc->p;
	
	switch (block->type) {
		case S_NODE_HEADER:
		case S_NODE_DESCRIPTION:
		case S_NODE_END:
		case S_NODE_THEMATIC_BREAK:
			return root;
		case S_NODE_CUE:
			if (!block->data.cue.isDual) {
				CueNode *scues = pool_create_node(p, S_NODE_SIMULTANEOUS_CUES, block->range.start, block->range.end);
				cue_node_add_child(root, scues);
				
				return scues;
			}
			
			CueNode *last = root->last_child;
			if (cue_node_is_type(last, S_NODE_SIMULTANEOUS_CUES)) {
				cue_node_extend_length_to_include_child(last, block);
				return last;
			}
			
			break;
		case S_NODE_FACSIMILE: {
			CueNode *last = root->last_child;
			
			// If last child of root is a facsimile, then change current block to a line and prepare it to be added to to the last child.
			if (cue_node_is_type(last, S_NODE_FACSIMILE)) {
				CueNode *line = block->first_child;
				CueNode *stream = line->first_child;
				
				block->type = S_NODE_LINE;
				
				line->type = S_NODE_STREAM;
				line->range = stream->range;
				
				cue_node_unlink(stream);
				
				pool_release_node(p, stream);
				
				cue_node_extend_length_to_include_child(last, block);
				return last;
			}
			
			// First line. Add to root.
			return root;
		}
		case S_NODE_LINE: {
			CueNode *scues = root->last_child;
			if (!cue_node_is_type(scues, S_NODE_SIMULTANEOUS_CUES))
				break;
			
			CueNode *cue = scues->last_child;
			if (!cue_node_is_type(cue, S_NODE_CUE))
				break;
			
			CueNode *dir = cue->data.cue.direction;
			if (!cue_node_is_type(dir, S_NODE_LYRIC_DIRECTION))
				break;
			
			cue_node_extend_length_to_include_child(dir, block);
			cue_node_extend_length_to_include_child(cue, dir);
			cue_node_extend_length_to_include_child(scues, cue);
			
			return dir;
		}
		default:
			break;
	}
	
	// invalid syntax, fail gracefully
	
	cue_node_unlink(block);
	pool_release_node(p, block);
	
	block = cue_node_description_init(p, s->bol, s->wc, s->ewc, s->eol);
	
	return root;
}

void finalize_line(CueDocument *doc, Scanner *s, CueNode *block)
{
	Pool *p = doc->p;
	
	switch (block->type) {
		case S_NODE_DESCRIPTION:
		case S_NODE_LINE:
			parse_inlines_for_node(s, p, block->first_child, 0);
			break;
		case S_NODE_FACSIMILE:
			parse_inlines_for_node(s, p, block->first_child->first_child, 0);
			break;
		case S_NODE_HEADER: {
			CueNode *title = block->data.header.title;
			if (title) {
				parse_inlines_for_node(s, p, title->first_child, 0);
			}
			break;
		}
		case S_NODE_CUE: {
			CueNode *dir = block->data.cue.direction;
			
			CueNode *newdir;
			s->loc = dir->range.start;
			if ((newdir = scan_for_lyric_line(s, p))) {
				dir = newdir;
				dir->type = S_NODE_LYRIC_DIRECTION;
				
				CueNode *line = pool_create_node(p, S_NODE_LINE, dir->range.start, dir->range.end);
				cue_node_add_child(dir, line);
				
				parse_inlines_for_node(s, p, line->first_child, 1);
			} else {
				CueNode *stream = pool_create_node(p, S_NODE_STREAM, dir->range.start, dir->range.end);
				cue_node_add_child(dir, stream);
				
				parse_inlines_for_node(s, p, stream, 1);
			}
			break;
		}
		default:
			break;
	}
}

void process_line(CueDocument *doc, Scanner *s)
{
	CueNode *block = block_for_line(s, doc->p);
	
	CueNode *container = appropriate_container_for_block(s, block, doc);
	cue_node_add_child(container, block);
	
	finalize_line(doc, s, block);
	
	return;
}

CueDocument *cue_document_from_utf8(const char *buff, size_t len)
{
	CueDocument *doc = cue_document_new((uint32_t)len);
	
	Scanner *s = scanner_new(buff, (uint32_t)len);
	
	// Enumerate lines
	while (scanner_advance_to_next_line(s) < len) {
		if (!scanner_is_at_eol(s)) {
			process_line(doc, s);
		}
	}
	
	scanner_free(s);
	
	return doc;
}
