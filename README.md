# Cue
Cue is a Markdown-style language for writing stories for print, screen, and stage. 

It is still in development and therefore not suitable for production just yet.

##Example
Cue is designed to be intuitive and invisible whenever possible. It should look more or less exactly the same as when it's printed. Headers, for example, are marked by their own keywords:

```
Act I
Chapter 1
Scene The First
```

Unmarked text is treated like ordinary description and can contain any variety of plain text.

```
Jack went to the store to buy some milk, but he came home with a Jack Russell Terrier instead.

// OR, if you prefer a more traditional screenplay-style of prose

The door opens to reveal Jack, both arms wrapped around a nervous Jack Russell Terrier. There is no milk to be seen.
```

It also inherits a similar inline syntax to Markdown.

```
Emphasis is marked by *asterisks*.
Images and other embeddable links are wrapped in [brackets].
```

The real power of Cue, however, comes from the way it treats dialogue and scene description. Both are treated as the same kind of thing: a cue. Dialogue is just a cue targeted at one person. Other cues can be targeted at other parts of the mise-en-scene.

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

Note that whitespace in Cue is ignored, allowing you to align lyrics and cues however you want, except when it comes to newlines.

```
This is line #1

This is line #3, because it comes two lines after line #1.
```

You can also write comments.

```
// Lines beginning with two or more slashes are considered comments.
```
