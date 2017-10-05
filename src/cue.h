
#ifndef cue_h
#define cue_h

#include <stdint.h>
#include <stddef.h>

#include "nodes.h"
#include "Walker.h"

typedef struct CueDocument CueDocument;

NodeAllocator *stack_allocator_new(void);

void stack_allocator_free(NodeAllocator *node_allocator);

void stack_allocator_reset(NodeAllocator *node_allocator);

/** Creates a CueDocument from a UTF-8 encoded string `utf8` of size `len`. It
 * is the client's responsibility to ensure `utf8` is a valid UTF-8 string.
 */
CueDocument *cue_document_from_utf8(NodeAllocator *node_allocator,
									const char *buff,
									size_t len);

void cue_document_free(CueDocument *doc);

ASTNode *cue_document_get_root(CueDocument *doc);

void *cue_document_get_table_of_contents(CueDocument *doc);

#endif /* cue_h */
