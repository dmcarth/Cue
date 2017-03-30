//
//  Integer+romanNumerals.swift
//  Cue
//
//  Created by Dylan McArthur on 3/18/17.
//
//

extension Int {
	
	var romanNumerals: String {
		let valueMap = [
			(1000,	"M"),
			(900,	"CM"),
			(500,	"D"),
			(400,	"CD"),
			(100,	"C"),
			(90,	"XC"),
			(50,	"L"),
			(40,	"XL"),
			(10,	"X"),
			(9,		"IX"),
			(5,		"V"),
			(4,		"IV"),
			(1,		"I")
		]
		
		var rms = ""
		var curr = self
		for (value, roman) in valueMap {
			while value <= curr {
				rms += roman
				curr -= value
			}
		}
		return rms
	}
	
}
