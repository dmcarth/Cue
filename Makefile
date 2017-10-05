SRCDIR=src
BUILDDIR=build
LIBSOURCES=$(addprefix $(SRCDIR)/,nodes.c Scanner.c inlines.c pool.c mem.c StringBuffer.c Walker.c cue.c)
OBJFILES=$(LIBSOURCES:$(SRCDIR)/%.c=$(BUILDDIR)/%.o)

CFLAGS=-Wall -O3

all: program

$(SRCDIR)/%.c: $(SRCDIR)/%.h

$(BUILDDIR)/%.o: $(SRCDIR)/%.c 
	mkdir -p $(BUILDDIR)
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILDDIR)/libcue.a: $(OBJFILES)
	mkdir -p $(BUILDDIR)
	ar -rsv $(BUILDDIR)/libcue.a $^

program: $(BUILDDIR)/libcue.a $(SRCDIR)/main.c
	mkdir -p $(BUILDDIR)
	$(CC) $(CFLAGS) $(SRCDIR)/main.c $(BUILDDIR)/libcue.a -o $(BUILDDIR)/cue -L $(BUILDDIR) -lcue

bench: program
	./$(BUILDDIR)/cue bench/war+peace.txt --bench 500

clean:
	rm -rf $(BUILDDIR)
