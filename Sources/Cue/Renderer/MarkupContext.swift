//
//  MarkupContext.swift
//  Cue
//
//  Created by Dylan McArthur on 4/3/17.
//
//

public class MarkupContext {
	
	public var string: String = ""
	
	public let counter = HeaderCounter()
	
	internal var indent = 0
	
	internal var needsNewLine = false
	
	public func append(_ aString: String) {
		if needsNewLine {
			string.append("\n")
			addIndent()
			needsNewLine = false
		}
		
		string.append(aString)
	}
	
	internal func addIndent() {
		var pad = ""
		for _ in 0..<indent {
			pad += "\t"
		}
		string.append(pad)
	}
	
	public func pushIndent() {
		indent += 1
	}
	
	public func popIndent() {
		guard indent > 0 else { return }
		
		indent -= 1
	}
	
	public func setNeedsNewLine() {
		needsNewLine = true
	}
	
	public func nextID(for type: Header.HeaderType) -> String? {
		return counter.nextID(for: type)
	}
	
}

