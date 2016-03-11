all:
	iverilog -t vvp alu.v -o alu.o

clean:
	rm alu.o
