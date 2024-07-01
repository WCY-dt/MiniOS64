[bits 64]

; @param rdi: 打印样式
; @param rsi: 指向字符串的指针
print_64:
  push rdi                       ; 保存 rdi 寄存器状态
  push rsi                       ; 保存 rsi 寄存器状态
  push rax                       ; 保存 rax 寄存器状态
  push rdx                       ; 保存 rdx 寄存器状态

  mov rdx, VGA_BASE_64           ; 设置显存地址

  shl rdi, 8                     ; 将打印样式左移 8 位

.print_loop_64:
  cmp byte[rsi], 0              ; 判断是否为字符串结尾
  je .print_done_64              ; 如果是，结束循环

  cmp rdx, VGA_BASE_64 + VGA_LIMIT_64 ; 判断是否到达显示内存地址限制
  jge .print_done_64             ; 如果是，结束循环

  mov rax, rdi                   ; 设置样式
  mov al, byte[rsi]                  ; 取出 rsi 指向的数据

  mov word[rdx], ax                  ; 将 ax 中的数据写入显存
  
  add rsi, 1                     ; 指向下一个字符
  add rdx, 2                     ; 指向下一个字符的显存位置

  jmp .print_loop_64             ; 继续循环

.print_done_64:
  pop rdx                        ; 恢复 rdx 寄存器状态
  pop rax                        ; 恢复 rax 寄存器状态
  pop rsi                        ; 恢复 rsi 寄存器状态
  pop rdi                        ; 恢复 rdi 寄存器状态
  ret                            ; 返回