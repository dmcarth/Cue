//
//  HTML.swift
//  Cue
//
//  Created by Dylan McArthur on 3/17/17.
//
//

import Foundation

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

struct HTMLMarkupRenderer: MarkupRenderer {
	
	var parser: Cue
	
	var output: String {
		let ctx = MarkupContext()
		render(in: ctx)
		return ctx.string
	}
	
}

extension HTMLMarkupRenderer {
	
	func renderTag(_ tag: String, class name: String?, event: WalkerEvent, context: MarkupContext) {
		if event == .enter {
			let classAttr = (name != nil) ? " class=\"\(name!)\"" : ""
			
			context.setNeedsNewLine()
			context.append("<\(tag)\(classAttr)>")
			context.setNeedsNewLine()
			context.pushIndent()
		} else {
			context.popIndent()
			context.setNeedsNewLine()
			context.append("</\(tag)>")
			context.setNeedsNewLine()
		}
	}
	
	func renderInlineTag(_ tag: String, event: WalkerEvent, context: MarkupContext) {
		if event == .enter {
			renderText("<\(tag)>", in: context)
		} else {
			renderText("</\(tag)>", in: context)
		}
	}
	
	func renderDocumentTags(for document: Document, event: WalkerEvent, in context: MarkupContext) {
		renderTag("div", class: "document", event: event, context: context)
	}
	
	func renderHeaderTags(for header: Header, event: WalkerEvent, in context: MarkupContext) {
		var level: Int
		switch header.type {
		case .act:		level = 1
		case .chapter:	level = 2
		case .scene:	level = 3
		case .page:		level = 4
		case .forced:	level = 3
		}
		
		renderTag("h\(level)", class: nil, event: event, context: context)
	}
	
	func renderDescriptionTags(for description: Description, event: WalkerEvent, in context: MarkupContext) {
		renderTag("p", class: nil, event: event, context: context)
	}
	
	func renderEmphasisTags(for emphasis: Emphasis, event: WalkerEvent, in context: MarkupContext) {
		renderInlineTag("em", event: event, context: context)
	}
	
	func renderReference(_ reference: Reference, in context: MarkupContext) {
		//FIXME: Perform some actual business logic.
		
		let ref = stringFromNode(reference)
		var src = ""
		var alt = "Unknown source"
		
		if let validURL = URL(string: ref) {
			src = validURL.absoluteString
			alt = validURL.lastPathComponent
		}
		
		renderText("<img src=\'\(src)\' alt=\'\(alt)\'>", in: context)
	}
	
	func renderCueContainerTags(for cueContainer: CueContainer, event: WalkerEvent, in context: MarkupContext) {
		renderTag("div", class: "cueContainer", event: event, context: context)
	}
	
	func renderCueBlockTags(for cueBlock: CueBlock, event: WalkerEvent, in context: MarkupContext) {
		renderTag("div", class: "cue", event: event, context: context)
	}
	
	func renderNameTags(for name: Name, event: WalkerEvent, in context: MarkupContext) {
		renderTag("div", class: "name", event: event, context: context)
	}
	
	func renderDirectionTags(for direction: DirectionBlock, event: WalkerEvent, in context: MarkupContext) {
		renderTag("div", class: "direction", event: event, context: context)
	}
	
	func renderLyricContainerTags(for lyricContainer: LyricContainer, event: WalkerEvent, in context: MarkupContext) {
		renderTag("div", class: "lyrics", event: event, context: context)
	}
	
	func renderLyricBlockTags(for lyricBlock: LyricBlock, event: WalkerEvent, in context: MarkupContext) {
		renderTag("p", class: nil, event: event, context: context)
	}
	
	func renderFacsimileContainerTags(for facsimileContainer: FacsimileContainer, event: WalkerEvent, in context: MarkupContext) {
		renderTag("blockquote", class: nil, event: event, context: context)
	}
	
	func renderFacsimileBlockTags(for facsimileBlock: FacsimileBlock, event: WalkerEvent, in context: MarkupContext) {
		renderTag("p", class: nil, event: event, context: context)
	}
	
	func renderEndBlockTags(for endBlock: EndBlock, event: WalkerEvent, in context: MarkupContext) {
		renderTag("div", class: "end", event: event, context: context)
	}
	
	func renderHorizontalBreak(_ hrBreak: HorizontalBreak, in context: MarkupContext) {
		context.setNeedsNewLine()
		context.append("<hr>")
		context.setNeedsNewLine()
	}
	
}
