
#ifndef mem_h
#define mem_h

#include <stdlib.h>

void *c_malloc(size_t size);

void *c_calloc(size_t count,
			   size_t size);

void *c_realloc(void *ptr,
				size_t size);

#endif /* mem_h */
