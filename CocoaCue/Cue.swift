//
//  Cue.swift
//  CocoaCue
//
//  Created by Dylan McArthur on 9/5/17.
//  Copyright © 2017 Dylan McArthur. All rights reserved.
//

import Foundation

public struct Cue {
	let p: Parser
	
	public init(_ str: String) {
		p = Parser(string: str)
	}
	
	public func dump() {
		p.printOutline()
	}
	
	public func pretty() -> String {
		return p.prettyOutline()
	}

}
