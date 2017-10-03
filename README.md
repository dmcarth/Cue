# Cue
Cue is a Markdown-style language for writing stories for print, screen, and stage.

While the Cue spec continues to develop, the API will also continue to undergo changes. Until the Cue spec reaches 1.0, it should be considered unstable.

## Dependencies
Every attempt has been made to remove the need for external dependencies. As a result, anything that can compile ANSI C can compile Cue.

## Installation
Cue uses make as its build system. To compile, run `make all` .

Cue has only been tested with clang and may not work immediately well with other compilers.

## Syntax
Cue is designed to be intuitive and invisible whenever possible. It should look more or less exactly the same as when it's printed on a book or in a script. 

### Headers
Headers are marked by one of these four keywords followed by some identifier:

```
Act I
Chapter 1
Scene The First
Page 💯
```

For headers that use a non-standard keyword (or that don't have an identifier), you can force a header by inserting a period at the beginning of the line.

```
.Prologue
```

Optionally, you can give each header a title by adding a hyphen.

```
Chapter I - An Unexpected Party
```

### Description
Unmarked text is treated as ordinary scene description.

```
The door opens to reveal Jack, both arms wrapped around a nervous Jack Russell Terrier. There is no milk to be seen.
```

It inherits a similar inline syntax to Markdown.

```
Emphasis is marked by *asterisks*.
Bold is marked by **double asterisks**.
Links to images and other embeddable files are wrapped in [brackets].
```

### Cues
Dialogue is marked by the character's name, a colon, and then their line.

```
Jack: Whatever's written here is meant specifically for me.
```

Fundamentally, dialogue is just scene description targeted at a single person. This is called a cue. Other cues can be targeted at other people and departments. Indeed, any part of the mise-en-scene can have a cue if it suits the writer and production team.

```
Audio FX: This is a cue for the audio department.
```

Cues that are meant to overlap with each other can be marked with a caret.

```
Jack: This is a line of dialogue.
^Jill: This is a line meant to be spoken at the same time.
```

### Parentheticals
Notes like `O.S`, `beat`, *et al.* are wrapped in parenthesis.

```
Jill: (O.S) I deeply regret tumbling after you.
```

### Lyrics
Cues that are meant to be sung are marked with a tilde.

```
Jack: ~This is a song
      ~That extends multiple lines
      ~And in theory could go on forever...
```

### Facsimiles
The begining of a letter (or sign, *et al.*) is marked with a right angle bracket.

```
> Dear Mr. Potter,
> You are out of eggs.
> Love,
> The Dursleys
```

### Whitespace
Whitespace in Cue is always ignored, allowing you to align lyrics and cues however you please.

```
       Jack:    ~This is
                ~a stanza of music
Christopher:    ~Aligned by the begining
                ~Of each lyric line
       Jill:    ~And by the end
                ~Of each cue name
```

Line spacing is also simply a matter of taste. 

```
This is line #1.

This is line #2.
This is line #3.
```

### Thematic Break
A line of three or more hyphens becomes a break.

```
It was the last she ever saw of him.
---
Five years later, Buttercup was betrothed to a prince...
```

### Comments
Comments can be extremely useful for sharing notes with yourself and your collaborators. You can add a comment to the end of a line using //.

```
It was the best of times, it was the worst of times.    // consider revising
```

### Ending
Every great work deserves closure. When you've reached the end of your story simply put:

```
The End
```
