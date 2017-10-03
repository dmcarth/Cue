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
| header 0x7fb382800058 {0, 15}
| | keyword 0x7fb3828000b0 {1, 14}
| header 0x7fb382800108 {16, 31}
| | keyword 0x7fb382800160 {16, 21}
| | identifier 0x7fb3828001b8 {22, 23}
| | title 0x7fb382800210 {26, 30}
| | | stream 0x7fb382800268 {26, 30}
| | | | literal 0x7fb3828002c0 {26, 30}
| description 0x7fb382800318 {32, 57}
| | stream 0x7fb382800370 {32, 56}
| | | literal 0x7fb3828003c8 {32, 56}
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
| facsimile 0x7fb3828024d0 {131, 149}
| | line 0x7fb382802528 {131, 138}
| | | stream 0x7fb382802600 {131, 138}
| | | | literal 0x7fb382802658 {131, 138}
| | line 0x7fb3828026b0 {139, 149}
| | | stream 0x7fb382802708 {139, 148}
| | | | literal 0x7fb382802760 {139, 148}
| end 0x7fb3828027b8 {150, 157}
```

Each line starts with the node's type (`document`, `stream`, etc.), followed by its address in memory (`0x7fb382802760`), followed by its source range (`{58, 130}`).

Source ranges become more specific as you move down the tree. Higher level nodes like `facsimile` and `cue` include whitespace and delimiters in their source ranges, while lower level nodes like `literal` and `name` do not. For example, in the above tree the source range for `strong 0x7fb382802160` is `{74, 82}`, which includes the two asterisks at both ends, while its child node `literal 0x7fb3828021b8` excludes those asterisks (`{76, 80}`). `literal` nodes always represent pure, unmarked text and thus will always be leaf nodes.
