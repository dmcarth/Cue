
#include "walker.h"
#include <stdio.h>
#include <stdlib.h>
#include "mem.h"

typedef struct {
	walker_event ev;
	s_node * node;
} walker_state;

struct walker {
	s_node * root;
	walker_state curr;
	walker_state next;
};

walker * walker_new(s_node * root) {
	walker_state curr = { EVENT_NONE, NULL };
	walker_state next = { EVENT_ENTER, root };
	
	walker * w = c_malloc(sizeof(walker));
	
	w->root = root;
	w->curr = curr;
	w->next = next;
	
	return w;
}

// Uses similar walking algorithm to cmark's iterator in https://github.com/commonmark/cmark/blob/master/src/iterator.c
walker_event walker_next(walker * w) {
	// Make next state the current state.
	w->curr = w->next;
	walker_event event = w->curr.ev;
	s_node * node = w->curr.node;
	
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

s_node *walker_get_current_node(walker *w) {
	return w->curr.node;
}
