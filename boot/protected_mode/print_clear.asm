[bits 32]

print_clear_32:
  pusha

  mov ebx, VGA_LIMIT_32 ; 显示内存地址限制
  mov ecx, VGA_BASE_32 ; 设置显存地址
  mov edx, 0 ; 指向当前要写入的位置

.print_clear_loop_32:
  cmp edx, ecx ; 判断是否到达显示内存地址限制
  jge .print_clear_done_32 ; 如果是，结束循环

  push edx

  mov al, SPACE_CHAR_32 ; 设置空格字符
  mov ah, WHITE_ON_BLACK_32 ; 设置样式

  add edx, ecx ; 计算显示内存地址
  mov [edx], ax ; 将 ax 中的数据写入显存

  pop edx; 恢复 edx
  
  add edx, 2 ; 指向下一个字符的显存位置
  
  jmp .print_clear_loop_32 ; 继续循环

.print_clear_done_32:
  popa
  ret

SPACE_CHAR_32 equ 0x20 ; 空格字符