
#include "cue.h"

#include <stdio.h>

#include "mem.h"
#include "pool.h"
#include "Scanner.h"
#include "inlines.h"
#include "parser.h"

struct CueDocument {
    const char *source;
    size_t source_len;
    ASTNode *root;
    Pool *node_allocator;
};

CueDocument *cue_document_new(const char *source,
                              size_t source_len,
                              ASTNode *root,
                              Pool *node_allocator)
{
    CueDocument *doc = c_malloc(sizeof(CueDocument));
    
    doc->source = source;
    doc->source_len = source_len;
    doc->root = root;
    doc->node_allocator = node_allocator;
    
    return doc;
}

void cue_document_free(CueDocument *doc)
{
    pool_free(doc->node_allocator);
    
    free(doc);
}

ASTNode *cue_document_get_root(CueDocument *doc)
{
    return doc->root;
}

CueParser *cue_parser_new(const char *buff, uint32_t len)
{
    CueParser *p = c_malloc(sizeof(CueParser));
    
    p->node_allocator = pool_new();
    p->root = pool_create_node(p->node_allocator, S_NODE_DOCUMENT, 0, len);
    p->scanner = scanner_new(buff, len);
    p->delimiter_stack = delimiter_stack_new();
    p->bol = 0;
    p->eol = 0;
    p->first_nonspace = 0;
    p->last_nonspace = 0;
    
    return p;
}

void cue_parser_free(CueParser *parser)
{
    free(parser->scanner);
    
    delimiter_stack_free(parser->delimiter_stack);
    
    free(parser);
}

ASTNode *ast_node_description_init(Pool *p, uint32_t start, uint32_t wc,
                               uint32_t ewc, uint32_t end)
{
    ASTNode *desc = pool_create_node(p, S_NODE_DESCRIPTION, start, end);
    ASTNode *stream = pool_create_node(p, S_NODE_STREAM, wc, ewc);
    ast_node_add_child(desc, stream);

    return desc;
}

ASTNode *block_for_line(CueParser *parser)
{
    Scanner *s = parser->scanner;
    Pool *p = parser->node_allocator;
    ASTNode *block;
    
    if ((block = scan_for_thematic_break(s, p)) ||
            (block = scan_for_forced_header(s, p)) ||
            (block = scan_for_header(s, p)) ||
            (block = scan_for_end(s, p)) ||
            (block = scan_for_facsimile(s, p)) ||
            (block = scan_for_lyric_line(s, p)) ||
            (block = scan_for_cue(s, p))) {
        return block;
    }
    
    block = ast_node_description_init(p, s->bol, s->wc, s->ewc, s->eol);
    
    return block;
}

ASTNode *appropriate_container_for_block(CueParser *parser, ASTNode *block)
{
    ASTNode *root = parser->root;
    Pool *p = parser->node_allocator;
    
    switch (block->type) {
        case S_NODE_HEADER:
        case S_NODE_DESCRIPTION:
        case S_NODE_END:
        case S_NODE_THEMATIC_BREAK:
            return root;
        case S_NODE_CUE:
            if (!block->data.cue.isDual) {
                ASTNode *scues = pool_create_node(p, S_NODE_SIMULTANEOUS_CUES, block->range.start, block->range.end);
                ast_node_add_child(root, scues);
                
                return scues;
            }
            
            ASTNode *last = root->last_child;
            if (ast_node_is_type(last, S_NODE_SIMULTANEOUS_CUES)) {
                ast_node_extend_length_to_include_child(last, block);
                return last;
            }
            
            break;
        case S_NODE_FACSIMILE: {
            ASTNode *last = root->last_child;
            
            // If last child of root is a facsimile, then change current block to a line and prepare it to be added to to the last child.
            if (ast_node_is_type(last, S_NODE_FACSIMILE)) {
                ASTNode *line = block->first_child;
                ASTNode *stream = line->first_child;
                
                block->type = S_NODE_LINE;
                
                line->type = S_NODE_STREAM;
                line->range = stream->range;
                
                ast_node_unlink(stream);
                
                pool_release_node(p, stream);
                
                ast_node_extend_length_to_include_child(last, block);
                return last;
            }
            
            // First line. Add to root.
            return root;
        }
        case S_NODE_LINE: {
            ASTNode *scues = root->last_child;
            if (!ast_node_is_type(scues, S_NODE_SIMULTANEOUS_CUES))
                break;
            
            ASTNode *cue = scues->last_child;
            if (!ast_node_is_type(cue, S_NODE_CUE))
                break;
            
            ASTNode *dir = cue->data.cue.direction;
            if (!ast_node_is_type(dir, S_NODE_LYRIC_DIRECTION))
                break;
            
            ast_node_extend_length_to_include_child(dir, block);
            ast_node_extend_length_to_include_child(cue, dir);
            ast_node_extend_length_to_include_child(scues, cue);
            
            return dir;
        }
        default:
            break;
    }
    
    // invalid syntax, fail gracefully
    
    ast_node_unlink(block);
    pool_release_node(p, block);
    
    Scanner *s = parser->scanner;
    
    block = ast_node_description_init(p, s->bol, s->wc, s->ewc, s->eol);
    
    return root;
}

void finalize_line(CueParser *parser, ASTNode *block)
{
    Scanner *s = parser->scanner;
    Pool *p = parser->node_allocator;
    
    switch (block->type) {
        case S_NODE_DESCRIPTION:
        case S_NODE_LINE:
            parse_inlines_for_node(parser, block->first_child, 0);
            break;
        case S_NODE_FACSIMILE:
            parse_inlines_for_node(parser, block->first_child->first_child, 0);
            break;
        case S_NODE_HEADER: {
            ASTNode *title = block->data.header.title;
            if (title) {
                parse_inlines_for_node(parser, title->first_child, 0);
            }
            break;
        }
        case S_NODE_CUE: {
            ASTNode *dir = block->data.cue.direction;
            
            ASTNode *newdir;
            s->loc = dir->range.start;
            if ((newdir = scan_for_lyric_line(s, p))) {
                dir = newdir;
                dir->type = S_NODE_LYRIC_DIRECTION;
                
                ASTNode *line = pool_create_node(p, S_NODE_LINE, dir->range.start, dir->range.end);
                ast_node_add_child(dir, line);
                
                parse_inlines_for_node(parser, line->first_child, 1);
            } else {
                ASTNode *stream = pool_create_node(p, S_NODE_STREAM, dir->range.start, dir->range.end);
                ast_node_add_child(dir, stream);
                
                parse_inlines_for_node(parser, stream, 1);
            }
            break;
        }
        default:
            break;
    }
}

void process_line(CueParser *parser)
{
    ASTNode *block = block_for_line(parser);
    
    ASTNode *container = appropriate_container_for_block(parser, block);
    ast_node_add_child(container, block);
    
    finalize_line(parser, block);
    
    return;
}

CueDocument *cue_document_from_utf8(const char *buff, size_t len)
{
    CueParser *parser = cue_parser_new(buff, (uint32_t)len);
    
    Scanner *scanner = parser->scanner;
    
    // Enumerate lines
    while (scanner_advance_to_next_line(scanner) < len) {
        if (!scanner_is_at_eol(scanner)) {
            process_line(parser);
        }
    }
    
    CueDocument *doc = cue_document_new(buff, len, parser->root, parser->node_allocator);
    
    cue_parser_free(parser);
    
    return doc;
}
