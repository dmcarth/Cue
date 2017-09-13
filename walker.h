
#ifndef walker_h
#define walker_h

#include "nodes.h"

typedef enum {
	EVENT_NONE,
	EVENT_ENTER,
	EVENT_EXIT,
	EVENT_DONE
} walker_event;

typedef struct {
	walker_event ev;
	s_node * node;
} walker_state;

typedef struct {
	s_node * root;
	walker_state curr;
	walker_state next;
} walker;

walker * walker_new(s_node * root);

walker_event walker_next(walker * w);

#define walker_get_current_node(w) w->curr.node

#endif /* walker_h */
