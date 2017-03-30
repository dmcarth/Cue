# Rendering
Cue uses its own internal HTML renderer to output HTML, but it also defines two public protocols for rendering Cue: `Renderer` and `MarkupRenderer`. Between these two protocols you should be able to render Cue into just about any format imaginable. The details behind using and implementing these two protocols are wildly different, however, and really deserve their own sections.

## Markup Rendering
`MarkupRenderer` is ideally suited for rendering to other plain text markup languages like XML, LaTeX, or HTML. It renders onto a `MarkupContext` which you must initialize yourself before passing it into `render(in:)`. 

```swift
var output: String {
    let context = MarkupContext()
    render(in: context)
    return context.string
}
```

`MarkupContext` is designed to create beautiful, well formed markup. To render onto this context, you pass a string into `context.append(_:)`. That string can be obtained by calling `stringFromNode(_:)`, which does some automatic HTML/XML sanitization. 

```swift
let text = stringFromNode(node)
context.append(text)
```

You should never add newlines with `context.append(_:)`. Instead, call `context.setNeedsNewLine()`. This will ensure that the next append operation will automatically be placed on a new line in the render output with proper indenting. 

Managing indentation is as easy as calling `context.pushIndent()` and `context.popIndent`. Each newline will automatically get the proper indentation set by those two methods. For an example, here is how `HTMLMarkupRenderer` renders  indented block tags.

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

The result looks like this:

```html
<div class="document">
    <h2>
        Chapter 1
    </h2>
    <div class="cueContainer">
        <div class="cue">
            <div class="name">
                John
            </div>
            <div class="direction">
                Hello.
            </div>
        </div>
    </div>
</div>
```

Most of the required methods for `MarkupRender` follow the same format: they pass a node and a `WalkerEvent` to indicate whether the renderer is entering or exiting the given node. The only exceptions are `renderReference(_:in:)` and `renderHorizontalBreak(_:in:)`, which are only called when entering.

For a full list of the requirements see MarkupRenderer.swift. 

## General Purpose Rendering
The `Renderer` protocol requires a little more work up front, but in exchange you gain much greater flexibility. Unlike `MarkupRenderer`, you are responsible for defining the context type of your renderer, enabling you to output the results of the Cue parser in far more than just plain text. A syntax highlighter would use this protocol.

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

`Renderer` provides two methods for initiating a render: `render(in:)` for rendering a complete document and `render(range:,in:)` for a partial render. Because `Renderer` supports iterative rendering, it is *essential* that your context type encapsulate *all* necessary statefulness.

The number of required methods is less than in `MarkupRender`, placing more responsibility on the renderer to handle layout and drawing. That includes calling `renderInlines(_:in:)` and determining whether a line of description is empty or not.

By convention, Cue ignores all whitespace. However, in order to facilitate syntax highlighting Cue still keeps empty description nodes in its tree. To check if a `Description` node is empty, and therefore if it needs to be rendered, check if `node.isEmpty` returns true.

Like `MarkupRenderer`, `Renderer` comes with a method for obtaining unmarked text from a given node for rendering: `stringFromNode(_:)`. Unlike `MarkupRenderer`, this method doesn't do any sanitizing.

For a full list of required methods, see Renderer.swift.