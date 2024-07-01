[bits 32]

init_pt_32:
  pusha

; 清理需要的内存
.clear_pt_memory_32:
  mov edi, 0x1000 ; 页表从 0x1000 开始
  mov cr3, edi    ; 设置 PML4T 的基地址
  xor eax, eax    ; 清零 eax
  mov ecx, 0x1000 ; 页表大小 4096 字节
  rep stosd       ; 清零整个页表
  mov edi, cr3    ; 将 PML4T 的基地址保存到 edi

; 设置各级页表入口
.set_pt_entry_32:
  mov edi, 0x2003
  add edi, 0x1000 ; PML4T
  mov edi, 0x3003
  add edi, 0x1000 ; PDPT
  mov edi, 0x4003
  add edi, 0x1000 ; PDT

; 设置页表属性
.set_pt_attr_32:
  mov ebx, 0x00000003       ; 地址 0x0000，flag 0x0003
  mov ecx, 512              ; 下面进行 512 次循环，设置 512 个页表项

.set_pt_attr_loop_32:
  mov edi, ebx              ; 写入第一个页表项
  add ebx, 0x1000           ; 下一个页表项
  add edi, 8                ; 下一个写入的位置
  loop .set_pt_attr_loop_32 ; 循环

; 启用 PAE
.enable_pae_32:
  mov eax, cr4 ; 读取 cr4
  or eax, 0x20 ; 设置 PAE 位
  mov cr4, eax ; 写入 cr4

  popa
  ret