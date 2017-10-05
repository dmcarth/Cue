
#include "MarkupContext.h"

#include <string.h>

#include "mem.h"

struct MarkupContext {
	StringBuffer *string;
	int indent;
	int needsNewLine;
};

MarkupContext *markup_context_new()
{
	MarkupContext *ctx = c_malloc(sizeof(MarkupContext));
	
	ctx->string = string_buffer_new();
	ctx->indent = 0;
	ctx->needsNewLine = 0;
	
	return ctx;
}

void markup_context_free(MarkupContext *ctx)
{
	string_buffer_free(ctx->string);
	
	free(ctx);
}

StringBuffer *markup_context_get_string(MarkupContext *ctx)
{
	return ctx->string;
}

void markup_context_add_indent(MarkupContext *ctx)
{
	for (int i = 0; i < ctx->indent; ++i) {
		string_buffer_put(ctx->string, "\t", 1);
	}
}

void markup_context_put(MarkupContext *ctx,
						const char *a_string,
						uint32_t a_length)
{
	if (ctx->needsNewLine) {
		string_buffer_put(ctx->string, "\n", 1);
		markup_context_add_indent(ctx);
		ctx->needsNewLine = 0;
	}
	
	string_buffer_put(ctx->string, a_string, a_length);
}

void markup_context_push_indent(MarkupContext *ctx)
{
	ctx->indent++;
}

void markup_context_pop_indent(MarkupContext *ctx)
{
	if (ctx->indent)
		ctx->indent--;
}

void markup_context_set_needs_new_line(MarkupContext *ctx)
{
	ctx->needsNewLine = 1;
}
