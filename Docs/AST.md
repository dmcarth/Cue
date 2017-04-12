# Abstract Syntax Tree
The AST returned by `Cue` comes with a number of powerful methods for traversing and querying.

```swift
ast.enumerate { (node) in
    // Performs a depth-first traversal. Does not support transformation.
}

ast.walk { (event, node, shouldBreak) in
    // Performs a depth-first traversal. Supports tree transformation.
}

let opts = SearchOptions(deepSearch: true, searchPredicate: { (node) in
    return node is Description
})
if let found = ast.search(for: searchIndex, options: opts) {
    // Finds and returns a node that matches the search query. If none, search returns nil.
}

let nodes = ast.childNodes(from: startOfRange, to: endOfRange)
// Returns all children in the given range
```

All nodes in the AST contain a `range` property where the `lowerBound` and `upperBound` correspond to the utf16 byte index where the node's content starts and ends. An additional `rangeIncludingMarkers` property extends `range` to include any delimiters and extra whitespace.