
#ifndef cue_h
#define cue_h

#include "nodes.h"
#include "walker.h"
#include <stdint.h>

typedef struct {
	s_node *root;
	// other tasty treats
} cue_document;

void cue_document_free(cue_document *doc);

cue_document *cue_document_from_utf16(uint16_t *buff, size_t len);

#endif /* cue_h */
