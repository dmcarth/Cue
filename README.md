# Cue
Cue is a Markdown-style language for writing stories for print, screen, and stage.

While the Cue spec continues to develop, the API will also continue to undergo changes. Until the Cue spec reaches 1.0, it should be considered unstable.

## Dependencies
Cue is designed to be portable and lightweight. Every attempt has been made to remove the need for external dependencies. It's even written in ANSI C for that very purpose!

## Usage
This repo contains a static library, `libcue`, and a command line utility, `cue`. To compile both, run `make all`. To compile one or the other run `make library` or `make program`.

Cue has only been tested with clang and may not work immediately with other compilers. If it doesn't work with yours, pull requests are greatly appreciated.

## Syntax
Cue is designed to be intuitive and invisible whenever possible. It should look more or less exactly the same as when it's printed on a book or in a script. 

### Headers
It can be useful to organize your script into sections and Cue let's you do this with headers. Headers begin with one of these four keywords: `Act`, `Scene`, `Page`, and `Frame`.

`Frame` is the equivalent of `CUT TO:` in a screenplay. It marks the beginning of a new camera angle. This gives you, the writer, as much granularity as you need to organize your ideas in a script.

In addition, headers can have an optional identifier. For example:

```
Act I
Scene 1
Page The First
Frame 💯
```

In practice, however, you should omit the identifiers and let Cue keep track of your headers for you.

You can force a header by inserting a period at the beginning of the line.

```
.Prologue
```

You can also give each header a short description by adding a hyphen.

```
Scene - Interior of a spooky cave 👻
```

### Scene Description
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
Dialogue is marked by the character's name, a colon, and their dialogue.

```
Jack: Whatever's written here is meant specifically for me.
```

Fundamentally, dialogue is just direction targeted at a single person. This is called a cue. Other cues can be targeted at other people and parts of the mise-en-scene. Indeed, any part of the mise-en-scene can have a cue if it suits the writer and production team.

```
Audio FX: This is a cue for the audio department.
```

Cues that are meant to overlap with each other can be marked with a caret.

```
Jack: This is a line of dialogue.
^Jill: This is a line meant to be spoken at the same time.
```

### Parentheticals
Notes for actors like `O.S.`, `beat`, and `V.O.` are wrapped in parenthesis.

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
Comments can be extremely useful for sharing notes with yourself and your collaborators. You can add a comment to the end of a line using `//`.

```
It was the best of times, it was the worst of times.    // consider revising
```

### Ending
Every great work deserves closure. When you've reached the end of your story simply put:

```
The End
```
