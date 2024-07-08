#define VGA_BASE 0xb8000
#define VGA_SIZE (80 * 25)

void print_str(const char* str) {
    char* vga = (char*)0xb8000;
    while (*str) {
        *vga = *str;
        str++;
        vga++;
        *vga = 0x07;
        vga++;
    }
}

void clear_screen() {
    char* vga = (char*)0xb8000;
    for (int i = 0; i < VGA_SIZE; i++) {
        *vga = 0;
        vga++;
        *vga = 0x07;
        vga++;
    }
}

int main() {
    clear_screen();
    print_str("Hello, Kernel!\n");
    return 0;
}