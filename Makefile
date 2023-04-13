ifeq ($(RELEASE), TRUE)
	CC=ocamlopt
	TARGET=bin/codiie.native
else
	CC=ocamlc
	TARGET=bin/codiie.byte
fi

all : $(TARGET)

$(TARGET) : 
	$(CC) -o $(TARGET) 