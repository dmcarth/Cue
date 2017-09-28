
#ifndef pool_h
#define pool_h

#include "nodes.h"

typedef struct pool pool;

pool *pool_new(void);

void pool_free(pool *p);

SNode *pool_create_node(pool *p, SNodeType type, uint32_t loc, uint32_t len);

void pool_release_node(pool *p, SNode *node);

#endif /* pool_h */
