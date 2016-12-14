# Cue
Cue is a Markdown-style language for writing stories for print, screen, and stage. 

It is still in development and therefore not suitable for production just yet.

## Syntax
Cue is designed to be intuitive and invisible whenever possible. It should look more or less exactly the same as when it's printed on a book or in a script. 

### Headers
Headers, for example, are marked by their own keywords and an identifier:

```
Act I
Chapter 1
Scene The First
```

The identifier can be anything: roman numerals, raw text, emoji, you pick. For this reason, Cue does not currently enforce the uniqueness of each identifier.

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
The real power of Cue, however, comes from the way it treats dialogue. On a fundamental level, dialogue is just scene description targeted at one person. Other cues can be targeted at other people and departments -- any part of the mise-en-scene can have a cue if it suits the writer and production team.

```
Jack: This is a line of dialogue.
Audio FX: This is a cue for the audio department.
Cut to:
```

The last line is an example of a self-describing cue. It doesn't need any further description because the cue name *is* the description.

Cues that are meant to overlap with each other can be marked with a caret.

```
Jack: This is a line of dialogue.
^Jill: This is a line meant to be spoken at the same time as Jack.
```

And cues that contain music/lyrics can be marked with a tilde

```
Jack: ~This is a song
      ~That extends multiple lines
      ~And in theory could go on forever...
```

### Whitespace
Note that whitespace in Cue is generally ignored, allowing you to align lyrics and cues however you please.

```
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
