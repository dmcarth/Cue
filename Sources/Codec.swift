//
//  Codec.swift
//  Cue
//
//  Created by Dylan McArthur on 1/30/17.
//
//

public protocol Codec {
	associatedtype CodeUnit: Comparable
	static func fromASCII(_ char: UInt8) -> CodeUnit
	static func scalars<S: Sequence>(from units: S) -> [UnicodeScalar] where S.Iterator.Element == CodeUnit
}

extension Codec {
	static var linefeed: CodeUnit { return fromASCII(0x0a) }
	static var carriage: CodeUnit { return fromASCII(0x0d) }
	static var space: CodeUnit { return fromASCII(0x20) }
	static var tab: CodeUnit { return fromASCII(0x09) }
	static var hyphen: CodeUnit { return fromASCII(0x2d) }
	static var slash: CodeUnit { return fromASCII(0x2f) }
	static var rightAngle: CodeUnit { return fromASCII(0x3e) }
	static var tilde: CodeUnit { return fromASCII(0x7e) }
	static var caret: CodeUnit { return fromASCII(0x5e) }
	static var colon: CodeUnit { return fromASCII(0x3a) }
	static var openBracket: CodeUnit { return fromASCII(0x5b) }
	static var closeBracket: CodeUnit { return fromASCII(0x5d) }
	static var asterisk: CodeUnit { return fromASCII(0x2a) }
	static var A: CodeUnit { return fromASCII(0x41) }
	static var C: CodeUnit { return fromASCII(0x43) }
	static var E: CodeUnit { return fromASCII(0x45) }
	static var P: CodeUnit { return fromASCII(0x50) }
	static var S: CodeUnit { return fromASCII(0x53) }
	static var T: CodeUnit { return fromASCII(0x54) }
	static var a: CodeUnit { return fromASCII(0x61) }
	static var c: CodeUnit { return fromASCII(0x63) }
	static var d: CodeUnit { return fromASCII(0x64) }
	static var e: CodeUnit { return fromASCII(0x65) }
	static var g: CodeUnit { return fromASCII(0x67) }
	static var h: CodeUnit { return fromASCII(0x68) }
	static var n: CodeUnit { return fromASCII(0x6e) }
	static var p: CodeUnit { return fromASCII(0x70) }
	static var r: CodeUnit { return fromASCII(0x72) }
	static var t: CodeUnit { return fromASCII(0x74) }
}

extension UTF16: Codec {
	
	public static func fromASCII(_ char: UInt8) -> UInt16 {
		return UInt16(char)
	}
	
	public static func scalars<S : Sequence>(from units: S) -> [UnicodeScalar] where S.Iterator.Element == UInt16 {
		var codec = UTF16()
		var iter = units.makeIterator()
		var scalars = [UnicodeScalar]()
		while case .scalarValue(let v) = codec.decode(&iter) {
			scalars.append(v)
		}
		return scalars
	}
	
}
