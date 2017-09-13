
#include "utf16.h"

int utf16_scan_for_single_cp(uint16_t *utf16, size_t len) {
	uint16_t byte = utf16[0];
	
	return byte < 0xd800 || byte > 0xdfff;
}

int utf16_scan_for_surrogate_pair(uint16_t *utf16, size_t len, uint32_t * cp) {
	if (len < 2)
		return 0;
	
	uint16_t w1 = utf16[0];
	uint16_t w2 = utf16[1];
	
	// high surrogate
	if ((w1 >> 10) != 0x36)
		return 0;
	
	// low surrogate
	if ((w2 >> 10) != 0x37)
		return 0;
	
	*cp = ((uint32_t)(w1 & 0x3ff) << 10) | ((uint32_t)(w2 & 0x3ff)) + 0x10000;
	
	return 1;
}

int utf16_scan_for_cp(uint16_t *utf16, size_t len, uint32_t * cp) {
	if (len < 1)
		return 0;
	
	if (utf16_scan_for_single_cp(utf16, len)) {
		*cp = *utf16;
		return 1;
	}
	
	uint32_t scp;
	
	if (utf16_scan_for_surrogate_pair(utf16, len, &scp)) {
		*cp = scp;
		return 2;
	}
	
	return 0;
}

int utf16_scan_code_points_into_stack(uint16_t *utf16, size_t len, cp_buff * buff) {
	uint32_t curr = 0;
	
	while (curr < len) {
		uint32_t cp;
		int distance = utf16_scan_for_cp(utf16 + curr, len - curr, &cp);
		
		if (distance) {
			cp_tok tok = { cp, curr, distance};
			cp_buff_append(buff, tok);
			
			curr += distance;
		} else {
			return 0;
		}
	}
	
	return 1;
}
