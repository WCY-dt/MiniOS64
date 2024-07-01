[org 0x7c00]

; 16 位实模式
BEGIN_RM_16:
[bits 16]

  mov bp, 0x0500        ; 将栈指针移动到安全位置
  mov sp, bp            ; 使其向着 256 字节的 BIOS Data Area 增长

  mov [BOOT_DRIVE], dl

  mov bx, 0x7e00        ; 将数据存储在 512 字节的 Loaded Boot Sector
  mov cl, 0x02          ; 从第 2 个扇区开始
  mov dh, 24             ; 读取 n 个扇区
  mov dl, [BOOT_DRIVE]  ; 读取的驱动器号
  call disk_load_16     ; 读取磁盘数据

  mov bx, MSG_REAL_MODE ; 打印模式信息
  call print_16

  call elevate_32       ; 进入 32 位保护模式

.boot_hold_16:
  jmp $                 ; 根本执行不到这里

%include "real_mode/print.asm"
%include "real_mode/disk.asm"
%include "real_mode/gdt.asm"
%include "real_mode/elevate.asm"

BOOT_DRIVE    db 0
MSG_REAL_MODE db "Started 16-bit real mode", 0

times 510-($-$$) db 0 ; 填充 0
dw 0xaa55             ; 结束标志

BOOT_SECTOR_EXTENDED_32:
; 32 位保护模式
BEGIN_PM_32:
[bits 32]

  call print_clear_32       ; 清屏

  mov esi, MSG_PROT_MODE    ; 打印模式信息
  call print_32

  call check_elevate_32     ; 检查是否支持 64 位

  ; call print_clear_32
  ; mov esi, MSG_LM_SUPPORTED ; 打印信息
  ; call print_32

  call init_pt_32            ; 初始化页表

  call elevate_64            ; 进入 64 位长模式

.boot_hold_32:
  jmp $                      ; 根本执行不到这里

%include "protected_mode/print.asm"
%include "protected_mode/print_clear.asm"
%include "protected_mode/check_elevate.asm"
%include "protected_mode/init_pt.asm"
%include "protected_mode/gdt.asm"
%include "protected_mode/elevate.asm"

VGA_BASE_32       equ 0x000b8000  ; VGA 显示内存地址
VGA_LIMIT_32      equ 80 * 25 * 2 ; VGA 显示内存地址限制
WHITE_ON_BLACK_32 equ 0x0f        ; 白色文本，黑色背景

MSG_PROT_MODE    db "Loaded 32-bit protected mode", 0
; MSG_LM_SUPPORTED db "64-bit long mode supported",   0

times 512 - ($ - BOOT_SECTOR_EXTENDED_32) db 0 ; 填充 0

BOOT_SECTOR_EXTENDED_64:
; 64 位长模式
BEGIN_LM_64:
[bits 64]

  mov rdi, WHITE_ON_BLUE_64
  call print_clear_64
  mov rsi, MSG_LONG_MODE
  call print_64

  call KERNEL_START

.boot_hold_64:
  jmp $

%include "long_mode/print.asm"
%include "long_mode/print_clear.asm"

VGA_BASE_64       equ 0x000b8000  ; VGA 显示内存地址
VGA_LIMIT_64      equ 80 * 25 * 2 ; VGA 显示内存地址限制
WHITE_ON_BLUE_64  equ 0x1f        ; 白色文本，蓝色背景

KERNEL_START      equ 0x8200     ; 内核入口地址

MSG_LONG_MODE db "Jumped to 64-bit long mode", 0

times 512 - ($ - BOOT_SECTOR_EXTENDED_64) db 0 ; 填充 0