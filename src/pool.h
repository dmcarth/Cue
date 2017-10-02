
#ifndef pool_h
#define pool_h

#include "nodes.h"

typedef struct Pool Pool;

Pool *pool_new(void);

void pool_free(Pool *p);

ASTNode *pool_create_node(Pool *p, ASTNodeType type, uint32_t loc, uint32_t len);

void pool_release_node(Pool *p, ASTNode *node);

#endif /* pool_h */
