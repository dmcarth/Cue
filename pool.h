
#ifndef pool_h
#define pool_h

#include "nodes.h"

typedef struct Pool Pool;

Pool *pool_new(void);

void pool_free(Pool *p);

SNode *pool_create_node(Pool *p, SNodeType type, uint32_t loc, uint32_t len);

void pool_release_node(Pool *p, SNode *node);

#endif /* pool_h */
