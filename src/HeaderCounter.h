
#ifndef HeaderCounter_h
#define HeaderCounter_h

#include "nodes.h"

typedef struct {
	int act_count;
	int scene_count;
	int page_count;
	int frame_count;
} HeaderCounter;

void header_counter_increment_header_count(HeaderCounter *counter,
										   HeaderType type);

#endif /* HeaderCounter_h */
