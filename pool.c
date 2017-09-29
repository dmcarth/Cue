
#include "pool.h"

#include <stdio.h>

#include "mem.h"

// We store pre-allocated nodes in buckets of varying sizes. Each bucket also holds a reference to the next bucket in the list.
struct Bucket
{
	struct Bucket *next;
	CueNode *first;
	size_t head;
	size_t len;
};

typedef struct Bucket Bucket;

// This pool maintains a linked list of buckets. cap represents the total capacity of all buckets combined.
struct Pool
{
	Bucket *first;
	Bucket *last;
	size_t cap;
};

Bucket *bucket_new(size_t len)
{
	Bucket *b = c_malloc(sizeof(Bucket));
	
	b->next = NULL;
	b->first = c_malloc(len * sizeof(CueNode));
	b->head = 0;
	b->len = len;
	
	return b;
}

Pool *pool_new()
{
	Pool *p = c_malloc(sizeof(Pool));
	
	size_t cap = 16;
	
	p->first = bucket_new(cap);
	p->last = p->first;
	p->cap = cap;
	
	return p;
}

void pool_free(Pool *p)
{
	Bucket *b = p->first;
	Bucket *next;
	
	while (b) {
		free(b->first);
		
		next = b->next;
		
		free(b);
		
		b = next;
	}
	
	free(p);
}

CueNode *pool_create_node(Pool *p, CueNodeType type, uint32_t loc, uint32_t len)
{
	Bucket *b = p->last;
	
	// If current bucket is full, create a new one.
	if (b->head >= b->len) {
		// We want our pool to grow exponentially to amortize the cost of bucket allocation. Make each new bucket equal to the pool's current capacity to double its size.
		size_t newlen = p->cap;
		b = bucket_new(newlen);
		p->last->next = b;
		p->last = b;
		p->cap += b->len;
	}
	
	// Obtain pointer to next available cue_node and increment b->head.
	CueNode *node = b->first + b->head++;
	
	// Setup node.
	SRange range = { loc, len };
	
	node->type = type;
	node->range = range;
	node->parent = NULL;
	node->first_child = NULL;
	node->last_child = NULL;
	node->next = NULL;
	node->prev = NULL;
	
	// If requested node is a stream container, automatically add a stream.
	if (type == S_NODE_TITLE || type == S_NODE_LINE) {
		CueNode *stream = pool_create_node(p, S_NODE_STREAM, loc, len);
		cue_node_add_child(node, stream);
	}
	
	return node;
}

// Releases a given cue_node pointer back into the pool. Assumes that cue_node is at the top of the stack. If node isn't at the top of the stack, it will persist in memory until the pool is freed.
void pool_release_node(Pool *p, CueNode *node)
{
	Bucket *b = p->last;
	
	if (b->first + b->head - 1 == node) {
		--b->head;
		return;
	} else {
		printf("Pool failed to release ");
		
		cue_node_print_description(node, 0);
		
		printf(" because it wasn't at the top of the stack.\n");
	}
}
