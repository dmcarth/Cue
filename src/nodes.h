
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
} CueNodeType;

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

struct CueNode
{
	uint32_t type;
	
	SRange range;
	
	struct CueNode * parent;
	struct CueNode * first_child;
	struct CueNode * last_child;
	struct CueNode * next;
	struct CueNode * prev;
	
	union {
		struct {
			uint32_t type;
			struct CueNode *keyword;
			struct CueNode *id;
			struct CueNode *title;
		} header;
		struct {
			int isDual;
			struct CueNode *name;
			struct CueNode *direction;
		} cue;
	} data;
};

typedef struct CueNode CueNode;

void cue_node_add_child(CueNode *node, CueNode *child);

void cue_node_extend_length_to_include_child(CueNode *node, CueNode *child);

int cue_node_is_type(CueNode *node, CueNodeType type);

int cue_node_is_direction(CueNode * node);

void cue_node_unlink(CueNode *node);

void cue_node_print_description(CueNode *node, int recurse);

#endif /* nodes_h */
