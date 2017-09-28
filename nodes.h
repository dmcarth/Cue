
#ifndef nodes_h
#define nodes_h

#include <stdint.h>

typedef enum {
	S_NODE_DOCUMENT,
	
	// Block-level
	S_NODE_HEADER,
	S_NODE_DESCRIPTION,
	S_NODE_SIMULTANEOUS_CUES,
	S_NODE_FACSIMILE,
	S_NODE_THEMATIC_BREAK,
	S_NODE_END,
	
	S_NODE_CUE,
	S_NODE_LYRIC_DIRECTION,
	S_NODE_PLAIN_DIRECTION,
	S_NODE_LINE,
	S_NODE_STREAM,
	
	S_NODE_KEYWORD,
	S_NODE_IDENTIFIER,
	S_NODE_TITLE,
	S_NODE_NAME,
	S_NODE_URL,
	
	// Inlines
	S_NODE_LITERAL,
	S_NODE_EMPHASIS,
	S_NODE_STRONG,
	S_NODE_REFERENCE,
	S_NODE_PARENTHETICAL,
	S_NODE_COMMENT,
} SNodeType;

typedef struct {
	uint32_t start, end;
} s_range;

typedef enum {
	HEADER_ACT,
	HEADER_SCENE,
	HEADER_PAGE,
	HEADER_FRAME,
	HEADER_FORCED
} header_type;

struct s_node {
	uint32_t type;
	
	s_range range;
	
	struct s_node * parent;
	struct s_node * first_child;
	struct s_node * last_child;
	struct s_node * next;
	struct s_node * prev;
	
	union {
		struct {
			uint32_t type;
			struct s_node *keyword;
			struct s_node *id;
			struct s_node *title;
		} header;
		struct {
			int isDual;
			struct s_node *name;
			struct s_node *direction;
		} cue;
	} data;
};

typedef struct s_node s_node;

void s_node_add_child(s_node *node, s_node *child);

void s_node_extend_length_to_include_child(s_node *node, s_node *child);

int s_node_is_type(s_node *node, SNodeType type);

int s_node_is_direction(s_node * node);

void s_node_unlink(s_node *node);

void s_node_print_description(s_node *node, int recurse);

#endif /* nodes_h */
