# Cue
Cue is a Markdown-style language for writing stories, whether they be for print, screen, or stage. 

It is still in development and therefore not suitable for production just yet.

##Example
Cue is designed to be intuitive and invisible whenever possible. It should look more or less the same as when it's printed! For example, headers are marked like so:

```
Chapter 1
Scene The First
Act I
```

... where "Chapter", "Scene", and "Act" all form keywords for the header name.

It also inherits a similar inline syntax to Markdown.

```
Emphasis is marked by *asterisks*.
Images and other embeddable links are wrapped in [brackets].
```

But the real power of Cue comes from the way it treats dialogue and scene description. Rather then separating the two, Cue treats them as the same kind of scene description: a (guess where the name of this came from) cue. Dialogue is just a cue targeted at one person. Likewise, other special cues can be targeted at other parts of the mise-en-scene.

```
Jack: This is a line of dialogue.
Audio FX: This is a cue for the audio department.
Cut to:
```
The last example is a self-describing cue. It doesn't need any description because the cue name *is* the description.

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

Note that whitespace in cue is ignored, allowing you to align lyrics and cues however you want. The only whitespace that matters in cue is a linebreak.

```
This is line #1

This is line #3
```

You can also write comments.

```
// Lines beginning with two or more slashes are considered comments.
```
