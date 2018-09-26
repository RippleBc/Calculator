OBJS = main.o  \
			 driver.o  \
       parser.tab.o    \
       lex.yy.o \

main: $(OBJS)
	g++ -o main $(OBJS)

main.o: driver.hh main.cc
	g++ -c main.cc

driver.o: parser.tab.hh driver.hh driver.cc
	g++ -c driver.cc

parser.tab.o: driver.hh stack.hh position.hh location.hh parser.tab.hh parser.tab.cc
	g++ -c parser.tab.cc

lex.yy.o: driver.hh parser.tab.hh lex.yy.c
	g++ -c lex.yy.c

parser: parser.yy
	bison parser.yy

lexer: lex.ll
	flex lex.ll

clean:
	-rm -f main $(OBJS)

test:
	./main -p -s 'test.txt'