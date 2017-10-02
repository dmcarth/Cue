LIBSOURCES=$(addprefix src/,nodes.c Scanner.c inlines.c pool.c mem.c Walker.c cue.c)
OBJFILES=$(LIBSOURCES:src/%.c=build/%.o)

CFLAGS=-Wall -O3

all: library program

build/%.o: src/%.c src/%.h
	mkdir -p build
	$(CC) -c $(CFLAGS) $< -o $@

library: $(OBJFILES)
	mkdir -p build
	ar -rsv build/libcue.a $^
	rm -rf $^

program: library src/main.c
	mkdir -p build
	$(CC) $(CFLAGS) src/main.c build/libcue.a -o build/cue -L build -lcue

clean:
	rm -rf build
