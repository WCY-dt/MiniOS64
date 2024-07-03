#include "util.h"

void reverse_str(char str[], int length);

void memory_copy(char* source, char* dest, int no_bytes) {
    for (int i = 0; i < no_bytes; i++) {
        *(dest + i) = *(source + i);
    }
}

void memory_set(char* dest, char val, int no_bytes) {
    for (int i = 0; i < no_bytes; i++) {
        *(dest + i) = val;
    }
}

void int_to_ascii(int n, char str[]) {
    // int 范围为 -2147483648 到 2147483647
    const int MAX_INT_LENGTH = 12;

    char temp[MAX_INT_LENGTH];

    int isNegative;

    if (n < 0) {
        isNegative = 1;
        n = -n;
    }

    int no_digits = 0;
    while (n != 0) {
        int remainder = n % 10;
        temp[no_digits++] = remainder + '0';
        n /= 10;
    }

    if (isNegative) {
        temp[no_digits++] = '-';
    }
    
    memory_set(str, '\0', no_digits);
    for (int i = 0; i < no_digits; i++) {
        str[i] = temp[no_digits - i - 1];
    }
}

void ascii_to_int(char str[], int* n) {
    *n = 0;
    int sign = 1;

    if (str[0] == '-') {
        sign = -1;
    }

    int i = 0;
    if (str[0] == '-') {
        i = 1;
    }

    while (str[i] != '\0') {
        *n = *n * 10 + str[i] - '0';
        i++;
    }

    *n *= sign;
}

void reverse_str(char str[], int length) {
    int start = 0;
    int end = length - 1;
    while (start < end) {
        // Swap characters
        char temp = str[start];
        str[start] = str[end];
        str[end] = temp;
        start++;
        end--;
    }
}