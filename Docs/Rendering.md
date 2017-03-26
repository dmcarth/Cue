# Rendering
Cue uses its own internal HTML renderer to output HTML, but it also defines two public protocols for rendering Cue: `Renderer` and `MarkupRenderer`. Between these two protocols you should be able to render Cue into just about any format imaginable. The details behind using and implementing these two protocols are wildly different, however, and really deserve their own sections.

## Markup Rendering
`MarkupRenderer` is ideally suited for rendering other plain text markup languages like XML, LaTeX, or HTML. It renders onto a `MarkupContext` which you must initialize yourself before calling `render(in:)`. This context will then be passed through each of the rendering callbacks. When rendering is completed, you can retrieve the results of the render from `context.string` property.

`MarkupContext` is a specialized class designed to create beautiful, well formed markup. To render onto this context, you call `context.append(_:)`. To get the literal string content of an AST node (excluding markup), call `stringFromNode(_:)` from the renderer. 

You should never add "\n" to `context.append(_:)`. Instead, call `context.setNeedsNewLine()`. This will ensure that the next append operation will automatically be placed on a new line in the render output. 

To manage the indent of each line, you can call `context.pushIndent()` and `context.popIndent`.  For an example, here is how `HTMLMarkupRenderer` renders properly indented block tags.

```swift
func renderTag(_ tag: String, class name: String?, event: WalkerEvent, context: MarkupContext) {
    if event == .enter {
        let classAttr = (name != nil) ? " class=\"\(name!)\"" : ""
        
        context.append("<\(tag)\(classAttr)>")
        context.setNeedsNewLine()
        context.pushIndent()
    } else {
        context.setNeedsNewLine()
        context.popIndent()
        context.append("</\(tag)>")
        context.setNeedsNewLine()
    }
}
```

## General Purpose Rendering
The `Renderer` protocol requires a little more work upfront, but in exchange you gain much greater flexibility. Unlike `MarkupRenderer`, you are responsible for defining the context type of your renderer, enabling you to output the results of the Cue parser in far more than just plain text. A syntax highlighter would use this protocol.

```swift
struct CGRenderer: Renderer {
    typealias Context = CGContext
    // ...
}

struct NSAttributedStringRenderer: Renderer {
    typealias Context = NSAttributedString
    // ...
}
```

`Renderer` provides two render methods: `render(in:)` and `render(range:,in:)`. Because `Renderer` supports iterative rendering, it is *essential* that your context type encapsulate *all* necessary statefulness.

The number of required methods is noticeably less than in `MarkupRender`, placing more responsibility on the renderer to handle layout and drawing.