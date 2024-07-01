[bits 64]

; @param rdi: 打印样式
print_clear_64:
  push rdi                       ; 保存 rdi 寄存器状态
  push rax                       ; 保存 rax 寄存器状态
  push rdx                       ; 保存 rdx 寄存器状态

  shl rdi, 8 ; 将打印样式左移 8 位
  mov rax, rdi ; 设置样式

  mov al, SPACE_CHAR_64 ; 设置空格字符

  mov rdi, VGA_BASE_64 ; 设置显存地址
  mov rcx, VGA_LIMIT_64 / 2 ; 显示内存地址限制

  rep stosw ; 将 ax 中的数据写入显存

  pop rdx                        ; 恢复 rdx 寄存器状态
  pop rax                        ; 恢复 rax 寄存器状态
  pop rdi                        ; 恢复 rdi 寄存器状态
  ret

SPACE_CHAR_64 equ 0x20 ; 空格字符