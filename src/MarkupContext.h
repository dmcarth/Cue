
#ifndef MarkupContext_h
#define MarkupContext_h

#include "StringBuffer.h"

typedef struct MarkupContext MarkupContext;

MarkupContext *markup_context_new(void);

void markup_context_free(MarkupContext *ctx);

StringBuffer *markup_context_get_string(MarkupContext *ctx);

void markup_context_put(MarkupContext *ctx,
						const char *a_string,
						uint32_t a_length);

void markup_context_push_indent(MarkupContext *ctx);

void markup_context_pop_indent(MarkupContext *ctx);

void markup_context_set_needs_new_line(MarkupContext *ctx);

#endif /* MarkupContext_h */
