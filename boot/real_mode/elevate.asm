[bits 16]

elevate_32:
  cli ; 禁用中断

  lgdt [gdt_descriptor_32] ; 加载 GDT

  mov eax, cr0 ; 将 CR0 寄存器的第 0 位置 1
  or eax, 0x1
  mov cr0, eax

  jmp CODE_SEG_32:.init_pm_32 ; 长距离的 jmp

[bits 32]

.init_pm_32:
  mov ax, DATA_SEG_32 ; 更新段寄存器
  mov ds, ax
  mov ss, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  mov ebp, 0x90000 ; 更新栈位置
  mov esp, ebp

  call BEGIN_PM_32 ; 去执行接下来的代码