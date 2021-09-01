# MIPS Compiler
MIPS machine-code compiler that uses the C language, Flex, and Bison lexical analyzers.

## Required Packages

Use the package manager to install Flex, Bison, and GCC.

```bash
sudo apt install Flex
sudo apt install Bison
sudo apt install GCC
```

## Usage (Using Make)
In the file directory, make
```
make
```
To compile with input code
```
./final -o HelloWorld < inputFile
```
