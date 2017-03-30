//
//  MarkupRenderer.swift
//  Cue
//
//  Created by Dylan McArthur on 3/23/17.
//
//

public protocol MarkupRenderer {
	var parser: Cue { get }
	
	func renderDocumentTags(for document: Document, event: WalkerEvent, in context: MarkupContext)
	func renderHeaderTags(for header: Header, event: WalkerEvent, in context: MarkupContext)
	func renderDescriptionTags(for description: Description, event: WalkerEvent, in context: MarkupContext)
	func renderEmphasisTags(for emphasis: Emphasis, event: WalkerEvent, in context: MarkupContext)
	func renderReference(_ reference: Reference, in context: MarkupContext)
	func renderCueContainerTags(for cueContainer: CueContainer, event: WalkerEvent, in context: MarkupContext)
	func renderCueBlockTags(for cueBlock: CueBlock, event: WalkerEvent, in context: MarkupContext)
	func renderNameTags(for name: Name, event: WalkerEvent, in context: MarkupContext)
	func renderDirectionTags(for direction: DirectionBlock, event: WalkerEvent, in context: MarkupContext)
	func renderLyricContainerTags(for lyricContainer: LyricContainer, event: WalkerEvent, in context: MarkupContext)
	func renderLyricBlockTags(for lyricBlock: LyricBlock, event: WalkerEvent, in context: MarkupContext)
	func renderFacsimileContainerTags(for facsimileContainer: FacsimileContainer, event: WalkerEvent, in context: MarkupContext)
	func renderFacsimileBlockTags(for facsimileBlock: FacsimileBlock, event: WalkerEvent, in context: MarkupContext)
	func renderEndBlockTags(for endBlock: EndBlock, event: WalkerEvent, in context: MarkupContext)
	func renderHorizontalBreak(_ hrBreak: HorizontalBreak, in context: MarkupContext)
}

extension MarkupRenderer {
	
	public func render(in context: MarkupContext) {
		
		parser.ast.walk { (event, node, shouldBreak) in
			let entering = (event == .enter)
			
			switch node {
			case let doc as Document:
				renderDocumentTags(for: doc, event: event, in: context)
				
			case let head as Header:
				renderHeaderTags(for: head, event: event, in: context)
				
				if entering {
					renderText(stringFromNode(head.keyword), in: context)
					renderText(" ", in: context)
					
					if let id = head.identifier {
						let idText = context.nextID(for: head.type) ?? stringFromNode(id)
						renderText(idText, in: context)
					}
					
					if let title = head.title {
						renderText(" ", in: context)
						renderText(stringFromNode(title), in: context)
					}
					
					shouldBreak = true
				}
				
			case let br as HorizontalBreak:
				if entering {
					renderHorizontalBreak(br, in: context)
				}
				
			case let desc as Description:
				// If the block has nothing in it (only whitespace) don't render.
				if desc.isEmpty {
					break
				}
				renderDescriptionTags(for: desc, event: event, in: context)
				
			case let lit as Literal:
				if entering {
					renderLiteralNode(lit, in: context)
				}
				
			case let emp as Emphasis:
				renderEmphasisTags(for: emp, event: event, in: context)
				
				if entering {
					renderLiteralNode(emp, in: context)
				}
				
			case let ref as Reference:
				if entering {
					renderReference(ref, in: context)
				}
				
			case is Comment:
				break
				
			case let cueCon as CueContainer:
				renderCueContainerTags(for: cueCon, event: event, in: context)
				
			case let cueBl as CueBlock:
				renderCueBlockTags(for: cueBl, event: event, in: context)
				
			case let name as Name:
				renderNameTags(for: name, event: event, in: context)
				
				if entering {
					renderLiteralNode(name, in: context)
				}
				
			case let dir as DirectionBlock:
				renderDirectionTags(for: dir, event: event, in: context)
				
			case let lyC as LyricContainer:
				renderLyricContainerTags(for: lyC, event: event, in: context)
				
			case let lyb as LyricBlock:
				renderLyricBlockTags(for: lyb, event: event, in: context)
				
			case let facsc as FacsimileContainer:
				renderFacsimileContainerTags(for: facsc, event: event, in: context)
				
			case let facsb as FacsimileBlock:
				renderFacsimileBlockTags(for: facsb, event: event, in: context)
				
			case let end as EndBlock:
				renderEndBlockTags(for: end, event: event, in: context)
				
				if entering {
					renderLiteralNode(end, in: context)
				}
				
			default:
				print("skipping over \(node)")
			}
		}
		
	}
	
	public func stringFromNode(_ node: Node) -> String {
		let bytes = parser.data[node.range]
		let scalars = UTF16.scalars(from: bytes)
		let scalarView = String.UnicodeScalarView(scalars)
		let string = String(scalarView)
		
		var sanitized = ""
		for char in string.characters {
			switch char {
			case "<":
				sanitized += "&lt;"
			case ">":
				sanitized += "&gt;"
			case "&":
				sanitized += "&amp;"
			case "\"":
				sanitized += "&quot;"
			case "\'":
				sanitized += "&#x27;"
			case "/":
				sanitized += "&#x2F;"
			default:
				
				sanitized.append(char)
			}
		}
		
		return sanitized
	}
	
	public func renderLiteralNode(_ node: Node, in context: MarkupContext) {
		let text = stringFromNode(node)
		renderText(text, in: context)
	}
	
	public func renderText(_ string: String, in context: MarkupContext) {
		context.append(string)
	}
	
}
