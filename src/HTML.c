
#include "HTML.h"

#include <stdlib.h>

#include "nodes.h"
#include "Walker.h"
#include "MarkupContext.h"

void render_div_tag_to_markup_context(const char *class,
									  uint32_t class_length,
									  int entering,
									  MarkupContext *ctx)
{
	if (entering) {
		markup_context_set_needs_new_line(ctx);
		markup_context_put(ctx, "<div class=\"", 12);
		markup_context_put(ctx, class, class_length);
		markup_context_put(ctx, "\">", 2);
		markup_context_set_needs_new_line(ctx);
		markup_context_push_indent(ctx);
	} else {
		markup_context_pop_indent(ctx);
		markup_context_set_needs_new_line(ctx);
		markup_context_put(ctx, "</div>", 6);
		markup_context_set_needs_new_line(ctx);
	}
}

void render_p_tag_in_markup_context(MarkupContext *ctx,
									int entering)
{
	if (entering) {
		markup_context_set_needs_new_line(ctx);
		markup_context_put(ctx, "<p>", 3);
	} else {
		markup_context_put(ctx, "</p>", 4);
		markup_context_set_needs_new_line(ctx);
	}
}

void render_inline_tag_to_markup_context(const char *tag,
										 WalkerEvent event,
										 MarkupContext *ctx)
{
	if (event == EVENT_ENTER) {
		markup_context_put(ctx, "", 0);
	} else {
		markup_context_put(ctx, "", 0);
	}
}

void render_node_to_markup_context(ASTNode *node,
								   WalkerEvent event,
								   const char *source,
								   MarkupContext *ctx)
{
	int entering = (event == EVENT_ENTER);
	
	switch ((ASTNodeType)node->type) {
		case S_NODE_HEADER: {
			int headerType = node->as.header.type;
			char level = (headerType == HEADER_FORCED) ? '1' : headerType + '1';
			if (entering) {
				markup_context_set_needs_new_line(ctx);
				markup_context_put(ctx, "<h", 2);
				markup_context_put(ctx, &level, 1);
				markup_context_put(ctx, ">", 1);
			} else {
				markup_context_put(ctx, "</h", 3);
				markup_context_put(ctx, &level, 1);
				markup_context_put(ctx, ">", 1);
				markup_context_set_needs_new_line(ctx);
			}
			break;
		}
		case S_NODE_DESCRIPTION:
			render_p_tag_in_markup_context(ctx, entering);
			break;
		case S_NODE_SIMULTANEOUS_CUES:
			render_div_tag_to_markup_context("simultaneous_cues", 17, entering, ctx);
			break;
		case S_NODE_FACSIMILE:
			render_div_tag_to_markup_context("facsimile", 9, entering, ctx);
			break;
		case S_NODE_THEMATIC_BREAK:
			if (entering) {
				markup_context_set_needs_new_line(ctx);
				markup_context_put(ctx, "<hr />", 6);
				markup_context_set_needs_new_line(ctx);
			}
			break;
		case S_NODE_END:
			render_div_tag_to_markup_context("end", 3, entering, ctx);
			break;
		case S_NODE_CUE:
			render_div_tag_to_markup_context("cue", 3, entering, ctx);
			break;
		case S_NODE_LYRIC_DIRECTION:
			render_div_tag_to_markup_context("lyrics", 6, entering, ctx);
			break;
		case S_NODE_PLAIN_DIRECTION:
			render_div_tag_to_markup_context("direction", 9, entering, ctx);
			break;
		case S_NODE_LINE:
			render_p_tag_in_markup_context(ctx, entering);
			break;
		case S_NODE_KEYWORD:
			break;
		case S_NODE_IDENTIFIER:
			break;
		case S_NODE_TITLE:
			break;
		case S_NODE_NAME:
			break;
		case S_NODE_LITERAL:
			break;
		case S_NODE_EMPHASIS:
			break;
		case S_NODE_STRONG:
			break;
		case S_NODE_REFERENCE:
			break;
		case S_NODE_PARENTHETICAL:
			break;
		default:
			break;
	}
}

void render_html_to_markup_context(MarkupContext *ctx,
								   ASTNode *root,
								   const char *source)
{
	Walker *walker = walker_new(root);
	WalkerEvent event;
	
	while ((event = walker_next(walker)) != EVENT_DONE) {
		ASTNode *current = walker_get_current_node(walker);
		
		render_node_to_markup_context(current, event, source, ctx);
	}
	
	free(walker);
}
