CC = gcc
CFLAGS = -Wall -D_XOPEN_SOURCE=600 -fcx-limited-range $(EXTRA_CFLAGS)
LIBS = -lm -ldl
EXEC = loader

$(EXEC): loader.c
	$(CC) -o $@ $< $(CFLAGS) $(LIBS)

clean:
	rm -f $(EXEC) *.table