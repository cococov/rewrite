
# REWRITE

Rewrite is a little programming language, written years ago at the college as final project for the 'programming languajes' subject.

# Example code

```
REWRITE_START
	REWRITE_STRING str
{
	str = "Hello World !"
	printString(str)
} REWRITE_END
```

# Compile the compiler

```sh
bison -d rewrite.y && flex rewrite.l
```
```sh
gcc rewrite.tab.c lex.yy.c symtab.c node.c gencode.c -o Rewrite
```

# Compile a Rewrite code

```sh
./Rewrite [path] [program name] && java -jar jasmin.jar [program name].j
```
example:
```sh
./Rewrite examples/programa.rwrt programa && java -jar jasmin.jar programa.j
```

# Run a Rewrite program

```sh
java [program name]
```
example:
```sh
java programa
```

