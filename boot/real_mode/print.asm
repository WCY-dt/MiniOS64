[bits 16]

; @param bx: 指向字符串的指针
print_16:
  pusha              ; 保存寄存器状态

  mov ah, 0x0e       ; 设置 TTY 模式

.print_loop_16:
  mov al, [bx]       ; 取出 bx 指向的数据
  cmp al, 0          ; 判断是否为字符串结尾
  je .print_done_16  ; 如果是，结束循环

  int 0x10           ; 打印 al 中的数据
  inc bx             ; 指向下一个字符
  jmp .print_loop_16 ; 继续循环

.print_done_16:
  popa               ; 恢复寄存器状态
  ret                ; 返回