all:
	make -f ../pico-ceu/Makefile SRC=main

xxx:
	make -f ../pico-ceu/Makefile SRC=xxx

c:
	gcc -g out.c -lm -lSDL2 -lSDL2_image -lSDL2_ttf -include ../pico-sdl/src/hash.c -include ../pico-sdl/src/pico.c
