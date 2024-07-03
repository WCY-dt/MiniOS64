#include "vga.h"
#include "util.h"

int main() {
    vga_clear();

    /* Fill up the screen */
    for (int i = 0; i <= VGA_MAX_ROW; i++) {
        char str[12];
        int_to_ascii(i, str);
        vga_print_at(str, i, 0);
    }

    vga_print("Hello, ");
    vga_print("World!");
    return 0;
}