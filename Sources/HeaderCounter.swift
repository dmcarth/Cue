//
//  HeaderCounter.swift
//  Cue
//
//  Created by Dylan McArthur on 3/18/17.
//
//

public enum IdentifierRenderOptions {
	case unsanitized
	case numbers
	case romanNumerals
}

public class HeaderCounter {
	
	var options: [Header.HeaderType: IdentifierRenderOptions]
	
	var counter: [Header.HeaderType: Int] = [:]
	
	init(options: [Header.HeaderType: IdentifierRenderOptions]=[:]) {
		self.options = options
	}
	
	public func nextID(for type: Header.HeaderType) -> String? {
		var currCount = counter[type] ?? 0
		currCount += 1
		counter[type] = currCount
		
		let style = options[type] ?? .unsanitized
		
		switch style {
		case .unsanitized:		return nil
		case .numbers:			return "\(currCount)"
		case .romanNumerals:	return currCount.romanNumerals
		}
	}
	
}
