[org 0x7c00]

; 16 位实模式
[bits 16]

  mov bp, 0x0500        ; 将栈指针移动到安全位置
  mov sp, bp            ; 使其向着 256 字节的 BIOS Data Area 增长

  mov [BOOT_DRIVE], dl

  mov bx, 0x7e00        ; 将数据存储在 512 字节的 Loaded Boot Sector
  mov cl, 0x02          ; 从第 2 个扇区开始
  mov dh, 0x01          ; 读取 1 个扇区
  mov dl, [BOOT_DRIVE]  ; 读取的驱动器号
  call disk_load_16     ; 读取磁盘数据

  mov bx, MSG_REAL_MODE ; 打印模式信息
  call print_16

  call elevate_32 ; 进入 32 位保护模式

.boot_hold_16:
  jmp $ ; 根本执行不到这里

%include "real_mode/print.asm"
%include "real_mode/disk.asm"
%include "real_mode/gdt.asm"
%include "real_mode/elevate.asm"

BOOT_DRIVE    db 0
MSG_REAL_MODE db "Started 16-bit real mode", 0

times 510-($-$$) db 0 ; 填充 0
dw 0xaa55 ; 结束标志

; 32 位保护模式
[bits 32]

BEGIN_PM_32:
  mov esi, MSG_PROT_MODE ; 打印模式信息
  call print_32

  call check_elevate_32 ; 检查是否支持 64 位


.boot_hold_32:
  jmp $

%include "protected_mode/print.asm"
%include "protected_mode/check_elevate.asm"
%include "protected_mode/init_pt.asm"

MSG_PROT_MODE db "Loaded 32-bit protected mode", 0

; 64 位长模式

MSG_LONG_MODE db "Jumped to 64-bit long mode", 0