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
| simultaneous cues 0x7fb382800528 {58, 130}
| | cue 0x7fb382800420 {58, 94}
| | | name 0x7fb382800478 {58, 63}
| | | plain direction 0x7fb3828004d0 {65, 93}
| | | | stream 0x7fb382802000 {65, 93}
| | | | | parenthetical 0x7fb382802058 {65, 71}
| | | | | | literal 0x7fb3828020b0 {66, 70}
| | | | | literal 0x7fb382802108 {71, 74}
| | | | | strong 0x7fb382802160 {74, 82}
| | | | | | literal 0x7fb3828021b8 {76, 80}
| | | | | literal 0x7fb382802210 {82, 93}
| | cue 0x7fb382802268 {94, 130}
| | | name 0x7fb3828022c0 {95, 103}
| | | plain direction 0x7fb382802318 {105, 129}
| | | | stream 0x7fb382802370 {105, 129}
| | | | | literal 0x7fb3828023c8 {105, 118}
| | | | | comment 0x7fb382802420 {118, 129}
| | | | | | literal 0x7fb382802478 {119, 129}
...
| end 0x7fb3828027b8 {150, 157}
```

Each line starts with the node's type (`document`, `stream`, etc.), followed by its address in memory (`0x7fb382802760`), followed by its source range (`{58, 130}`).

Source ranges become more specific as you move down the tree. Higher level nodes like `facsimile` and `cue` include whitespace and delimiters in their source ranges, while lower level nodes like `literal` and `name` do not. For example, in the above tree the source range for `strong 0x7fb382802160` is `{74, 82}`, which includes the two asterisks at both ends, while its child node `literal 0x7fb3828021b8` excludes those asterisks (`{76, 80}`).

## Headers
If a node is a header (`ast_node_is_type(node, S_NODE_HEADER`), you can access its header-specific information through the `as` union.

```
HeaderType type = node->as.header->type;
ASTNode *keyword = node->as.header->keyword;
ASTNode *id = node->as.header->id;		// may be NULL
ASTNode *title = node->as.header->title;	// may be NULL
```

## Cues
The `as` union also stores cue-specific information when the node is a cue (`ast_node_is_type(node, S_NODE_CUE`).

```
int isDual = node->as.cue.isDual;
ASTNode *name = node->as.cue->name;
ASTNode *direction = node->as.cue->direction;
```

There are two different kinds of direction nodes, `S_NODE_PLAIN_DIRECTION` and `S_NODE_LYRIC_DIRECTION`, that might be stored in `as.cue->direction`. Plain direction holds an `S_NODE_STREAM` of inline nodes. Lyric direction holds a sequence of `S_NODE_LINE`s.
