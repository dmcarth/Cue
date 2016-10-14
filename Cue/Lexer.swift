//
//  CueParser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import Foundation

public class CueLexer {
	
	public static func lex(bytes: [UInt16]) -> [CueLexerToken] {
		var tokens = [CueLexerToken]()
		
		var index = 0
		var location = 0
		var length = 0
		var offset = 0
		var beginningOfLine = true
		var blockType = CueNodeType.description
		var buffer = [UInt16]()
		//buffer.reserveCapacity(100)
		
		while index < bytes.count {
			let c = bytes[index]
			
			// newlines
			if c == 0x000a || c == 0x000d { // '\n', '\r'
				buffer.append(c)
				let token = CueLexerToken(type: blockType, text: buffer, location: location, length: length+1, offset: offset)
				tokens.append(token)
				
				beginningOfLine = true
				index += 1
				location = index
				length = 0
				offset = 0
				blockType = .description
				buffer = []
				continue
			}
			
			// at the beginning of a line, determine it's type
			if beginningOfLine {
				beginningOfLine = false
				
				let maxPrefix = min(index+24, bytes.endIndex)
				let prefix = bytes[index..<maxPrefix]
				
				if canParseScene(fromBytes: prefix, startingAtIndex: index) {
					blockType = .scene
					length = 6
					offset = length
					index += length
					continue
				} else if canParseComment(fromBytes: prefix, startingAtIndex: index) {
					blockType = .comment
					length = 2
					offset = length
					index += length
					continue
				} else if let name = cueName(fromBytes: prefix, startingAtIndex: index) {
					blockType = .cue(name)
					length = name.characters.count + 1
					offset = length
					index += length
					continue
				}
			}
			
			buffer.append(c)
			
			index += 1
			length += 1
		}
		
		return tokens
	}
	
	private static func canParseScene(fromBytes col: ArraySlice<UInt16>, startingAtIndex i: Int) -> Bool {
		if col.endIndex < i+6 {
			return false
		}
		if (col[i] == 0x0053 || col[i] == 0x0073) && col[i+1] == 0x0063 && col[i+2] == 0x0065 && col[i+3] == 0x006e && col[i+4] == 0x0065 && col[i+5] == 0x0020 { // 'S'||'s', 'c', 'e', 'n', 'e', ' '
			return true
		}
		return false
	}
	
	private static func canParseComment(fromBytes col: ArraySlice<UInt16>, startingAtIndex i: Int) -> Bool {
		if col.endIndex < i+2 {
			return false
		}
		if col[i] == 0x002f && col[i+1] == 0x002f { // '//'
			return true
		}
		return false
	}
	
	private static func cueName(fromBytes col: ArraySlice<UInt16>, startingAtIndex i: Int) -> String? {
		var ind = i
		while ind < col.endIndex {
			let c = col[ind]
			if c == 0x000a || c == 0x000d { //newline
				return nil
			}
			else if ind > col.startIndex && c == 0x003a { // ':'
				let subcol = Array(col.prefix(upTo: ind))
				let string = String(utf16CodeUnits: subcol, count: subcol.count)
				
				return string
			}
			ind += 1
		}
		
		return nil
	}
}
