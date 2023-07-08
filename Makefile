CC = gcc
CFLAGS = -Wall -D_XOPEN_SOURCE=600
EXEC = loader

$(EXEC): loader.c
	$(CC) -o $@ $< $(CFLAGS)

clean:
	rm $(EXEC)