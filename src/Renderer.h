
#ifndef Renderer_h
#define Renderer_h

#include "nodes.h"
#include "MarkupContext.h"

typedef struct {
	void (*header)(MarkupContext*,ASTNode*);
	void (*description)(MarkupContext*,ASTNode*);
	void (*simultaneous_cues)(MarkupContext*,ASTNode*);
	void (*lyrics)(MarkupContext*,ASTNode*);
	void (*facsimile)(MarkupContext*,ASTNode*);
	void (*thematic_break)(MarkupContext*,ASTNode*);
	void (*end)(MarkupContext*,ASTNode*);
} RendererCallbacks;

void render_header(MarkupContext *ctx, char *keyword, char *identifier, char *title);

#endif /* Renderer_h */
