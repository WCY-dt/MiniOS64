[bits 16]

; 未使用
print_nl_16:
  pusha           ; 保存寄存器状态
  
  mov ah, 0x0e    ; 设置 TTY 模式

  mov al, 0x0a    ; 换行符
  int 0x10        ; 打印换行符
  mov al, 0x0d    ; 回车符
  int 0x10        ; 打印回车符
  
  popa            ; 恢复寄存器状态
  ret             ; 返回