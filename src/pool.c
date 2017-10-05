
#include "cue.h"

#include <stdio.h>

#include "mem.h"

// We store pre-allocated nodes in buckets of varying sizes. Each bucket also holds a reference to the next bucket in the list.
typedef struct Bucket {
	struct Bucket *next;
	ASTNode *first;
	size_t head;
	size_t len;
} Bucket;

// This pool maintains a linked list of buckets. cap represents the total capacity of all buckets combined.
typedef struct Pool
{
	Bucket *first;
	Bucket *last;
	size_t cap;
} Pool;

Bucket *bucket_new(size_t len)
{
	Bucket *b = c_malloc(sizeof(Bucket));
	
	b->next = NULL;
	b->first = c_malloc(len * sizeof(ASTNode));
	b->head = 0;
	b->len = len;
	
	return b;
}

ASTNode *pool_create_node(NodeAllocator *node_allocator);

void pool_release_node(NodeAllocator *node_allocator, ASTNode *node);

NodeAllocator *stack_allocator_new()
{
	Pool *p = c_malloc(sizeof(Pool));
	
	size_t cap = 16;
	
	p->first = bucket_new(cap);
	p->last = p->first;
	p->cap = cap;
	
	NodeAllocator *node_allocator = c_malloc(sizeof(NodeAllocator));
	
	node_allocator->alloc = &pool_create_node;
	node_allocator->release = &pool_release_node;
	node_allocator->data = p;
	
	return node_allocator;
}

void stack_allocator_free(NodeAllocator *node_allocator)
{
	Pool *p = node_allocator->data;
	Bucket *b = p->first;
	Bucket *next;
	
	while (b) {
		free(b->first);
		
		next = b->next;
		
		free(b);
		
		b = next;
	}
	
	free(p);
	
	free(node_allocator);
}

ASTNode *pool_create_node(NodeAllocator *node_allocator)
{
	Pool *p = node_allocator->data;
	
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
	
	// Obtain pointer to next available ast_node and increment b->head.
	ASTNode *node = b->first + b->head++;
	
	return node;
}

// Releases a given ast_node pointer back into the pool. Assumes that ast_node is at the top of the stack. If node isn't at the top of the stack, it will persist in memory until the pool is freed.
void pool_release_node(NodeAllocator *node_allocator, ASTNode *node)
{
	Pool *p = node_allocator->data;
	
	Bucket *b = p->last;
	
	if (b->first + b->head - 1 == node) {
		--b->head;
		return;
	} else {
		printf("Pool failed to release ");
		
		ast_node_print_description(node, 0);
		
		printf(" because it wasn't at the top of the stack.\n");
	}
}
