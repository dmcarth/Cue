There are two kinds of nodes in the current AST design: nodes where children.count is a static quantity, and nodes where children.count is a variable quantity. Implementing this in code turns out to be rather complicated. In the future, we could accomplish this by conforming each node type to a recursively constrained protocol like this:

protocol Traversable {
	associatedtype ChildType: Traversable
	var children: [ChildType] { get }
}

Doing so would remove the need for AbstractNode, since the algorithms that AbstractNode provides to its concrete subclasses could easily be moved to an extension.

extension Traversable {
	func enumerate(_ handler: (Traversable)->Void) {}
	func search(index: Index, options: SearchOptions) -> Traversable? {}
}

Unfortunately, Swift does not currently support recursively constrained protocols (though it is on the roadmap), and using this kind of a protocol would introduce the need for existentials -- adding even further to the complication. It is presented here only as a path to consider in the future.

