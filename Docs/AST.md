# Abstract Syntax Tree
To walk the tree depth-first you use a `Walker` object.

```c
Walker *w = walker_new(node);
WalkerEvent event;

while ((event = walker_next(w)) != EVENT_DONE) {
	ASTNode *current = walker_get_current_node(w);

	// do something with `current`
}

free(w);
```

To examine the contents of an AST visually you can print a node to the console.

```c
ast_node_print_description(node, 1) // 0 to print just `node`, 1 to recurse
```

That gives us something like this:

```
document 0x7fb382800000 {0, 157}
...
| simultaneous cues 0x7f8c3f0005a0 {58, 72}
| | cue 0x7f8c3f000480 {58, 36}
| | | name 0x7f8c3f0004e0 {58, 5}
| | | plain direction 0x7f8c3f000540 {65, 28}
| | | | stream 0x7f8c3f000600 {65, 28}
| | | | | parenthetical 0x7f8c3f000660 {65, 6}
| | | | | | literal 0x7f8c3f0006c0 {66, 4}
| | | | | literal 0x7f8c3f000720 {71, 3}
| | | | | strong 0x7f8c3f000780 {74, 8}
| | | | | | literal 0x7f8c3f0007e0 {76, 4}
| | | | | literal 0x7f8c3f000840 {82, 11}
| | cue 0x7f8c3f0008a0 {94, 36}
| | | name 0x7f8c3f000900 {95, 8}
| | | plain direction 0x7f8c3f000960 {105, 24}
| | | | stream 0x7f8c3f0009c0 {105, 24}
| | | | | literal 0x7f8c3f000a20 {105, 13}
| | | | | comment 0x7f8c3f000a80 {118, 11}
| | | | | | literal 0x7f8c3f000ae0 {119, 10}
...
| end 0x7fb3828027b8 {150, 7}
```

Each line starts with the node's type (`document`, `stream`, etc.), followed by its address in memory (`0x7f8c3f0004e0`), followed by its source range (`{58, 5}`).

Source ranges become more specific as you move down the tree. Higher level nodes like `facsimile` and `cue` include whitespace and delimiters in their source ranges, while lower level nodes like `literal` and `name` do not. For example, in the above tree the source range for `strong 0x7fb382802160` is `{74, 8}`, which includes the two asterisks at both ends, while its child node `literal 0x7fb3828021b8` excludes those asterisks (`{76, 4}`).

## Headers
If a node is a header (`ast_node_is_type(node, S_NODE_HEADER`), you can access its header data through the `as` union.

```
HeaderType type = node->as.header->type;
ASTNode *keyword = node->as.header->keyword;
ASTNode *id = node->as.header->id;		// may be NULL
ASTNode *title = node->as.header->title;	// may be NULL
```

## Cues
The `as` union also stores cue data when the node is a cue (`ast_node_is_type(node, S_NODE_CUE`).

```
int isDual = node->as.cue.isDual;
ASTNode *name = node->as.cue->name;
ASTNode *direction = node->as.cue->direction;
```

There are two different kinds of direction nodes, `S_NODE_PLAIN_DIRECTION` and `S_NODE_LYRIC_DIRECTION`, that might be stored in `as.cue->direction`. These reflect the two different kinds of possible cues.

Plain direction holds an `S_NODE_STREAM` of inline nodes. Lyric direction holds a sequence of `S_NODE_LINE`s.
