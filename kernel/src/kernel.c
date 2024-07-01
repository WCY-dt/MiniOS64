#define VGA_BASE  0xb8000
#define VGA_LIMIT 80 * 25

#define STYLE_WHITE_ON_BLACK 0x0f
#define STYLE_WHITE_ON_BLUE  0x1f

typedef struct __attribute__((packed)) {
    char character;
    char color;
} vga_char;

volatile vga_char *TEXT_AREA = (vga_char *)VGA_BASE;

void print_clear() {
    vga_char clear_char = {
        .character = 'x',
        .color = STYLE_WHITE_ON_BLACK,
    };

    for (unsigned int i = 0; i < VGA_LIMIT; i++) {
        TEXT_AREA[i] = clear_char;
    }
}

void print_string(const char *str) {
    for (unsigned int i = 0; str[i] != '\0'; i++) {
        if (i >= VGA_LIMIT) {
            break;
        }

        vga_char tmp = {
            .character = str[i],
            .color = STYLE_WHITE_ON_BLUE,
        };

        TEXT_AREA[i] = tmp;
    }
}

void main() {
    print_clear();

    const char *hello_world_msg = "Hello, Kernel!";
    print_string(hello_world_msg);
}