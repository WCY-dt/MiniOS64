[bits 16]

; @depends print.asm
; @param bx: 存储数据要保存的位置
; @param cl: 存储开始要读取的扇区号
; @param dh: 存储要读取的扇区数
; @param dl: 存储要读取的驱动器号
disk_load_16:
  push dx            ; 保存要读取的扇区数

  mov ah, 0x02       ; 表明是读取

  mov al, dh         ; 要读取的扇区数
  mov dh, 0x00       ; 从第 0 个磁头 (0x0 .. 0xF) 开始
  mov ch, 0x00       ; 从第 0 个磁道 (0x0 .. 0x3FF, 其中最高两位在 cl 中) 开始
  
  int 0x13           ; BIOS 磁盘服务中断
  jc .disk_error_16  ; 如果读取失败，跳转

  pop dx             ; 要读取的扇区数
  cmp dh, al         ; 检查读取的扇区数是否正确
  jne .disk_error_16 ; 如果不正确，跳转

  ret

.disk_error_16:
  mov bx, DISK_ERROR_MSG_16
  call print_16
  jmp $

DISK_ERROR_MSG_16: db "[ERR] Disk read error", 0