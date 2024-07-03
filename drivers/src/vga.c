#include "vga.h"
#include "ports.h"
#include "util.h"

int vga_print_char_at(char c, int row, int col, char style);
int vga_get_offset_from_cursor();
void vga_set_offset_from_cursor(int offset);
int vga_get_offset(int row, int col);
int vga_get_row_from_offset(int offset);
int vga_get_col_from_offset(int offset);

void vga_clear() {
    unsigned char* vga = (unsigned char*)VGA_BASE;

    for (int i = 0; i < 2 * VGA_MAX_ROW * VGA_MAX_COL; i += 2) {
        vga[i] = ' ';
        vga[i + 1] = STYLE_WHITE_ON_BLACK;
    }

    vga_set_offset_from_cursor(vga_get_offset(0, 0));
}

void vga_print_at(char* message, int row, int col) {
    int offset;
    if (row >= 0 && col >= 0) {
        offset = vga_get_offset(row, col);
    } else {
        offset = vga_get_offset_from_cursor();
        row = vga_get_row_from_offset(offset);
        col = vga_get_col_from_offset(offset);
    }

    int i = 0;
    while (message[i] != 0) {
        offset = vga_print_char_at(message[i], row, col, STYLE_WHITE_ON_BLACK);

        row = vga_get_row_from_offset(offset);
        col = vga_get_col_from_offset(offset);

        i++;
    }
}

void vga_print(char* message) {
    vga_print_at(message, -1, -1);
}

int vga_print_char_at(char c, int row, int col, char style) {
    unsigned char* vga = (unsigned char*)VGA_BASE;

    if (!style) {
        style = STYLE_WHITE_ON_BLACK;
    }

    if (row >= VGA_MAX_ROW || col >= VGA_MAX_COL) {
        vga[2 * (VGA_MAX_ROW * VGA_MAX_COL) - 2] = 'E';
        vga[2 * (VGA_MAX_ROW * VGA_MAX_COL) - 1] = STYLE_WHITE_ON_RED;
        return vga_get_offset(col, row);
    }

    int offset;
    if (row >= 0 && col >= 0) {
        offset = vga_get_offset(row, col);
    } else {
        offset = vga_get_offset_from_cursor();
        row = vga_get_row_from_offset(offset);
        col = vga_get_col_from_offset(offset);
    }

    if (c == '\n') {
        offset = vga_get_offset(row + 1, 0);
    } else {
        vga[offset] = c;
        vga[offset + 1] = style;
        offset += 2;
    }

    if (offset >= 2 * VGA_MAX_ROW * VGA_MAX_COL) {
        for (int i = 1; i < VGA_MAX_ROW; i++) {
            memory_copy(CAST_TO_CHAR_PTR(vga_get_offset(i, 0) + VGA_BASE), CAST_TO_CHAR_PTR(vga_get_offset(i - 1, 0) + VGA_BASE), 2 * VGA_MAX_COL);
        }
        
        memory_set(CAST_TO_CHAR_PTR(vga_get_offset(VGA_MAX_ROW - 1, 0) + VGA_BASE), ' ', 2 * VGA_MAX_COL);

        offset -= 2 * VGA_MAX_COL;
    }

    vga_set_offset_from_cursor(offset);

    return offset;
}

int vga_get_offset_from_cursor() {
    port_byte_out(REG_SCREEN_CTRL, 14);
    int offset = port_byte_in(REG_SCREEN_DATA) << 8;
    port_byte_out(REG_SCREEN_CTRL, 15);
    offset += port_byte_in(REG_SCREEN_DATA);
    return offset * 2;
}

void vga_set_offset_from_cursor(int offset) {
    offset /= 2;
    port_byte_out(REG_SCREEN_CTRL, 14);
    port_byte_out(REG_SCREEN_DATA, (unsigned char)(offset >> 8));
    port_byte_out(REG_SCREEN_CTRL, 15);
    port_byte_out(REG_SCREEN_DATA, (unsigned char)(offset & 0xff));
}

int vga_get_offset(int row, int col) {
    return 2 * (row * VGA_MAX_COL + col);
}

int vga_get_row_from_offset(int offset) {
    return offset / (2 * VGA_MAX_COL);
}

int vga_get_col_from_offset(int offset) {
    return (offset - vga_get_row_from_offset(offset) * 2 * VGA_MAX_COL) / 2;
}