
#ifndef cue_h
#define cue_h

#include <stdint.h>
#include <stddef.h>

#include "nodes.h"
#include "Walker.h"

typedef struct CueParser CueParser;

/** Creates a CueParser from a UTF-8 encoded string `buff` of size `len`. It
 * is the client's responsibility to ensure `buff` is a valid UTF-8 string.
 */
CueParser *cue_parser_from_utf8(const char *buff, size_t len);

void cue_parser_free(CueParser *parser);

CueNode *cue_parser_get_root(CueParser *parser);

void *cue_parser_get_table_of_contents(CueParser *parser);

#endif /* cue_h */
