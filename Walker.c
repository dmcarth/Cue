
#include "Walker.h"
#include <stdio.h>
#include <stdlib.h>
#include "mem.h"

typedef struct {
	WalkerEvent ev;
	SNode * node;
} WalkerState;

struct Walker {
	SNode * root;
	WalkerState curr;
	WalkerState next;
};

Walker * walker_new(SNode * root) {
	WalkerState curr = { EVENT_NONE, NULL };
	WalkerState next = { EVENT_ENTER, root };
	
	Walker * w = c_malloc(sizeof(Walker));
	
	w->root = root;
	w->curr = curr;
	w->next = next;
	
	return w;
}

// Uses similar walking algorithm to cmark's iterator in https://github.com/commonmark/cmark/blob/master/src/iterator.c
WalkerEvent walker_next(Walker * w) {
	// Make next state the current state.
	w->curr = w->next;
	WalkerEvent event = w->curr.ev;
	SNode * node = w->curr.node;
	
	// If done, return early.
	if (event == EVENT_DONE)
		return event;
	
	// We walk the tree depth-first, visiting each node twice: once before traversing its children and once immediately after. After all nodes have been visited, we emit DONE. With this pattern, we can use the current node and event to form a vector to the next node and event.
	if (event == EVENT_ENTER) {
		if (node->first_child) {
			w->next.ev = EVENT_ENTER;
			w->next.node = node->first_child;
		} else {
			w->next.ev = EVENT_EXIT;
			w->next.node = node;
		}
	} else if (node == w->root) {
		w->next.ev = EVENT_DONE;
		w->next.node = NULL;
	} else if (node->next) {
		w->next.ev = EVENT_ENTER;
		w->next.node = node->next;
	} else if (node->parent) {
		w->next.ev = EVENT_EXIT;
		w->next.node = node->parent;
	} else {
		fprintf(stderr, "Malformed tree, aborting.\n");
		abort();
	}
	
	return event;
}

SNode *walker_get_current_node(Walker *w) {
	return w->curr.node;
}
