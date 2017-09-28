
#include "nodes.h"
#include "mem.h"
#include "walker.h"
#include <stdio.h>

const char *s_node_type_description(s_node_type type) {
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

int s_node_is_type(s_node *node, s_node_type type) {
	return (node && node->type == type);
}

int s_node_is_direction(s_node * node) {
	return node->type == S_NODE_PLAIN_DIRECTION || node->type == S_NODE_LYRIC_DIRECTION;
}

int s_node_is_stream_container(s_node *node) {
	return node->type == S_NODE_TITLE || node->type == S_NODE_LINE || node->type == S_NODE_DESCRIPTION;
}

void s_node_extend_length_to_include_child(s_node *node, s_node *child) {
	node->range.end = child->range.end;
}

void s_node_add_child(s_node *node, s_node *child) {
	child->parent = node;

	if (node->last_child) {
		node->last_child->next = child;
		child->prev = node->last_child;
	} else {
		node->first_child = child;
	}

	node->last_child = child;
}

void s_node_unlink(s_node *node) {
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

static void s_node_print_single_description(s_node *node) {
	const char * tdesc = s_node_type_description(node->type);
	
	printf("%s %p {%u, %u}", tdesc, node, node->range.start, node->range.end);
}

void s_node_print_description(s_node *node, int recurse) {
	if (recurse) {
		walker *w = walker_new(node);
		walker_event event;
		
		int indent = 0;
		while ((event = walker_next(w)) != EVENT_DONE) {
			s_node *current = walker_get_current_node(w);
			
			if (event == EVENT_ENTER) {
				for (size_t i=0; i<indent; ++i)
					printf("| ");
				
				s_node_print_single_description(current);
				printf("\n");
				
				++indent;
			} else if (event == EVENT_EXIT) {
				--indent;
			}
		}
		
		free(w);
	} else {
		s_node_print_single_description(node);
	}
}
