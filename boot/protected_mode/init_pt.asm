[bits 32]

init_pt_32:
  pusha

; 在 cr3 寄存器中设置页表位置并清理需要的内存
.clear_pt_memory_32:
  mov edi, 0x1000 ; 页表从 0x1000 开始
  mov cr3, edi    ; 设置 PML4T 的基地址
  xor eax, eax    ; 清零 eax
  mov ecx, 4096   ; 页表大小 4096 字节
  rep stosd       ; 清零整个页表
  mov edi, cr3    ; 将 edi 设置为 PML4T 的地址

; 设置各级页表入口
.set_pt_entry_32:
  mov dword[edi], 0x2003 ; 向 PML4T 写入第一个 PDPT 的地址及 flag
  add edi, 0x1000        ; 将 edi 设置为第一个 PDPT 的地址
  mov dword[edi], 0x3003 ; 向 PDPT 写入第一个 PD 的地址及 flag
  add edi, 0x1000        ; 将 edi 设置为第一个 PD 的地址
  mov dword[edi], 0x4003 ; 向 PD 写入第一个 PT 的地址及 flag
  add edi, 0x1000        ; 将 edi 设置为第一个 PT 的地址

; 设置页表属性
.set_pt_attr_32:
  mov ebx, 0x00000003       ; 默认地址 0x0000，flag 0x0003
  mov ecx, 512              ; 下面进行 512 次循环，设置 512 个页表项

.set_pt_attr_loop_32:
  mov dword[edi], ebx       ; 写入第一个 PT 指向的第一个物理地址
  add ebx, 0x1000           ; 下一个 PT 指向的第一个物理地址
  add edi, 8                ; 下一个写入的位置
  loop .set_pt_attr_loop_32 ; 循环

; 启用 PAE
.enable_pae_32:
  mov eax, cr4 ; 读取 cr4
  or eax, 0x20 ; 设置 PAE 位
  mov cr4, eax ; 写入 cr4

  popa
  ret