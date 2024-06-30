[bits 32]

; @depends print.asm
check_elevate_32:
  pusha ; 保存寄存器状态

; 将标志位第 21 位翻转，观察是否会自动恢复，如果恢复了，说明 cpuid 存在
.check_cpuid_exist_32:
  pushfd            ; 保存标志寄存器
  pop eax           ; 将标志寄存器保存到 eax
  mov ecx, eax      ; 复制标志寄存器到 ecx

  xor eax, 0x200000 ; 将第 21 位翻转
  push eax          ; 将修改后的标志寄存器保存到栈中
  popfd             ; 恢复标志寄存器

  pushfd            ; 保存修改后的标志寄存器
  pop eax           ; 将修改后的标志寄存器保存到 eax

  push ecx          ; 将原始标志寄存器保存到栈中
  popfd             ; 恢复标志寄存器

  cmp eax, ecx      ; 比较修改后的标志寄存器和原始标志寄存器
  je .no_cpuid_32   ; 如果相等，说明不支持 64 位

; 将 0x80000000 作为参数调用 cpuid，如果 eax 变大了，说明支持扩展功能
.check_cpuid_extend_function_exist_32:
  mov eax, 0x80000000 ; 设置 cpuid 的最大功能号
  cpuid               ; 调用 cpuid

  cmp eax, 0x80000000 ; 检查是否支持扩展功能
  jle .no_cpuid_extend_function_32

;
.check_cpuid_lm_32:
  mov eax, 0x80000001  ; 设置 cpuid 的功能号
  cpuid                ; 调用 cpuid

  test edx, 0x20000000 ; 检查第 29 位是否为 1
  jz .no_lm_32

  popa ; 恢复寄存器状态
  ret

.no_cpuid_32:
  mov esi, NO_CPUID_MSG_32
  call print_32
  jmp $

.no_cpuid_extend_function_32:
  mov esi, NO_EXTEND_MSG_32
  call print_32
  jmp $

.no_lm_32:
  mov esi, NO_LM_MSG_32
  call print_32
  jmp $

NO_CPUID_MSG_32  db "[ERR] CPUID instruction is not supported",   0
NO_EXTEND_MSG_32 db "[ERR] Extended functions are not supported", 0
NO_LM_MSG_32     db "[ERR] Long mode is not supported",           0
