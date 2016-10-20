//
//  Cue.swift
//  Cue
//
//  Created by Dylan McArthur on 10/14/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import Foundation

public class CueDown {
	
	public init() {}
	
	public func parse(document buffer: [UInt8]) -> Node {
		let parser = CueParser()
		
		parser.process(buffer)
		
		let document = parser.finish()
		
		return document
	}
	
}
