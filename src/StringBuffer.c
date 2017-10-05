
#include "StringBuffer.h"

#include <string.h>

#include "mem.h"

StringBuffer *string_buffer_new()
{
	StringBuffer *str = c_malloc(sizeof(StringBuffer));
	
	uint32_t cap = 32;
	
	str->buff = malloc(sizeof(char) * cap);
	str->length = 0;
	str->capacity = cap;
	
	return str;
}

void string_buffer_free(StringBuffer *string)
{
	free(string->buff);
	
	free(string);
}

void string_buffer_resize(StringBuffer *string,
					   uint32_t new_cap)
{
	string->buff = c_realloc(string->buff, new_cap);
	
	string->capacity = new_cap;
}

void string_buffer_put(StringBuffer *string,
					   const char *a_string,
					   uint32_t a_len)
{
	while (string->length + a_len >= string->capacity)
		string_buffer_resize(string, string->capacity * 2);
	
	void *base_ptr = string->buff + string->length;
	
	memmove(base_ptr, a_string, a_len);
	
	string->length += a_len;
}
