[bits 16]

; 未使用
; @depends print.asm
; @param dx: 要打印的 16 位数据
print_hex_16:
  pusha                  ; 保存寄存器状态
  
  mov cx, 5              ; 首先设置 HEX_OUT 的最后一位

.print_hex_loop_16:
  cmp cx, 1              ; 判断是否到达 HEX_OUT 的第一位 (x)
  je .print_hex_done_16  ; 如果是，结束循环

  mov ax, dx             ; 将 dx 中的数据放入 ax
  and ax, 0xf            ; 取出 ax 的最后一位

  mov bx, HEX_DIGITS_16  ; 取出 HEX_DIGITS 的地址
  add bx, ax             ; 计算出对应的字符的地址
  mov al, [bx]           ; 取出对应的字符

  mov bx, HEX_OUT_16     ; 取出 HEX_OUT 的地址
  add bx, cx             ; 计算出要写入的位置
  mov [bx], al           ; 将字符写入 HEX_OUT

  shr dx, 4              ; 将 dx 右移 4 位
  dec cx                 ; 准备处理下一位
  jmp .print_hex_loop_16 ; 继续循环

.print_hex_done_16:
  mov bx, HEX_OUT_16
  call print_16          ; 调用打印函数

  popa                   ; 恢复寄存器状态
  ret                    ; 返回
  
HEX_DIGITS_16:
  db '0123456789ABCDEF'

HEX_OUT_16:
  db '0x0000', 0