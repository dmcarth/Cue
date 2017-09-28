
#include "mem.h"
#include <stdio.h>

void *c_malloc(size_t size)
{
	void *ptr = malloc(size);
	
	if (!ptr) {
		fprintf(stderr, "Allocation of size %zu failed.\n", size);
		abort();
	}
	
	return ptr;
}

void *c_calloc(size_t count, size_t size)
{
	void *ptr = calloc(count, size);
	
	if (!ptr) {
		fprintf(stderr, "Allocation of size %zu failed.\n", size * count);
		abort();
	}
	
	return ptr;
}

void *c_realloc(void *ptr, size_t size)
{
	void *newPtr = realloc(ptr, size);
	
	if (!newPtr) {
		fprintf(stderr, "Reallocation of size %zu failed.\n", size);
		abort();
	}
	
	return newPtr;
}
