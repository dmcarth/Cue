
#ifndef utf16_h
#define utf16_h

#include "cp_buff.h"

int utf16_scan_for_cp(uint16_t *utf16, size_t len, uint32_t * cp);

int utf16_scan_code_points_into_stack(uint16_t *utf16, size_t len, cp_buff * buff);

#endif /* utf16_h */
