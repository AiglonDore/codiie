ifeq ($(RELEASE), TRUE)
	CC=ocamlopt
	TARGET=bin/codiie.native
else
	CC=ocamlc
	TARGET=bin/codiie.byte
endif

all : $(TARGET)

$(TARGET) : src/squelette.ml
	$(CC) -o $(TARGET) src/squelette.ml
	make clean

clean :
	rm -vf src/*.cmi src/*.cmo src/*.cmx src/*.o

purge : 
	make clean
	rm -vf bin/*.byte bin/*.native