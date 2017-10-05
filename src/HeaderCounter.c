
#include "HeaderCounter.h"

void header_counter_increment_header_count(HeaderCounter *counter,
										   HeaderType header_type)
{
	switch (header_type) {
		case HEADER_ACT:
			counter->act_count++;
			break;
		case HEADER_SCENE:
			counter->scene_count++;
			break;
		case HEADER_PAGE:
			counter->page_count++;
			break;
		case HEADER_FRAME:
			counter->frame_count++;
			break;
		default:
			break;
	}
}
