#CFLAGS = -DCEU_RUNTESTS -DCEU_DEBUG #-DSIMUL #-DCEU_DEBUG_TRAILS

all:
	ceu --cpp-args "-I . $(CFLAGS)" main.ceu
	gcc -g -Os main.c $(CFLAGS) -lSDL2 -lSDL2_image -lSDL2_mixer -lSDL2_ttf -lSDL2_net -lSDL2_gfx -lpthread -lm \
		-o rocks.exe

clean:
	find . -name "*.exe"  | xargs rm -f
	find . -name "_ceu_*" | xargs rm -f

.PHONY: all clean
