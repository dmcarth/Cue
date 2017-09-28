
#ifndef walker_h
#define walker_h

#include "nodes.h"

typedef enum {
	EVENT_NONE,
	EVENT_ENTER,
	EVENT_EXIT,
	EVENT_DONE
} WalkerEvent;

typedef struct Walker Walker;

Walker * walker_new(s_node *root);

WalkerEvent walker_next(Walker *w);

s_node *walker_get_current_node(Walker *w);

#endif /* walker_h */
