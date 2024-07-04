[bits 64]
[extern main]

global _start

_start:
  call main
  jmp $