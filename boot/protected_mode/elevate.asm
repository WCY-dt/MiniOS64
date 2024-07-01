[bits 32]

elevate_64:
  mov ecx, 0xc0000080 ; 设置 IA32_EFER 的第 8 位为 1
  rdmsr
  or eax, 1 << 8
  wrmsr

  mov eax, cr0 ; 将 CR0 寄存器的第 31 位置 1
  or eax, 1 << 31
  mov cr0, eax

  lgdt [gdt_descriptor_64] ; 加载 GDT
  jmp CODE_SEG_64:.init_lm_64 ; 长距离的 jmp

[bits 64]

.init_lm_64:
  cli ; 禁用中断

  mov ax, DATA_SEG_64 ; 更新段寄存器
  mov ds, ax
  mov ss, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  call BEGIN_LM_64 ; 去执行接下来的代码