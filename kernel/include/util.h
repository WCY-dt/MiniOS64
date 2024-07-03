#ifndef UTIL_H
#define UTIL_H

#include <stdint.h>

#define CAST_TO_CHAR_PTR(x) ((char*)(uintptr_t)(x))

void memory_copy(char* source, char* dest, int no_bytes);
void memory_set(char* dest, char val, int no_bytes);
void int_to_ascii(int n, char str[]);
void ascii_to_int(char str[], int* n);

#endif