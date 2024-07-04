# MiniOS

## 环境准备

我推荐你用 x86_64 平台下的 Linux。因为我们将要开发 x86_64 平台下的系统，使用别的平台做开发可能会需要交叉编译。而 Linux 单纯是因为配置环境方便，我认为 MacOS 应该也是没有问题的，但我没有试过。

先安装好必要的工具：

```bash
sudo apt-get update
sudo apt-get install nasm qemu gcc gcc-multilib
```

你要是心情好的话，也可以再安装一些调试工具：

```bash
sudo apt-get install xxd gdb
```

我已经在 WSL 和虚拟机上都测试过了，正常开发没有问题。

## 系统，启动！

### 引导扇区

![擦电开机](./imgs/擦电开机.jpg)

擦电！开机！

此时计算机一片混沌，BIOS (Basic Input/Output System) 开天辟地。

> 当然，新的计算机都使用 UEFI（Unified Extensible Firmware Interface）了。
>
> UEFI 也会使用到 BIOS，它和单纯使用 BIOS 的区别在于加载内核的方式、准备工作和高级功能等。这里为了方便起见，我们暂时只考虑 BIOS。

此时的计算机连文件系统都没有！也就是说，我们甚至无法告诉 BIOS 从哪里加载操作系统到内存。于是，有人规定了，操作系统应当放在存储设备最开始的 512 字节（例如磁盘第 0 柱面第 0 磁头第 0 扇区）。这个区域就是我们的`引导扇区`。也就是说，操纵系统运行的第一行代码就是在引导扇区中。

然而，一台计算机可能有多个存储设备，BIOS 依然不知道哪个设备存储了引导扇区。但不知道谁又规定了，引导扇区的最后两个字节必须是 `0xaa55`。于是，BIOS 只需要遍历所有存储设备，检查他们的第 511 和 512 字节是否是 `0xaa55`。如果是，就说明找到了操作系统的位置，把这一段数据加载到内存中，然后跳转到这段代码的第一个字节开始执行。

因此，对于手动编写一个引导扇区来说，只需要：

1. 首先把最后两个字节设置为 `0xaa55`；
2. 然后从第一个字节开始写上想要的代码；
3. 最后把其它的字节填充为 `0`，补满 512 字节。

我们暂时先写一个死循环：

`boot/boot.asm`：

```asm
[bits 16]             ; 告诉汇编器我们是在 16 位下工作

jmp $                 ; $ 表示当前地址，跳转到当前地址就是死循环

times 510-($-$$) db 0 ; $ 表示当前地址，$$ 表示当前段的开始地址
                      ; 510-($-$$) 计算出当前位置到 510 字节的距离，然后全部填充为 0

dw 0xaa55             ; 最后两个字节是 0xaa55
```

然后编译为二进制文件：

```bash
nasm ./boot/boot.asm -f bin -o ./boot/dist/boot.bin
```

再使用 QEMU 运行：

```bash
qemu-system-x86_64 ./boot/dist/boot.bin
```

你会看到窗口中显示 `Booting from Hard Disk...`，然后它就开始执行我们的死循环了。

![QEMU 进入死循环](./imgs/qemu.jpg)

你也可以用下面的命令看看我们的 bin 文件内容是否如我们所想：

```bash
xxd ./boot/dist/boot.bin
```

值得一提的是，目前状态下的程序只能以 16 位运行，因此我们只能使用 16 位的寄存器和指令。我们在[后面的章节](#16-位实模式)会解释这一切，并逐步用上 64 位的寄存器和指令。

### `Hello, World!`

死循环没什么意思，我们来尝试输出一句 `Hello, World!`。同样的，先写程序，然后将最后两位设置为 `0xaa55`，再把其它的字节填充为 `0`。

问题来了，如何在汇编中打印字符？首先，我们要设置要打印哪个字符。我们只需要将字符存储在 `ax` 寄存器的低 8 位（也就是 `al` 寄存器），然后调用 `int 0x10` 中断执行打印即可。

> 对于此时的 x86 CPU 来讲，一共有 4 个 16 位通用寄存器，包括 `ax`、`bx`、`cx` 和 `dx`。有时候我们只需要使用 8 位，因此每个 16 位寄存器可以拆为两个 8 位寄存器，例如 `al` 和 `ah`。

> 什么是中断？简单来讲就是给 CPU 正在做的事情按下暂停，然后去执行我们指定的任务。中断可以执行的任务被存储在内存最开始的区域，这个区域像一张表格（中断向量表），每个单元格指向一段指令的地址，也就是 ISR（interrupt service routines）。
>
> 为了方便在汇编中调用，BIOS 给这些中断分配了号码。例如，`int 0x10` 就是第 16 个中断，它指向了一个打印字符的 ISR。

然而 `int 0x10` 中断只知道要打印，但并不知道要怎么打印。我们这里将其设置为 TTY（TeleTYpe）模式，让它接收字符并显示在屏幕上，然后将光标向后移动。设置 TTY 模式的方法是将 `ah` 寄存器设置为 `0x0e`，你可以理解为传给系统中断的参数。

于是我们修改刚刚的代码：

`boot/boot.asm`：

```asm
  mov ah, 0x0e           ; 设置 TTY 模式

  mov al, 'H'            ; 设置要打印的字符
  int 0x10
  mov al, 'e'
  int 0x10
  mov al, 'l'
  int 0x10
  mov al, 'l'
  int 0x10
  mov al, 'o'
  int 0x10
  mov al, ','
  int 0x10
  mov al, ' '
  int 0x10
  mov al, 'W'
  int 0x10
  mov al, 'o'
  int 0x10
  mov al, 'r'
  int 0x10
  mov al, 'l'
  int 0x10
  mov al, 'd'
  int 0x10
  mov al, '!'
  int 0x10

  jmp $                 ; 打印完成后死循环

  times 510-($-$$) db 0 ; 填充 0

  dw 0xaa55             ; 最后两个字节是 0xaa55
```

现在，再次编译运行，便可以看到 `Hello, World!` 了。

我推荐你用 `xxd ./boot/dist/boot.bin` 来查看编译后的二进制文件，看看这些汇编指令在二进制中到底是啥样的。

### 内存地址

512 字节小小的也很可爱，但显然满足不了操作系统庞大的欲望，因此操作系统的绝大部分代码被放在磁盘的其它地方。这些代码是如何加载到内存的呢？

在回答如何加载到内存之前，我们先关注另一个更紧迫的问题：应该加载到内存的哪里？

答案是，引导扇区并没有被加载到内存的 `0x0000` 处。这是因为内存中还需要存储一些重要的信息，例如中断向量表、BIOS 数据区等。这些内容需要占用一部分内存，因此有人规定，引导扇区应当被加载到 `0x7c00` 处。

更具体地讲，开头这块的内存布局如下：

```plaintext
          |         Free          |
0x100000  +-----------------------+
          |     BIOS (256 KB)     |
0x0C0000  +-----------------------+
          | Video Memory (128 KB) |
0x0A0000  +-----------------------+
          |Extended BIOS Data Area|
          |        (639 KB)       |
0x09FC00  +-----------------------+
          |     Free (638 KB)     |
0x007E00  +-----------------------+
          |   Loaded Boot Sector  |
          |      (512 Bytes)      |
0x007C00  +-----------------------+
          |                       |
0x000500  +-----------------------+
          |     BIOS Data Area    |
          |      (256 Bytes)      |
0x000400  +-----------------------+
          | Interrupt Vector Table|
          |         (1 KB)        |
0x000000  +-----------------------+
```

> 这张图还挺重要，我们之后会不断参考它。

在汇编中，我们定义的数据都存储的相对地址。为了访问它们，我们需要将这些相对地址转换为绝对地址——也就是加上 `0x7c00`。例如：

`boot/boot.asm`：

```asm
  mov ah, 0x0e

  mov bx, my_data ; 将 my_data 的相对地址存储到 bx 中
  add bx, 0x7c00  ; 将 bx 加上 0x7c00，得到 my_data 的绝对地址
  mov al, [bx]    ; 从 my_data 的绝对地址读取数据放入 al 中
  int 0x10        ; 打印 al 中的数据

  jmp $

my_data:
  db 'X'          ; db 表示 declare bytes

  times 510-($-$$) db 0
  dw 0xaa55
```

但是，每次都要加上 `0x7c00` 太麻烦了，我们可以使用 `org` 指令来设置全局偏移量（当前段的基地址）：

`boot/boot.asm`：

```asm
[org 0x7c00]

  mov ah, 0x0e

  mov al, [my_data] ; 自动转换为了 [0x7c00 + my_data]
  int 0x10          ; 打印 al 中的数据

  jmp $

my_data:
  db 'X'

  times 510-($-$$) db 0
  dw 0xaa55
```

### 分段

我们使用 `[org 0x7c00]` 来设置当前段的基地址，从底层来看，这相当于设置了`段寄存器`的值。

段基址可以存储在 4 个 16 位寄存器中，分别是 `cs`、`ds`、`ss` 和 `es`。存储的基址在计算时会左移 4 位，然后加上段内偏移量。例如，我将 `ds` 设置为 `0x7c0`，那么访问 `0x10` 时，实际上访问的是 `0x7c0 << 4 + 0x10 = 0x7c10`。

因此，`[org 0x7c00]` 和把 `0x7c0` 传入 `ds` 是等价的：

`boot/boot.asm`：

```asm
  mov ah, 0x0e

  mov bx, 0x7c0     ; 将 my_data 的相对地址存储到 bx 中
  mov ds, bx        ; 将 bx 的值传入 ds
  mov al, [my_data] ; 自动转换为了 [0x7c00 + my_data]
  int 0x10          ; 打印 al 中的数据

  jmp $

my_data:
  db 'X'

  times 510-($-$$) db 0
  dw 0xaa55
```

> 注意，我们无法将立即数直接传入段寄存器。我们需要先将立即数存储到一个通用寄存器中，再从通用寄存器传入段寄存器。
>
> 你可以试着这么做，但会报错：
>
> ```plaintext
> error: invalid combination of opcode and operands
> ```

当然，也可以使用别的段寄存器，例如 `es`：

`boot/boot.asm`：

```asm
  mov ah, 0x0e

  mov bx, 0x7c0        ; 将 my_data 的相对地址存储到 bx 中
  mov es, bx           ; 将 bx 的值传入 es
  mov al, [es:my_data] ; 自动转换为了 [0x7c00 + my_data]
  int 0x10             ; 打印 al 中的数据

  jmp $

my_data:
  db 'X'

  times 510-($-$$) db 0
  dw 0xaa55
```

### Another `Hello, World!`

我大胆假设一下，你的汇编水平和我卧龙凤雏。所以我不打算介绍基础的汇编知识了，直接上代码。

我们可以将 `Hello, World!` 存储在内存中，然后通过循环打印出来：

`boot/boot.asm`：

```asm
[org 0x7c00]

  mov bx, HELLO_MSG ; 放入参数地址
  call print_16     ; 调用打印函数

  jmp $

%include "real_mode/print.asm"

HELLO_MSG:
  db 'Hello, World!', 0

  times 510-($-$$) db 0
  dw 0xaa55
```

[`boot/real_mode/print.asm`](./boot/real_mode/print.asm):

```asm
[bits 16]

; @param bx: 指向字符串的指针
print_16:
  pusha              ; 保存寄存器状态

  mov ah, 0x0e       ; 设置 TTY 模式

.print_loop_16:
  mov al, [bx]       ; 取出 bx 指向的数据
  cmp al, 0          ; 判断是否为字符串结尾
  je .print_done_16  ; 如果是，结束循环

  int 0x10           ; 打印 al 中的数据
  inc bx             ; 指向下一个字符
  jmp .print_loop_16 ; 继续循环

.print_done_16:
  popa               ; 恢复寄存器状态
  ret                ; 返回
```

编译运行，你会看到 `Hello, World!` 被打印在屏幕上。

很好，你已经精通汇编了。接下来，我们要用类似的控制流、函数调用等概念，来实现更多的功能。

### 打印 16 进制

别急，我们依然还没有做好读取磁盘的准备。

为了编写这种过于底层的程序，我们需要一些调试工具。但是，gdb 显然太过城市化了。我们将会使用最原始的打印的方法来调试我们的程序。

上一节中，我们已经实现了一个打印字符串的函数。现在，我们再来实现一个打印 16 进制的函数。

`boot/boot.asm`:

```asm
[org 0x7c00]

  mov bx, HELLO_MSG ; 放入参数地址
  call print_16     ; 调用打印函数

  call print_nl_16  ; 调用打印换行函数

  mov dx, 0x1f6b    ; 放入参数
  call print_hex_16 ; 调用打印 16 进制函数

  jmp $

%include "real_mode/print.asm"
%include "real_mode/print_nl.asm"
%include "real_mode/print_hex.asm"

HELLO_MSG:
  db 'Hello, World!', 0

  times 510-($-$$) db 0
  dw 0xaa55
```

[`boot/real_mode/print_hex.asm`](./boot/real_mode/print_hex.asm):

```asm
[bits 16]

; @depends print.asm
; @param dx: 要打印的 16 位数据
print_hex_16:
  pusha                  ; 保存寄存器状态
  
  mov cx, 5              ; 首先设置 HEX_OUT 的最后一位

.print_hex_loop_16:
  cmp cx, 1              ; 判断是否到达 HEX_OUT 的第一位 (x)
  je .print_hex_done_16  ; 如果是，结束循环

  mov ax, dx             ; 将 dx 中的数据放入 ax
  and ax, 0xf            ; 取出 ax 的最后一位

  mov bx, HEX_DIGITS_16  ; 取出 HEX_DIGITS 的地址
  add bx, ax             ; 计算出对应的字符的地址
  mov al, [bx]           ; 取出对应的字符

  mov bx, HEX_OUT_16     ; 取出 HEX_OUT 的地址
  add bx, cx             ; 计算出要写入的位置
  mov [bx], al           ; 将字符写入 HEX_OUT

  shr dx, 4              ; 将 dx 右移 4 位
  dec cx                 ; 准备处理下一位
  jmp .print_hex_loop_16 ; 继续循环

.print_hex_done_16:
  mov bx, HEX_OUT_16
  call print_16          ; 调用打印函数

  popa                   ; 恢复寄存器状态
  ret                    ; 返回
  
HEX_DIGITS_16:
  db '0123456789ABCDEF'

HEX_OUT_16:
  db '0x0000', 0
```

同时，在 [`boot/real_mode/print_nl.asm`](./boot/real_mode/print_nl.asm) 中添加打印换行函数：

```asm
[bits 16]

print_nl_16:
  pusha           ; 保存寄存器状态
  
  mov ah, 0x0e    ; 设置 TTY 模式

  mov al, 0x0a    ; 换行符
  int 0x10        ; 打印换行符
  mov al, 0x0d    ; 回车符
  int 0x10        ; 打印回车符
  
  popa            ; 恢复寄存器状态
  ret             ; 返回
```

编译运行，你会看到 `Hello, World!` 和 `0x1F6B` 被打印在屏幕上。

万事俱备，只欠东风。接下来，我们就真的要开始读取磁盘了。

### 读取磁盘

首先要考虑的是，我们如何定位磁盘上的某一个区域。

通常，磁盘会按照 CHS 来定位。Head 是磁头，Cylinder 是磁道，Sector 是扇区。我们可以使用这三个参数来定位磁盘上的某一个区域，如图所示。

![CHS 示意图](./imgs/chs.jpeg)

> 还有一种方式是 LBA（Logical Block Addressing），它使用一个 32 位的地址来定位磁盘上的某一个区域。它和 CHS 的区别如图所示。
>
> ![CHS vs LBA](./imgs/chs_vs_lba.gif)

读盘是使用 [`0x13` 中断](https://stanislavs.org/helppc/int_13-2.html)来实现的，它的参数如下：

- `ah`：功能号，`0x02` 表示读取扇区；
- `al`：要读取的扇区数，范围从 `0x01` 到 `0x80`；
- `es:bx`: 放置数据的地址；
- `ch`：开始读取的磁道号，范围从 `0x0` 到 `0x3ff`；
- `cl`：开始读取的扇区号，范围从 `0x01` 到 `0x11`（`0x00` 是引导扇区）；
- `dh`：开始读取的磁头号，范围从 `0x0` 到 `0xf`；
- `dl`：驱动器号，`0`=A:、`1`=2nd floppy、`0x80`=drive 0、`0x81`=drive 1。

返回值为：

- `ah` 为[状态码](https://stanislavs.org/helppc/int_13-1.html)；
- `al` 为读取的扇区数；
- `cf` 为指示是否出错的标志，`0` 表示成功，`1` 表示失败。

据此，我们可以很容易地实现读取磁盘：

`boot/boot.asm`:

```asm
[org 0x7c00]
  mov [BOOT_DRIVE], dl   ; 保存启动驱动器号

  mov bp, 0x0500         ; 将栈指针移动到安全位置
  mov sp, bp

  mov bx, 0x7e00        ; 将数据存储在 512 字节的 Loaded Boot Sector
                        ; 位置在 [es:bx] 中，其中 es = 0x0000
  mov cl, 0x02          ; 从第 2 个扇区开始
  mov dh, 4             ; 读取 4 个扇区 (0x01 .. 0x80)
  mov dl, [BOOT_DRIVE]  ; 0 = floppy, 1 = floppy2, 0x80 = hdd, 0x81 = hdd2
  call disk_load_16     ; 读取磁盘数据

  mov dx, [0x7e00]       ; 扇区 2 磁道 0 磁头 0 的第一个字
  call print_hex_16

  call print_nl_16

  mov dx, [0x7e00 + 1536] ; 扇区 5 磁道 0 磁头 0 的第一个字
  call print_hex_16

  jmp $

%include "real_mode/print.asm"
%include "real_mode/print_nl.asm"
%include "real_mode/print_hex.asm"

  BOOT_DRIVE: db 0

  times 510 - ($-$$) db 0
  dw 0xaa55

  times 256 dw 0xdead ; 扇区 2 磁道 0 磁头 0
  times 256 dw 0xbeaf ; 扇区 3 磁道 0 磁头 0
  times 256 dw 0xface ; 扇区 4 磁道 0 磁头 0
  times 256 dw 0xbabe ; 扇区 5 磁道 0 磁头 0
```

[`boot/real_mode/disk.asm`](./boot/real_mode/disk.asm):

```asm
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
```

编译运行后，你会看到 `0xdead` 和 `0xbabe` 被打印在屏幕上。

## 32 位保护模式

### 16 位实模式

我们之前一直在 16 位下工作，这是因为计算机是充满妥协的，当你设计出一个新东西的时候，总是要考虑向下兼容。

对于刚开始启动的计算机来讲，当然不知道操作系统是多少位的。为了兼容，它只能先进入一个 16 位的模式——`16 位实模式`。实模式是 Intel 8086 处理器的一种工作模式，在实模式下，CPU 只能访问 1MB 的内存，而且只能使用 16 位的寄存器。

我们刚刚就一直在实模式下工作。但是，实模式有着很多缺点。因此，我们在实模式下读取到一些硬盘数据后，便可以顺势进入 `32 位保护模式`，享受到更大的内存、更多更大的寄存器、更丰富的功能。具体来讲有以下几点：

- 寄存器全部变为 32 位，我们向之前的寄存器名称前添加 `e` 来表明这一点，例如 `eax`、`ebx`；
- 增加了 2 个新的段寄存器 `fs` 和 `gs`；
- 内存偏移增加至 32 位，因此我们可以访问到 4 GB 的内存；
- 支持了虚拟内存、内存保护等功能。

当然，在这之后，还可以进入 `64 位长模式`，我们[后文](#64-位长模式)会具体介绍。但现在，让我们先从 32 位保护模式开始。

要想从 16 位实模式进入 32 位保护模式，有几项必须完成的步骤：

1. 禁用中断；
2. 设置并加载 GDT；
3. 设置 CR0 寄存器的指示位；
4. 更新各寄存器。

这些步骤我们会逐一介绍。

> 事实上，32 位保护模式还有一个子模式，叫做 `虚拟 8086 模式`。在这个模式下，CPU 会模拟出一个 8086 处理器，让它运行 16 位的程序。这个模式在运行一些老的程序时很有用。我们这里将不会涉及。

> 切换到 32 位实模式可能还会需要启用 `A20`，但这是老黄历了，我们不做介绍。

### Yet Another `Hello, World!`

在 32 位保护模式中，BIOS 就无法使用了。这让我们没法方便地调用系统中断来打印字符。但幸运的是，我们不需要当人肉显卡手操像素点！

不管你的计算机是亮机卡还是 4090，在进入 32 位保护模式时都会从 VGA（Video Graphics Array）开始。VGA 能够打印出 80×25 的字符，并且可以给它们设置颜色、样式等。VGA 位于内存 `0xb8000` 处，每个字符占用 2 个字节，第一个字节是字符的 ASCII 码，第二个字节是字符的颜色样式。

因此，我们只需要向 VGA 内存中写入字符，就可以在屏幕上显示出来。例如：

[`boot/protected_mode/print.asm`](./boot/protected_mode/print.asm):

```asm
[bits 32]

; @param esi: 指向字符串的指针
print_32:
  pusha                       ; 保存寄存器状态
  mov edx, VGA_BASE_32        ; 设置显存地址

.print_loop_32:
  mov al, [esi]               ; 取出 bx 指向的数据
  mov ah, WHITE_ON_BLACK_32   ; 设置样式

  cmp al, 0                   ; 判断是否为字符串结尾
  je .print_done_32           ; 如果是，结束循环

  mov [edx], ax               ; 将 ax 中的数据写入显存
  
  add esi, 1                  ; 指向下一个字符
  add edx, 2                  ; 指向下一个字符的显存位置

  jmp .print_loop_32          ; 继续循环

.print_done_32:
  popa                        ; 恢复寄存器状态
  ret                         ; 返回
```

这个程序每次都会将字符串写到左上角，覆盖之前的字符串。其中，有一些常量，如 `VGA_BASE_32`、`WHITE_ON_BLACK_32` 等，可以在 `boot/boot.asm` 中定义它们：

```asm
VGA_BASE_32       equ 0x000b8000  ; VGA 显示内存地址
VGA_LIMIT_32      equ 80 * 25 * 2 ; VGA 显示内存地址限制
WHITE_ON_BLACK_32 equ 0x0f        ; 白色文本，黑色背景
```

但字符串互相叠着会很难看，我们可以再写一个清空屏幕的函数：

[`boot/protected_mode/print_clear.asm`](./boot/protected_mode/print_clear.asm)：

```asm
[bits 32]

print_clear_32:
  pusha

  mov ebx, VGA_LIMIT_32 ; 显示内存地址限制
  mov ecx, VGA_BASE_32 ; 设置显存地址
  mov edx, 0 ; 指向当前要写入的位置

.print_clear_loop_32:
  cmp edx, ecx ; 判断是否到达显示内存地址限制
  jge .print_clear_done_32 ; 如果是，结束循环

  push edx

  mov al, SPACE_CHAR_32 ; 设置空格字符
  mov ah, WHITE_ON_BLACK_32 ; 设置样式

  add edx, ecx ; 计算显示内存地址
  mov [edx], ax ; 将 ax 中的数据写入显存

  pop edx; 恢复 edx
  
  add edx, 2 ; 指向下一个字符的显存位置
  
  jmp .print_clear_loop_32 ; 继续循环

.print_clear_done_32:
  popa
  ret

SPACE_CHAR_32 equ 0x20 ; 空格字符
```

当然，现在的这个打印函数还很简陋。但不用管它，我们只需要它打印出必要信息即可。不久之后我们就能用上 C 语言了，没必要在它身上浪费精力。

现在的当务之急是，这个打印函数怎么运行它？

### GDT

答案是，运行这个 32 位的打印函数需要先进入 32 位保护模式。

在进入 32 位保护模式之前，我们需要先设置好全局描述符表（GDT, Global Descriptor Table）。GDT 是一个表格，里面存储了段的信息，每个段的信息构成一个 8 字节的段描述符（SD, Segment Descriptor）。段描述符包括：

- 32 位的段基址；
- 20 位的段长；
- 12 位的类型、特权级、段是否存在等信息。

不知道是哪个脑洞大开的人搞出来的，段描述符并不是依次排开的。比如，段基址和段长就被拆分成了好几部分放在段描述符的各个角落。下图就是一个段描述符的[结构](https://pdos.csail.mit.edu/6.828/2008/readings/i386/s06_03.htm)：

![SD 结构](./imgs/GDT.gif)

尽管我们可以定义很多段。由于在内核中定义段要方便得多，因此在这里，我们通常只需要定义两个段：一个用于代码，一个用于数据。

对于代码段，除了段基址和段长，这里面有一些 flags，包括：

- `Type`：
  - `A=0`：是否被访问过（用于 Debug 和虚拟内存）；
  - `R=1`：是否可读（`1` = 可以读取其中的常量，`0` = 只能执行）；
  - `C=0`：是否可以被更低特权级的代码段调用；
  - `1`：是否是代码段；
  - `1`：段类型（`0` = 系统段，`1` = 代码段或数据段）；
- `DPL=00`：描述符特权级（`00` = 最高特权级，`11` = 最低特权级）；
- `P=1`：段是否真实存在（`0` 用于虚拟内存）；
- `AVL=0`：自行定义的位；
- `L=0`：是否是 64 位代码段；
- `D=1`：默认操作数大小（`0` = 16 位，`1` = 32 位）；
- `G=1`：粒度（设置为 `1` 时会将基址左移 12 位，即将基址乘以 4KB）。

数据段和代码段几乎一样，只是 `Type` 有所不同：

- `Type`：
  - `A=0`：是否被访问过（用于 Debug 和虚拟内存）；
  - `W=1`：是否可写（`1` = 可以写入其中的数据，`0` = 只能读取）；
  - `E=0`：扩展方向（`1` = 向上，`0` = 向下）；
  - `0`：是否是代码段；
  - `1`：段类型（`0` = 系统段，`1` = 代码段或数据段）。

在写入段描述符之前，我们还需要设置 8 个字节的空描述符。这些描述符是为了让我们在忘记设置基址时，能够捕获到错误。

现在，我们可以照着上面的内容，写一个 GDT 了：

[`boot/real_mode/gdt.asm`](./boot/real_mode/gdt.asm)：

```asm
[bits 16]

gdt_start_32:
  dd 0x00000000 ; 空描述符（32 bit）
  dd 0x00000000 ; 空描述符（32 bit）

; 代码段
gdt_code_32: 
  dw 0xffff     ; 段长 00-15（16 bit）
  dw 0x0000     ; 段基址 00-15（16 bit）
  db 0x00       ; 段基址16-23（8 bit）
  db 0b10011010 ; flags（8 bit）
  db 0b11001111 ; flags（4 bit）+ 段长 16-19（4 bit）
  db 0x00       ; 段基址 24-31（8 bit）

; 数据段
gdt_data_32:
  dw 0xffff     ; 段长 00-15（16 bit）
  dw 0x0000     ; 段基址 00-15（16 bit）
  db 0x00       ; 段基址16-23（8 bit）
  db 0b10010010 ; flags（8 bit）
  db 0b11001111 ; flags（4 bit）+ 段长 16-19（4 bit）
  db 0x00       ; 段基址 24-31（8 bit）

gdt_end_32:

; GDT 描述符
gdt_descriptor_32:
  dw gdt_end_32 - gdt_start_32 - 1 ; 比真实长度少 1（16 bit）
  dd gdt_start_32                  ; 基址（32 bit）

; 常量
CODE_SEG_32 equ gdt_code_32 - gdt_start_32
DATA_SEG_32 equ gdt_data_32 - gdt_start_32
```

### 切换

现在，我们已经准备好从 16 位实模式切换到 32 位保护模式了。我们需要做的是：

1. 禁用中断。这是因为，BIOS 在 16 位实模式下的中断将不再适用于 32 位保护模式；
2. 使用 `lgdt` 指令加载 GDT；
3. 将 `cr0` 寄存器的第 0 位设置为 `1`，进入保护模式；
4. 刷掉 CPU 的管道队列，确保接下来不会再去执行实模式的指令。这可以通过执行一个长距离的 `jmp` 来实现。我们需要将 `cs` 设置为 GDT 的位置；
5. 更新所有段寄存器，让它们指向数据段；
6. 更新栈的位置。

根据以上流程，我们可以写出代码：

[`boot/real_mode/elevate.asm`](./boot/real_mode/elevate.asm)：

```asm
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
```

### 合体！

现在，我们可以将所有的代码合并到一起了。这里，我们选择将 32 位的代码放置在磁盘上一个单独的扇区，并在 16 位下通过已经实现的读取磁盘功能加载它：

`boot/boot.asm`：

```asm
[org 0x7c00]

; 16 位实模式
BEGIN_RM_16:
[bits 16]

  mov bp, 0x0500        ; 将栈指针移动到安全位置
  mov sp, bp            ; 使其向着 256 字节的 BIOS Data Area 增长

  mov [BOOT_DRIVE], dl

  mov bx, 0x7e00        ; 将数据存储在 512 字节的 Loaded Boot Sector
  mov cl, 0x02          ; 从第 2 个扇区开始
  mov dh, 1             ; 读取 1 个扇区
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

.boot_hold_32:
  jmp $

%include "protected_mode/print.asm"
%include "protected_mode/print_clear.asm"

VGA_BASE_32       equ 0x000b8000  ; VGA 显示内存地址
VGA_LIMIT_32      equ 80 * 25 * 2 ; VGA 显示内存地址限制
WHITE_ON_BLACK_32 equ 0x0f        ; 白色文本，黑色背景

MSG_PROT_MODE    db "Loaded 32-bit protected mode", 0

times 512 - ($ - BOOT_SECTOR_EXTENDED_32) db 0 ; 填充 0
```

编译运行可以得到：

![切换完成效果](./imgs/finish_protected.jpg)

如果你跟上了节奏的话，当前的文件夹应该是这样的：

```plaintext
MiniOS
└── boot
    ├── real_mode
    │   ├── disk.asm
    │   ├── elevate.asm
    │   ├── gdt.asm
    │   ├── print_hex.asm
    │   ├── print_nl.asm
    │   └── print.asm
    ├── protected_mode
    │   ├── print_clear.asm
    │   └── print.asm
    └── boot.asm
```

每次编译运行还是比较麻烦的，我们可以写两个 shell 来简化工作：

`boot/build.sh`：

```bash
#!/bin/bash

# 检查 nasm 是否已安装
if ! command -v nasm >/dev/null 2>&1; then
    echo "nasm could not be found, please install it first."
    exit 1
fi

# 检查源文件是否存在
if [ ! -f "boot.asm" ]; then
    echo "Source file boot.asm not found."
    exit 1
fi

# 创建输出目录（如果不存在）
mkdir -p dist

# 编译源文件
nasm -f bin boot.asm -o dist/boot.bin

# 检查编译是否成功
if [ $? -eq 0 ]; then
    echo "Compilation successful. Output file is located at dist/boot.bin"
else
    echo "Compilation failed."
    exit 1
fi
```

`debug.sh`：

```bash
#!/bin/bash

# 检查 qemu-system-x86_64 是否已安装
if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "qemu-system-x86_64 could not be found, please install it first."
    exit 1
fi

# 检查 dist/boot.bin 文件是否存在
if [ ! -f "dist/boot.bin" ]; then
    echo "Boot file dist/boot.bin not found, please run build.sh first."
    exit 1
fi

# 使用 qemu-system-x86_64 运行 dist/boot.bin
qemu-system-x86_64 -drive format=raw,file=dist/boot.bin

# 检查 qemu 是否成功启动
if [ $? -eq 0 ]; then
    echo "qemu-system-x86_64 successfully started the boot image."
else
    echo "Failed to start qemu-system-x86_64 with the boot image."
    exit 1
fi
```

之后，我们每次编写玩程序后，只需要在 `boot` 文件夹下运行 `sh build.sh` 编译，然后运行 `sh debug.sh` 运行即可。

## 64 位长模式

### 能用 64 位吗？

我们已经完成了从 16 位实模式到 32 位保护模式的切换。

如果你就是要编写 32 位操作系统的话，可以就此停下，对其进行完善，比如设置页表、实现中断等，然后开始写内核。

但我们的目标是，遥遥领先。因此，我们要继续完成从 32 位保护模式到 64 位长模式的切换。

> 我们这里只讨论 x86_64。而 IA-64 和 x86_64 差别巨大，我们暂不做讨论。

和之前的切换类似，64 位长模式相较于 32 位保护模式会带来如下变化：

- 64 位、且更多的寄存器。包括 8 个通用寄存器 `rax`、`rbx`、`rcx`、`rdx`、`rsi`、`rdi`、`rbp`、`rsp` 和 8 个 SSE 寄存器 `r8`、`r9`、`r10`、`r11`、`r12`、`r13`、`r14`、`r15`；
- 更大的地址空间。64 位长模式下，CPU 可以访问到 2^64 个字节的虚拟内存；物理地址空间也达到了 2^52 个字节；
- 不再支持分段，改为使用分页；
- 不再支持虚拟 8086 模式。如果需要运行 32 位或者 16 位的程序，需要在兼容模式下运行；
- CPU 将支持一些新的指令。

总体来说，切换到 64 位带来的好处是巨大的，可以让我们更好地利用硬件资源，提高程序的性能。

但是，从 32 位切换至 64 位相较于从 16 位切换到 32 位有很大不同。最先需要考虑的就是，部分 CPU 不支持 64 位长模式，在切换前需要检查支持情况。只有支持 64 位的 CPU 才能进入 64 位长模式。

检查支持情况可以直接通过 [`CPUID`](https://www.scss.tcd.ie/jeremy.jones/CS4021/processor-identification-cpuid-instruction-note.pdf) 来实现。`CPUID` 是 x86 架构下的用于查询 CPU 具体信息的指令，可以获取到 CPU 的制造商、型号、指令集、功能特性等。对于完全支持 `CPUID` 的 CPU，这个指令可以接收这些参数值：

- 基础功能：
  - `0`：获取厂商标识符；
  - `1`：获取CPU型号、系列号、步进和特性信息；
  - `2`：获取高级处理器缓存描述符；
  - `3`：获取处理器序列号；
  - `4`：获取确定处理器类型的确定位；
- 扩展功能：
  - `0x80000000`：获取最大扩展参数值和厂商标识符；
  - `0x80000001`：获取扩展处理器信息和特性位；
  - `0x80000002`-`0x80000004`：获取处理器品牌字符串。

表明 CPU 是否支持 64 位长模式的标志位就可以用参数 `0x80000001` 获取得到。然而，有一些 CPU 并不支持扩展功能；更有些 CPU 直接不支持 `CPUID` 指令！

于是，我们为了检查 CPU 对 64 位长模式的支持情况，需要逐项检查：

1. 检查 CPU 是否支持 `CPUID` 指令；

  标志位寄存器的第 21 位表明了 CPU 是否支持 `CPUID` 指令。如果支持，则其*必须*为 `1`，否则可以为任意值。我们可以修改这一位，然后观察它是否会被自动该回去。如果被改回去了，就说明 CPU 支持 `CPUID` 指令。

2. 检查 `CPUID` 指令是否支持扩展功能；

  `CPUID` 指令的最大参数值可以通过参数 `0x80000000` 获取。如果支持扩展功能，那么最大参数值应该大于等于 `0x80000001`。

3. 使用 `CPUID` 指令的扩展功能检查是否支持 64 位长模式。

  如果支持 64 位长模式，那么 `CPUID` 指令的参数 `0x80000001` 的第 29 位应该为 `1`。

我们依据以上步骤，可以写出检查 CPU 是否支持 64 位长模式的代码：

[`boot/protected_mode/check_elevate.asm`](./boot/protected_mode/check_elevate.asm)：

```asm
[bits 32]

; @depends print.asm
; @depends print_clear.asm
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

  popa                 ; 恢复寄存器状态
  ret

.no_cpuid_32:
  call print_clear_32
  mov esi, NO_CPUID_MSG_32
  call print_32
  jmp $

.no_cpuid_extend_function_32:
  call print_clear_32
  mov esi, NO_EXTEND_MSG_32
  call print_32
  jmp $

.no_lm_32:
  call print_clear_32
  mov esi, NO_LM_MSG_32
  call print_32
  jmp $

NO_CPUID_MSG_32  db "[ERR] CPUID not supported",   0
NO_EXTEND_MSG_32 db "[ERR] Extended functions not supported", 0
NO_LM_MSG_32     db "[ERR] Long mode not supported",           0
```

### 页表

页表是一种数据结构，用于将虚拟地址映射到物理地址。你可以把页表理解为之前用过的段寄存器的升级版。它可以更加高效地管理内存，提高内存的利用率，同时支持虚拟内存、内存保护等功能。但在这里，bootloader 的职责只是建立起一个最基本的页表，以便能够加载和运行内核。在内核加载完后，就会将页表移交给内核了。

页表由 4 层组成：

- `PML4`（Page Map Level 4）：最顶层的页表，用于将虚拟地址映射到 `PDPT`；
- `PDPT`（Page Directory Pointer Table）：第二层的页表，用于将虚拟地址映射到 `PD`；
- `PD`（Page Directory）：第三层的页表，用于将虚拟地址映射到 `PT`；
- `PT`（Page Table）：最底层的页表，用于将虚拟地址映射到物理地址。

> 有些还支持更高层级的页表 `PML5`。但是，页表层数越多，寻址越慢，普通的操作系统一般不会使用。

每层页表都有 512 个项，每个项占用 8 字节。由于 `PT` 的每个项可以映射 4KB 的内存，因此，理论上整个页表可以处理 48 位虚拟寻址、映射 512 \* 512 \* 512 \* 4KB = 256TB 的内存。

> 你也许会问，反正是 52 位的地址总线，为什么不直接寻址 53 位的物理内存呢？
>
> 通常来讲，页表处理的内存量不会达到最大值，因为页表还有一个更重要的作用：内存保护。通过页表，我们可以将一部分内存设置为只读、只执行、不可访问等，从而保护内存不被恶意程序破坏。页表最大的意义也在于此。

页表每项的结构如下：

![页表项结构](./imgs/pt.png)

初始化页表的步骤如下：

1. 初始化页表前，我们需要在 `cr3` 寄存器中记录页表起始位置，并清理页表所需的内存以防发生错误。
2. 初始化页表时，对于较高级的 `PML4`、`PDPT`、`PD`，我们只需要给它建立唯一的一个表项即可。这个表项的内容是指向下一级页表的地址，标志位只有最后两位为 `1`——也就是存在位和可写位。对于其它标志位，我们可以设置为 `0`。
3. 对于 `PT` 就不能这样做了，因为我们需要访问到所有内存，因此需要它建立尽可能多的表项。这样，对于每个物理地址，我们才都能映射到。
4. 初始化页表之后，还需要设置 PAE 标志位。PAE（Physical Address Extension）是一种扩展的物理地址，可以将物理地址扩展到 36 位，从而支持 64 位长模式。我们只需要将 `cr4` 寄存器的第 5 位置 `1` 即可。

接下来，我们可以写出初始化页表的代码：

[`boot/protected_mode/init_pt.asm`](./boot/protected_mode/init_pt.asm)：

```asm
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
```

### Another GDT

尽管我们之前讲过，在 64 位长模式下不再使用分段，但是，我们还是需要设置 GDT。这是因为，GDT 里面还有一些和位数有关的标志位，我们需要调整它们。

在 64 位长模式下，GDT 的结构和 32 位保护模式下的一样。但是，64 位长模式下，GDT 的基址和限制都会被忽略，所有的段都会覆盖整个内存。此外，我们还需要调整一下和位数有关的标志位。代码如下：

[`boot/protected_mode/gdt.asm`](./boot/protected_mode/gdt.asm)：

```asm
[bits 32]
align 4

gdt_start_64:
  dd 0x00000000 ; 空描述符（32 bit）
  dd 0x00000000 ; 空描述符（32 bit）

; 代码段
gdt_code_64: 
  dw 0xffff     ; 段长 00-15（16 bit）
  dw 0x0000     ; 段基址 00-15（16 bit）
  db 0x00       ; 段基址16-23（8 bit）
  db 0b10011010 ; flags（8 bit）
  db 0b10101111 ; flags（4 bit）+ 段长 16-19（4 bit）
  db 0x00       ; 段基址 24-31（8 bit）

; 数据段
gdt_data_64:
  dw 0x0000     ; 段长 00-15（16 bit）
  dw 0x0000     ; 段基址 00-15（16 bit）
  db 0x00       ; 段基址16-23（8 bit）
  db 0b10010010 ; flags（8 bit）
  db 0b10100000 ; flags（4 bit）+ 段长 16-19（4 bit）
  db 0x00       ; 段基址 24-31（8 bit）

gdt_end_64:

; GDT 描述符
gdt_descriptor_64:
  dw gdt_end_64 - gdt_start_64 - 1 ; 比真实长度少 1（16 bit）
  dd gdt_start_64                  ; 基址（32 bit）

; 常量
CODE_SEG_64 equ gdt_code_64 - gdt_start_64
DATA_SEG_64 equ gdt_data_64 - gdt_start_64
```

### 切换

现在，我们已经准备好从 32 位保护模式切换到 64 位长模式了。我们需要做的是：

1. 将 `IA32_EFER` 的第 8 位置 `1`：

  `IA32_EFER` 是一个 MSR（Model Specific Register），地址为 `0xc0000080`，用于控制 CPU 的一些特性。第 8 位是 `LME`（Long Mode Enable）位，用于控制是否启用 64 位长模式。读取和写入 MSR 需要使用 `rdmsr` 和 `wrmsr` 指令；

2. 将 `CR0` 寄存器的第 31 位置 `1`：
  
  这个位是 `PG`（Paging）位，用于启用分页机制。在 64 位长模式下，分页是必须的；

3. 加载 GDT；

4. 刷掉 CPU 的管道队列，这和之前的切换一样，需要执行一个长距离的 `jmp`；

5. 禁用中断；

6. 更新所有段寄存器，让它们指向数据段。

接下来，我们可以写出切换到 64 位长模式的代码：

[`boot/protected_mode/elevate.asm`](./boot/protected_mode/elevate.asm)：

```asm
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
```

### 合体！

在 64 位长模式下，我们同样去实现一下打印函数玩玩。和之前的区别在于，64 位长模式下，我们的寄存器需要使用 64 位的寄存器。此外，64 位下不再有 `pusha` 和 `popa` 指令，我们需要手动保存和恢复寄存器。代码如下：

[`boot/long_mode/print.asm`](./boot/long_mode/print.asm)：

```asm
[bits 64]

; @param rdi: 打印样式
; @param rsi: 指向字符串的指针
print_64:
  push rdi                       ; 保存 rdi 寄存器状态
  push rsi                       ; 保存 rsi 寄存器状态
  push rax                       ; 保存 rax 寄存器状态
  push rdx                       ; 保存 rdx 寄存器状态

  mov rdx, VGA_BASE_64           ; 设置显存地址

  shl rdi, 8                     ; 将打印样式左移 8 位

.print_loop_64:
  cmp byte[rsi], 0               ; 判断是否为字符串结尾
  je .print_done_64              ; 如果是，结束循环

  cmp rdx, VGA_BASE_64 + VGA_LIMIT_64 ; 判断是否到达显示内存地址限制
  je .print_done_64              ; 如果是，结束循环

  mov rax, rdi                   ; 设置样式
  mov al, byte[rsi]              ; 取出 rsi 指向的数据

  mov word[rdx], ax              ; 将 ax 中的数据写入显存
  
  add rsi, 1                     ; 指向下一个字符
  add rdx, 2                     ; 指向下一个字符的显存位置

  jmp .print_loop_64             ; 继续循环

.print_done_64:
  pop rdx                        ; 恢复 rdx 寄存器状态
  pop rax                        ; 恢复 rax 寄存器状态
  pop rsi                        ; 恢复 rsi 寄存器状态
  pop rdi                        ; 恢复 rdi 寄存器状态
  ret                            ; 返回
```

[`boot/long_mode/print_clear.asm`](./boot/long_mode/print_clear.asm)：

```asm
[bits 64]

; @param rdi: 打印样式
print_clear_64:
  push rdi                       ; 保存 rdi 寄存器状态
  push rax                       ; 保存 rax 寄存器状态
  push rdx                       ; 保存 rdx 寄存器状态

  shl rdi, 8 ; 将打印样式左移 8 位
  mov rax, rdi ; 设置样式

  mov al, SPACE_CHAR_64 ; 设置空格字符

  mov rdi, VGA_BASE_64 ; 设置显存地址
  mov rcx, VGA_LIMIT_64 / 2 ; 显示内存地址限制

  rep stosw ; 将 ax 中的数据写入显存

  pop rdx                        ; 恢复 rdx 寄存器状态
  pop rax                        ; 恢复 rax 寄存器状态
  pop rdi                        ; 恢复 rdi 寄存器状态
  ret

SPACE_CHAR_64 equ 0x20 ; 空格字符
```

[`boot/boot.asm`](./boot/boot.asm)：

```asm
[org 0x7c00]

jmp BEGIN_RM_16

KERNEL_SIZE db 0 ; 内核大小

; 16 位实模式
BEGIN_RM_16:
[bits 16]

  mov bp, 0x0500        ; 将栈指针移动到安全位置
  mov sp, bp            ; 使其向着 256 字节的 BIOS Data Area 增长

  mov [BOOT_DRIVE], dl

  mov bx, 0x7e00        ; 将数据存储在 512 字节的 Loaded Boot Sector
  mov cl, 0x02          ; 从第 2 个扇区开始
  mov dh, [KERNEL_SIZE] ; 读取 n 个扇区
  add dh, 2             ; 加上 2 个扇区
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

.boot_hold_64:
  jmp $

%include "long_mode/print.asm"
%include "long_mode/print_clear.asm"

VGA_BASE_64       equ 0x000b8000  ; VGA 显示内存地址
VGA_LIMIT_64      equ 80 * 25 * 2 ; VGA 显示内存地址限制
WHITE_ON_BLUE_64  equ 0x1f        ; 白色文本，蓝色背景

MSG_LONG_MODE db "Jumped to 64-bit long mode", 0

times 512 - ($ - BOOT_SECTOR_EXTENDED_64) db 0 ; 填充 0
```

现在编译运行，你应该可以看到：

![64 位长模式结果](./imgs/finish_long.jpg)

## 内核，启动！

### 文件组织

现在，终于可以加载内核了。在开始之前，我觉得有必要先向 Linux 学习一下如何组织源码目录，否则后期代码和功能变多后再去重构就很麻烦了。

写本文时，Linux stable 版本为 6.9.7，其[源码](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/?h=v6.9.7)结构如下：

```plaintext
linux
├── arch
├── block
├── certs
├── crypto
├── Documentation
├── drivers
├── fs
├── include
├── init
├── io_uring
├── ipc
├── kernel
├── lib
├── mm
├── net
├── rust
├── samples
├── scripts
├── security
├── sound
├── tools
├── usr
├── virt
└── Makefile
```

这也太复杂了，我们的内核暂时（也大概率是永远）不会有这么多功能，我们只需要保留必要的内容。我们可以参考 Linux 0.12 的[源码](https://github.com/Original-Linux/Linux-0.12)组织结构：

```plaintext
linux-0.12
├── boot     // bootloader，我们已经写好了
├── fs       // 文件系统
├── include  // 头文件
├── init     // 初始化
├── kernel   // 内核
├── lib      // 库
├── mm       // 内存管理
├── tools    // 工具
└── Makefile // 编译文件
```

我推荐你先自己翻一翻目录，看看都有些什么内容，然后我们就可以开始编写自己的内核了。