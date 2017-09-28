
#ifndef cue_h
#define cue_h

#include "nodes.h"
#include "walker.h"
#include <stdint.h>
#include "pool.h"

typedef struct cue_document cue_document;

void cue_document_free(cue_document *doc);

s_node *cue_document_get_root(cue_document *doc);

cue_document *cue_document_from_utf8(const char *buff, size_t len);

#endif /* cue_h */
