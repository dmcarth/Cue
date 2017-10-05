
#ifndef string_h
#define string_h

#include <stdint.h>

typedef struct {
	char *buffer;
	uint32_t length;
	uint32_t capacity;
} StringBuffer;

StringBuffer *string_buffer_new(void);

void string_buffer_free(StringBuffer *string);

void string_buffer_put(StringBuffer *string,
					   const char *a_string,
					   uint32_t a_len);

#endif /* string_h */
