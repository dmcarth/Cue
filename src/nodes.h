
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
} ASTNodeType;

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

typedef struct NodeAllocator NodeAllocator;

typedef struct ASTNode
{
	NodeAllocator *allocator;
	uint32_t type;
	
	SRange range;
	
	struct ASTNode * parent;
	struct ASTNode * first_child;
	struct ASTNode * last_child;
	struct ASTNode * next;
	struct ASTNode * prev;
	
	union {
		struct {
			uint32_t type;
			struct ASTNode *keyword;
			struct ASTNode *id;
			struct ASTNode *title;
		} header;
		struct {
			int isDual;
			struct ASTNode *name;
			struct ASTNode *direction;
		} cue;
	} data;
} ASTNode;

struct NodeAllocator {
	ASTNode *(*alloc)(struct NodeAllocator*);
	void (*release)(struct NodeAllocator*, ASTNode *);
	void *data;
};

ASTNode *ast_node_new(NodeAllocator *allocator,
					  ASTNodeType type,
					  uint32_t loc,
					  uint32_t len);

void ast_node_free(ASTNode *node);

void ast_node_add_child(ASTNode *node,
						ASTNode *child);

void ast_node_extend_length_to_include_child(ASTNode *node,
											 ASTNode *child);

int ast_node_is_type(ASTNode *node,
					 ASTNodeType type);

int ast_node_is_direction(ASTNode * node);

void ast_node_unlink(ASTNode *node);

void ast_node_print_description(ASTNode *node,
								int recurse);

#endif /* nodes_h */
