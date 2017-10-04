# Cue
Cue is a Markdown-style language for writing stories for print, screen, and stage.

While the Cue spec continues to develop, the API will also continue to undergo changes. Until the Cue spec reaches 1.0, it should be considered unstable.

## Dependencies
Cue is designed to be portable and lightweight. Every attempt has been made to remove the need for external dependencies. It's even written in ANSI C for that very purpose!

## Usage
This repo contains a static library, `libcue`, and a command line utility, `cue`. To compile both, run `make all`. To compile one or the other run `make library` or `make program`.

Cue has only been tested with clang and may not work immediately with other compilers. If it doesn't work with yours, pull requests are greatly appreciated.

## Syntax
Cue is designed to be intuitive and invisible whenever possible. It should look more or less exactly the same as when it's printed as a final script.

### Scene Header
Each scene begins with a scene header.

```
Scene 1 - A spooky cave. 👻
```

You can omit the number if your wish, or you can use other text instead.

```
Scene - In front of a vast mansion.

Scene Twenty - Interior of a car.
```

In practice, you should omit the identifiers and let Cue keep track of your headers for you. Your job is to write, not count your scenes.

You can also omit the location if you'd rather describe it elsewhere.

```
Scene

A description of the new scene...
```

### Others Headers
It can be quite useful to organize your script into more sections then just scenes, and Cue let's you do this with headers. Headers begin with one of these four keywords: `Act`, `Scene`, `Page`, or `Frame`.

`Frame` is the equivalent of `CUT TO:` in a screenplay. It marks the beginning of a new camera angle. Likewise, `Page` marks the beginning of a new page in, say, a graphic novel. This gives you, the writer, as much granularity as you need to organize your ideas in a script.

These other headers all follow the same rules as scene headers.

```
Act I
Scene - An underwater grotto.
Page
Frame 💯 - MCU on glass of milk.
```

You can force a header by inserting a period at the beginning of the line.

```
.Prologue
```

Forced headers do not support identifiers, but you can still add location description with a hyphen.

```
.Post credits scene - A thai food restaraunt.
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
Jack: I'd really like to go up that hill and fill this pail with water.
```

Cue treats dialogue differently from other script formats. Fundamentally, dialogue is just direction targeted at a single person. This is called a cue. Other cues can be targeted at other people and parts of the mise-en-scene. Indeed, any part of the mise-en-scene can have a cue if it suits the writer and production team.

```
Audio FX: This is a cue for the audio department.
```

Cues that are meant to overlap can be marked with a caret.

```
Jack: This is a line of dialogue.
^Jill: This is a line meant to be spoken at the same time.
```

Parentheticals like `O.S.`, `beat`, and `V.O.` are wrapped inline in parenthesis.

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
       Jack:    ~This is a stanza
                ~of music
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
