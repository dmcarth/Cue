
#ifndef nodes_h
#define nodes_h

#include <stdint.h>

typedef enum
{
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

typedef struct
{
	uint32_t start, end;
} SRange;

typedef enum
{
	HEADER_ACT,
	HEADER_SCENE,
	HEADER_PAGE,
	HEADER_FRAME,
	HEADER_FORCED
} HeaderType;

struct SNode
{
	uint32_t type;
	
	SRange range;
	
	struct SNode * parent;
	struct SNode * first_child;
	struct SNode * last_child;
	struct SNode * next;
	struct SNode * prev;
	
	union {
		struct {
			uint32_t type;
			struct SNode *keyword;
			struct SNode *id;
			struct SNode *title;
		} header;
		struct {
			int isDual;
			struct SNode *name;
			struct SNode *direction;
		} cue;
	} data;
};

typedef struct SNode SNode;

void s_node_add_child(SNode *node, SNode *child);

void s_node_extend_length_to_include_child(SNode *node, SNode *child);

int s_node_is_type(SNode *node, SNodeType type);

int s_node_is_direction(SNode * node);

void s_node_unlink(SNode *node);

void s_node_print_description(SNode *node, int recurse);

#endif /* nodes_h */
