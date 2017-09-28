
#ifndef cue_h
#define cue_h

#include "nodes.h"
#include "Walker.h"
#include <stdint.h>
#include "pool.h"

typedef struct CueDocument CueDocument;

void cue_document_free(CueDocument *doc);

SNode *cue_document_get_root(CueDocument *doc);

CueDocument *cue_document_from_utf8(const char *buff, size_t len);

#endif /* cue_h */
