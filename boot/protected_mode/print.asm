[bits 32]

; @param esi: 指向字符串的指针
print_32:
  pusha                       ; 保存寄存器状态
  mov edx, VGA_BASE_32        ; 设置显存地址

.print_loop_32:
  mov al, [esi]               ; 取出 bx 指向的数据
  mov ah, WHITE_ON_BLACK_32   ; 设置样式

  cmp al, 0                   ; 判断是否为字符串结尾
  je .print_done_32           ; 如果是，结束循环

  mov [edx], ax               ; 将 ax 中的数据写入显存
  
  add esi, 1                  ; 指向下一个字符
  add edx, 2                  ; 指向下一个字符的显存位置

  jmp .print_loop_32          ; 继续循环

.print_done_32:
  popa                        ; 恢复寄存器状态
  ret                         ; 返回