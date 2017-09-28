
#include "pool.h"
#include "walker.h"
#include "mem.h"
#include <stdio.h>

// We store pre-allocated nodes in buckets of varying sizes. Each bucket also holds a reference to the next bucket in the list.
struct bucket {
	struct bucket *next;
	s_node *first;
	size_t head;
	size_t len;
};

typedef struct bucket bucket;

// This pool maintains a linked list of buckets. cap represents the total capacity of all buckets combined.
struct pool {
	bucket *first;
	bucket *last;
	size_t cap;
};

bucket *bucket_new(size_t len) {
	bucket *b = c_malloc(sizeof(bucket));
	
	b->next = NULL;
	b->first = c_malloc(len * sizeof(s_node));
	b->head = 0;
	b->len = len;
	
	return b;
}

pool *pool_new() {
	pool *p = c_malloc(sizeof(pool));
	
	size_t cap = 16;
	
	p->first = bucket_new(cap);
	p->last = p->first;
	p->cap = cap;
	
	return p;
}

void pool_free(pool *p) {
	bucket *b = p->first;
	bucket *next;
	
	while (b) {
		free(b->first);
		
		next = b->next;
		
		free(b);
		
		b = next;
	}
	
	free(p);
}

s_node *pool_create_node(pool *p, s_node_type type, uint32_t loc, uint32_t len) {
	bucket *b = p->last;
	
	// If current bucket is full, create a new one.
	if (b->head >= b->len) {
		// We want our pool to grow exponentially to amortize the cost of bucket allocation. Make each new bucket equal to the pool's current capacity to double its size.
		size_t newlen = p->cap;
		b = bucket_new(newlen);
		p->last->next = b;
		p->last = b;
		p->cap += b->len;
	}
	
	// Obtain pointer to next available s_node and increment b->head.
	s_node *node = b->first + b->head++;
	
	// Setup node.
	s_range range = { loc, len };
	
	node->type = type;
	node->range = range;
	node->parent = NULL;
	node->first_child = NULL;
	node->last_child = NULL;
	node->next = NULL;
	node->prev = NULL;
	
	// If requested node is a stream container, automatically add a stream.
	if (type == S_NODE_TITLE || type == S_NODE_LINE) {
		s_node *stream = pool_create_node(p, S_NODE_STREAM, loc, len);
		s_node_add_child(node, stream);
	}
	
	return node;
}

// Releases a given s_node pointer back into the pool. Assumes that s_node is at the top of the stack. If node isn't at the top of the stack, it will persist in memory until the pool is freed.
void pool_release_node(pool *p, s_node *node) {
	bucket *b = p->last;
	
	if (b->first + b->head - 1 == node) {
		--b->head;
		return;
	} else {
		printf("Pool failed to release ");
		
		s_node_print_description(node, 0);
		
		printf(" because it wasn't at the top of the stack.\n");
	}
}
