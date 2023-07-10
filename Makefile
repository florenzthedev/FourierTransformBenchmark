CC = gcc
CFLAGS = -Wall -D_XOPEN_SOURCE=600 -fcx-limited-range $(EXTRA_CFLAGS)
EXEC = loader

$(EXEC): loader.c
	$(CC) -o $@ $< $(CFLAGS)

clean:
	rm $(EXEC) *.table