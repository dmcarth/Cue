
#include "nodes.h"

#include <stdio.h>

#include "mem.h"
#include "Walker.h"

ASTNode *ast_node_new(NodeAllocator *allocator,
					  ASTNodeType type,
					  uint32_t location,
					  uint32_t length)
{
	// Obtain node from allocator.
	ASTNode *node = allocator->alloc(allocator);
	
	// Setup node.
	SRange range = { location, length };
	
	node->allocator = allocator;
	node->type = type;
	node->range = range;
	node->parent = NULL;
	node->first_child = NULL;
	node->last_child = NULL;
	node->next = NULL;
	node->prev = NULL;
	
	// If requested node is a stream container, automatically add a stream.
	if (type == S_NODE_TITLE || type == S_NODE_LINE) {
		ASTNode *stream = ast_node_new(allocator, S_NODE_STREAM, location, length);
		ast_node_add_child(node, stream);
	}
	
	return node;
}

void ast_node_free(ASTNode *node)
{
	NodeAllocator *allocator = node->allocator;
	
	allocator->release(allocator, node);
}

const char *ast_node_type_description(ASTNodeType type)
{
	switch (type) {
		case S_NODE_DOCUMENT:
			return "document";
		case S_NODE_HEADER:
			return "header";
		case S_NODE_DESCRIPTION:
			return "description";
		case S_NODE_SIMULTANEOUS_CUES:
			return "simultaneous cues";
		case S_NODE_FACSIMILE:
			return "facsimile";
		case S_NODE_THEMATIC_BREAK:
			return "thematic break";
		case S_NODE_END:
			return "end";
		case S_NODE_CUE:
			return "cue";
		case S_NODE_LYRIC_DIRECTION:
			return "lyric direction";
		case S_NODE_PLAIN_DIRECTION:
			return "plain direction";
		case S_NODE_LINE:
			return "line";
		case S_NODE_STREAM:
			return "stream";
		case S_NODE_KEYWORD:
			return "keyword";
		case S_NODE_IDENTIFIER:
			return "identifier";
		case S_NODE_TITLE:
			return "title";
		case S_NODE_NAME:
			return "name";
		case S_NODE_URL:
			return "url";
		case S_NODE_LITERAL:
			return "literal";
		case S_NODE_EMPHASIS:
			return "emphasis";
		case S_NODE_STRONG:
			return "strong";
		case S_NODE_REFERENCE:
			return "reference";
		case S_NODE_PARENTHETICAL:
			return "parenthetical";
		case S_NODE_COMMENT:
			return "comment";
		default:
			printf("Unrecognized node type: %i", type);
			abort();
			break;
	}
	
	return "";
}

int ast_node_is_type(ASTNode *node, ASTNodeType type)
{
	return (node && node->type == type);
}

int ast_node_is_direction(ASTNode * node)
{
	return node->type == S_NODE_PLAIN_DIRECTION || node->type == S_NODE_LYRIC_DIRECTION;
}

int ast_node_is_stream_container(ASTNode *node)
{
	return node->type == S_NODE_TITLE || node->type == S_NODE_LINE || node->type == S_NODE_DESCRIPTION;
}

void ast_node_extend_length_to_include_child(ASTNode *node, ASTNode *child)
{
	node->range.length = s_range_max(child->range) - node->range.location;
}

void ast_node_add_child(ASTNode *node, ASTNode *child)
{
	child->parent = node;

	if (node->last_child) {
		node->last_child->next = child;
		child->prev = node->last_child;
	} else {
		node->first_child = child;
	}

	node->last_child = child;
}

void ast_node_unlink(ASTNode *node)
{
	if (node->parent) {
		if (node->parent->first_child == node)
			node->parent->first_child = node->next;
		if (node->parent->last_child == node)
			node->parent->last_child = node->prev;
	}
	
	if (node->prev) {
		node->prev->next = node->next;
	}
	
	if (node->next) {
		node->next->prev = node->prev;
	}
}

static void ast_node_print_single_description(ASTNode *node)
{
	const char * tdesc = ast_node_type_description(node->type);
	
	printf("%s %p {%u, %u}", tdesc, node, node->range.location, node->range.length);
}

void ast_node_print_description(ASTNode *node, int recurse)
{
	if (recurse) {
		Walker *w = walker_new(node);
		WalkerEvent event;
		
		int indent = 0;
		while ((event = walker_next(w)) != EVENT_DONE) {
			ASTNode *current = walker_get_current_node(w);
			
			if (event == EVENT_ENTER) {
				for (size_t i=0; i<indent; ++i)
					printf("| ");
				
				ast_node_print_single_description(current);
				printf("\n");
				
				++indent;
			} else if (event == EVENT_EXIT) {
				--indent;
			}
		}
		
		free(w);
	} else {
		ast_node_print_single_description(node);
	}
}
