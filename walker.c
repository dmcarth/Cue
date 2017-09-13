
#include "walker.h"
#include <stdio.h>
#include <stdlib.h>

walker * walker_new(s_node * root) {
	walker_state curr = { EVENT_NONE, NULL };
	
	walker_state next = { EVENT_ENTER, root };
	
	walker * w = malloc(sizeof(walker));
	
	w->root = root;
	w->curr = curr;
	w->next = next;
	
	return w;
}

walker_event walker_next(walker * w) {
	// set current state
	walker_event event = w->next.ev;
	s_node * node = w->next.node;
	
	w->curr = w->next;
	
	// if done, return early
	if (event == EVENT_DONE)
		return event;
	
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
