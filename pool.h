
#ifndef pool_h
#define pool_h

#include "nodes.h"

typedef struct pool pool;

pool *pool_new(void);

void pool_free(pool *p);

s_node *pool_create_node(pool *p, SNodeType type, uint32_t loc, uint32_t len);

void pool_release_node(pool *p, s_node *node);

#endif /* pool_h */
