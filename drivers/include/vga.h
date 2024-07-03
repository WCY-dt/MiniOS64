#ifndef VGA_H
#define VGA_H

#define VGA_BASE 0xb8000
#define VGA_MAX_ROW 25
#define VGA_MAX_COL 80
#define STYLE_WHITE_ON_BLACK 0x0f
#define STYLE_WHITE_ON_RED 0x4f

#define REG_SCREEN_CTRL 0x3d4
#define REG_SCREEN_DATA 0x3d5

void vga_clear();
void vga_print(char* message);
void vga_print_at(char* message, int row, int col);

#endif