
#ifndef cue_h
#define cue_h

#include <stdint.h>
#include <stddef.h>

#include "nodes.h"
#include "Walker.h"

typedef struct CueDocument CueDocument;

/** Creates a CueParser from a UTF-8 encoded string `buff` of size `len`. It
 * is the client's responsibility to ensure `buff` is a valid UTF-8 string.
 */
CueDocument *cue_document_from_utf8(const char *utf8, size_t len);

void cue_document_free(CueDocument *doc);

ASTNode *cue_document_get_root(CueDocument *doc);

void *cue_document_get_table_of_contents(CueDocument *doc);

#endif /* cue_h */
