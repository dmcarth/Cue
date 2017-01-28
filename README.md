# Cue
Cue is a Markdown-style language for writing stories for print, screen, and stage.

The library presented here for parsing Cue is still in early stages of development. 

## Dependencies
A top priority of the Cue library has been the ability to run without any external dependencies. As a result, anything that can compile Swift can compile the Cue library.

## Installation
I recommend using the Swift Package Mangager to install Cue. 

## Usage
The bread and butter of the Cue library is the Cue class, which accepts a string and provides a number of views onto the parsed data.

```swift
import Cue

let parser = Cue("Hello world!")

let ast = parser.ast 
// An abstract syntax tree

let table = parser.tableOfContents
// An array representing a table of contents

let names = parser.namedEntitiesDictionary
// A dictionary of names and their occurences in the original string
```

### Abstract Syntax Tree
The returned AST comes with a number of powerful methods for traversing and querying.

```swift
ast.enumerate { (node) in
	// Performs a depth-first traversal
}

var current = ast.children.first
while let next = current {
	// Traverses child nodes in sequence
	current = next.next
}

let opts = NodeSearchOptions(deepSearch: true, searchPredicate: { (node) in
	return node is Description
})
if let found = ast.search(index: searchIndex, options: opts) {
	// Finds and returns a node that matches the search query. If none, search returns nil.
}

let nodes = ast.childNodes(from: startOfRange, to: endOfRange)
// Returns all children in the given range
```

All nodes in the AST contain a `startIndex` and an `endIndex`. These properties map to the utf16 indices in the original string where the node's content starts and ends. This is to enable maximum compatibility with NSRange in Foundation and in environments where NSRange is unavailable.

## Syntax
Cue is designed to be intuitive and invisible whenever possible. It should look more or less exactly the same as when it's printed on a book or in a script. 

### Headers
Headers, for example, are marked by their own keywords and an identifier:

```
Act I
Chapter 1
Scene The First
Page 💯
```

You can use all or none of these headers to subdivide a document into smaller parts. 

Note that the identifier can be anything: roman numerals, raw text, emoji, or anything else.

In addition, you can optionally give each header a title by adding a hyphen.

```
Chapter I - An Unexpected Party
```

### Description
Unmarked text is treated as ordinary description and can contain any variety of plain text.

```
Jack went to the store to buy some milk, but he came home with a Jack Russell Terrier instead.
```

Or, if you prefer a more traditional screenplay-style of prose:

```
The door opens to reveal Jack, both arms wrapped around a nervous Jack Russell Terrier. There is no milk to be seen.
```

It also inherits a similar inline syntax to Markdown.

```
Emphasis is marked by *asterisks*.
Links to images and other embeddable files are wrapped in [brackets].
```

### Cues
The real power of Cue, however, comes from the way it treats dialogue. On a fundamental level, dialogue is just scene description targeted at one person. This targeted direction is called a cue.

```
Jack: This part of the document is meant specifically for me.
```

Other cues can be targeted at other people and departments. Indeed, any part of the mise-en-scene can have a cue if it suits the writer and production team.

```
Audio FX: This is a cue for the audio department.
Cut to:
```

The last line is an example of a self-describing cue. It doesn't need any further description because the cue name *is* the description.

Cues that are meant to overlap with each other can be marked with a caret.

```
Jack: This is a line of dialogue.
^Jill: This is a line meant to be spoken at the same time.
```

### Lyrics
Lines that are meant to be sung are marked with a tilde.

```
Jack: ~This is a song
      ~That extends multiple lines
      ~And in theory could go on forever...
```

### Facsimiles
The begining of a letter (or email, or sign, *et al.*) is marked with a right angle bracket.

```
> Dear Mr. Potter,
> You are out of eggs.
> Love,
> The Dursleys
```

### Whitespace
Note that whitespace in Cue is generally ignored, allowing you to align lyrics and cues however you please.

```
	Scene 2
       Jack:	~This is
				~a stanza of music
Christopher:	~Aligned by the begining
				~Of each lyric line
	   Jill:	~And by the end
				~Of each cue name
```

The only exception is for newlines. Unlike Markdown, Cue counts every single line

```
This is line #1

This is line #3 because it comes two lines after line #1.
```

### Comments
You can also write comments.

```
// Lines beginning with two or more slashes are considered comments.
```

All comments are block elements, meaning that they take over the entire line they're on. If a line does not begin with `//` it can not be a comment.

### Ending
Every great work deserves closure. When you've reached the end of your story simply put:

```
The End
```
