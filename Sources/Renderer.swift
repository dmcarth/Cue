//
//  Renderer.swift
//  Cue
//
//  Created by Dylan McArthur on 2/20/17.
//
//

public protocol Renderer {
	associatedtype Context
	var parser: Cue { get }
	
	// Document-level callbacks
	func renderWillBegin(range: Range<Int>, in context: Context)
	func renderDidFinish(range: Range<Int>, in context: Context)
	
	// Block-level callbacks
	func renderHeader(_ header: Header, in context: Context)
	func renderDescription(_ description: Description, in context: Context)
	func renderCues(_ cueContainer: CueContainer, in context: Context)
	func renderLyrics(_ lyricContainer: LyricContainer, in context: Context)
	func renderFacsimiles(_ facsimileContainer: FacsimileContainer, in context: Context)
	func renderEndBlock(_ endBlock: EndBlock, in context: Context)
	
	// Inline callbacks
	func renderLiteral(_ literal: Literal, in context: Context)
	func renderEmphasis(_ emphasis: Emphasis, in context: Context)
	func renderReference(_ reference: Reference, in context: Context)
	func renderComment(_ comment: Comment, in context: Context)
}

extension Renderer {
	
	/// Triggers a render operation for the whole document. The given context will be passed by reference to the whole renderer and should be unique for each render operation.
	///
	/// - Parameter context: A rendering context.
	public func render(in context: Context) {
		_render(nodes: parser.ast.children, range: parser.ast.range, in: context)
	}
	
	/// Triggers a render operation for a portion of the document. You are responsible for providing a context with proper state information (if necessary). The given context will be passed by reference to the whole renderer and should be unique for each render operation.
	///
	/// - Parameters:
	///   - range: The range of bytes to be rendered.
	///   - context: A rendering context.
	public func render(range: Range<Int>, in context: Context) {
		let dirtyNodes = parser.ast.childNodes(from: range.lowerBound, to: range.upperBound)
		let lowerBound = dirtyNodes.first?.rangeIncludingMarkers.lowerBound ?? range.lowerBound
		let upperBound = dirtyNodes.last?.rangeIncludingMarkers.upperBound ?? range.upperBound
		
		_render(nodes: dirtyNodes, range: lowerBound..<upperBound, in: context)
	}
	
	private func _render(nodes: [Node], range: Range<Int>, in context: Context) {
		renderWillBegin(range: range, in: context)
		
		for node in nodes {
			switch node {
			case let header as Header:
				renderHeader(header, in: context)
			case let description as Description:
				renderDescription(description, in: context)
			case let cueContainer as CueContainer:
				renderCues(cueContainer, in: context)
			case let facsimileContainer as FacsimileContainer:
				renderFacsimiles(facsimileContainer, in: context)
			case let endBlock as EndBlock:
				renderEndBlock(endBlock, in: context)
			default:
				print("error: unknown block \(node)")
			}
		}
		
		renderDidFinish(range: range, in: context)
	}
	
}

// MARK: - Render Helps
extension Renderer {
	
	public func stringFromNode(_ node: Node) -> String {
		let bytes = parser.data[node.range]
		let scalars = UTF16.scalars(from: bytes)
		let scalarView = String.UnicodeScalarView(scalars)
		return String(scalarView)
	}
	
	public func renderInlines(_ nodes: [Node], in context: Context) {
		for node in nodes {
			switch node {
			case let literal as Literal:
				renderLiteral(literal, in: context)
			case let emphasis as Emphasis:
				renderEmphasis(emphasis, in: context)
			case let reference as Reference:
				renderReference(reference, in: context)
			case let comment as Comment:
				renderComment(comment, in: context)
			default:
				print("error: unknown inline: \(node)")
			}
		}
	}
	
}
