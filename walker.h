
#ifndef walker_h
#define walker_h

#include "nodes.h"

typedef enum {
	EVENT_NONE,
	EVENT_ENTER,
	EVENT_EXIT,
	EVENT_DONE
} walker_event;

typedef struct walker walker;

walker * walker_new(s_node *root);

walker_event walker_next(walker *w);

s_node *walker_get_current_node(walker *w);

#endif /* walker_h */
