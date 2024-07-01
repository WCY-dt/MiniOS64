align 4

gdt_start_64:
  dd 0x0 ; 空描述符（32 bit）
  dd 0x0 ; 空描述符（32 bit）

; 代码段
gdt_code_64: 
  dw 0xffff     ; 段长 00-15（16 bit）
  dw 0x0        ; 段基址 00-15（16 bit）
  db 0x0        ; 段基址16-23（8 bit）
  db 0b10011010 ; flags（8 bit）
  db 0b10101111 ; flags（4 bit）+ 段长 16-19（4 bit）
  db 0x0        ; 段基址 24-31（8 bit）

; 数据段
gdt_data_64:
  dw 0xffff     ; 段长 00-15（16 bit）
  dw 0x0        ; 段基址 00-15（16 bit）
  db 0x0        ; 段基址16-23（8 bit）
  db 0b10010010 ; flags（8 bit）
  db 0b10101111 ; flags（4 bit）+ 段长 16-19（4 bit）
  db 0x0        ; 段基址 24-31（8 bit）

gdt_end_64:

; GDT 描述符
gdt_descriptor_64:
  dw gdt_end_64 - gdt_start_64 - 1 ; 比真实长度少 1（16 bit）
  dd gdt_start_64                  ; 基址（32 bit）

; 常量
CODE_SEG_64 equ gdt_code_64 - gdt_start_64
DATA_SEG_64 equ gdt_data_64 - gdt_start_64