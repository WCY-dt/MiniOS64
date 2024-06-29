# MiniOS

我推荐你用 Linux。因为不管你用什么，反正我是用 Linux。

先安装好 nasm 和 qemu：

```bash
sudo apt-get install nasm qemu
```

你要是心情好的话，也可以再安装一下 xxd：

```bash
sudo apt-get install xxd
```

## 系统，启动！

### 引导扇区

![擦电开机](./imgs/擦电开机.jpg)

擦电！开机！

此时计算机一片混沌，BIOS (Basic Input/Output System) 开天辟地。

> 当然，新的计算机都使用 UEFI（Unified Extensible Firmware Interface）了。但我们暂时先考虑更简单的 BIOS。

此时的计算机连文件系统都没有！也就是说，我们甚至无法告诉 BIOS 从哪里加载操作系统到内存。于是，有人规定了，操作系统应当放在存储设备最开始的 512 字节（例如磁盘第 0 柱面第 0 磁头第 0 扇区）。这个区域就是我们的`引导扇区`。也就是说，操纵系统运行的第一行代码就是在引导扇区中。

然而，一台计算机可能有多个存储设备，BIOS 依然不知道哪个设备存储了引导扇区。但不知道谁又规定了，引导扇区的最后两个字节必须是 `0xaa55`。于是，BIOS 只需要遍历所有存储设备，检查他们的第 511 和 512 字节是否是 `0xaa55`。如果是，就说明找到了操作系统的位置，把这一段数据加载到内存中，然后跳转到这段代码的第一个字节开始执行。

因此，对于手动编写一个引导扇区来说，只需要：

1. 首先把最后两个字节设置为 `0xaa55`；
2. 然后从第一个字节开始写上想要的代码；
3. 最后把其它的字节填充为 `0`，补满 512 字节。

我们暂时先写一个死循环：

```asm
; $ 表示当前地址
; 跳转到当前地址就是死循环
jmp $

; $ 表示当前地址，$$ 表示当前段的开始地址
; 510-($-$$) 计算出当前位置到 510 字节的距离，然后全部填充为 0
times 510-($-$$) db 0

; 最后两个字节是 0xaa55
dw 0xaa55
```

将文件命名为 `boot_sect.asm`，然后编译为二进制文件：

```bash
nasm boot_sect.asm -f bin -o boot_sect.bin
```

再使用 QEMU 运行：

```bash
qemu-system-x86_64 boot_sect.bin
```

你会看到窗口中显示 `Booting from Hard Disk...`，然后它就开始执行我们的死循环了。

![QEMU 进入死循环](./imgs/qemu.jpg)

你也可以用下面的命令看看我们的 bin 文件内容是否如我们所想：

```bash
xxd boot_sect.bin
```

### `Hello, World!`

死循环没什么意思，我们来尝试输出一句 `Hello, World!`。同样的，先写程序，然后将最后两位设置为 `0xaa55`，再把其它的字节填充为 `0`。

问题来了，如何在汇编中打印字符？首先，我们要设置要打印哪个字符。我们只需要将字符存储在 `ax` 寄存器的低 8 位（也就是 `al` 寄存器），然后调用 `int 0x10` 中断执行打印即可。

> 对于此时的 x86 CPU 来讲，一共有 4 个 16 位通用寄存器，包括 `ax`、`bx`、`cx` 和 `dx`。有时候我们只需要使用 8 位，因此每个 16 位寄存器可以拆为两个 8 位寄存器，例如 `al` 和 `ah`。

> 什么是中断？简单来讲就是给 CPU 正在做的事情按下暂停，然后去执行我们指定的任务。中断可以执行的任务被存储在内存最开始的区域，这个区域像一张表格（中断向量表），每个单元格指向一段指令的地址，也就是 ISR（interrupt service routines）。
>
> 为了方便在汇编中调用，BIOS 给这些中断分配了号码。例如，`int 0x10` 就是第 16 个中断，它指向了一个打印字符的 ISR。

然而 `int 0x10` 中断只知道要打印，但并不知道要怎么打印。我们这里将其设置为 TTY（TeleTYpe）模式，让它接收字符并显示在屏幕上，然后将光标向后移动。设置 TTY 模式的方法是将 `ah` 寄存器设置为 `0x0e`，你可以理解为传给系统中断的参数。

于是我们修改刚刚的代码：

```asm
  ; 设置 TTY 模式
  mov ah, 0x0e

  ; 设置要打印的字符
  mov al, 'H'
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

  ; 打印完成后死循环
  jmp $

  ; 填充 0
  times 510-($-$$) db 0

  ; 最后两个字节是 0xaa55
  dw 0xaa55
```

现在，再次编译运行，便可以看到 `Hello, World!` 了。

我推荐你用 `xxd boot_sect.bin` 来查看编译后的二进制文件，看看这些汇编指令在二进制中到底是啥样的。

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

在汇编中，我们定义的数据都存储的相对地址。为了访问它们，我们需要将这些相对地址转换为绝对地址——也就是加上 `0x7c00`。例如：

```asm
  mov ah, 0x0e

  mov bx, my_data ; 将 my_data 的相对地址存储到 bx 中
  add bx, 0x7c00  ; 将 bx 加上 0x7c00，得到 my_data 的绝对地址
  mov al, [bx]    ; 从 my_data 的绝对地址读取数据放入 al 中
  int 0x10        ; 打印 al 中的数据

  jmp $

my_data:
  db 'X'        ; db 表示 declare bytes

  times 510-($-$$) db 0
  dw 0xaa55
```

但是，每次都要加上 `0x7c00` 太麻烦了，我们可以使用 `org` 指令来设置全局偏移量（当前段的基地址）：

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

### Yet Another `Hello, World!`

我大胆假设一下，你的汇编水平和我卧龙凤雏。所以我不打算介绍基础的汇编知识了，直接上代码。

我们可以将 `Hello, World!` 存储在内存中，然后通过循环打印出来：

`boot_sect.asm`:

```asm
[org 0x7c00]

  mov bx, HELLO_MSG ; 放入参数地址
  call print        ; 调用打印函数

  jmp $

%include "boot_sect_print.asm"

HELLO_MSG:
  db 'Hello, World!', 0

  times 510-($-$$) db 0
  dw 0xaa55
```

`boot_sect_print.asm`:

```asm
; 参数在 bx 中
print:
  pusha           ; 保存寄存器状态

  mov ah, 0x0e    ; 设置 TTY 模式

.print_loop:
  mov al, [bx]    ; 取出 bx 指向的数据
  cmp al, 0       ; 判断是否为字符串结尾
  je .print_done  ; 如果是，结束循环

  int 0x10        ; 打印 al 中的数据
  inc bx          ; 指向下一个字符
  jmp .print_loop ; 继续循环

.print_done:
  popa            ; 恢复寄存器状态
  ret             ; 返回
```

编译运行，你会看到 `Hello, World!` 被打印在屏幕上。

很好，你已经精通汇编了。接下来，我们要用类似的控制流、函数调用等概念，来实现更多的功能。

### 打印 16 进制

别急，我们依然还没有做好读取磁盘的准备。

为了编写这种过于底层的程序，我们需要一些调试工具。但是，gdb 显然太过城市化了。我们将会使用最原始的打印的方法来调试我们的程序。

上一节中，我们已经实现了一个打印字符串的函数。现在，我们再来实现一个打印 16 进制的函数。

`boot_sect.asm`:

```asm
[org 0x7c00]

  mov bx, HELLO_MSG ; 放入参数地址
  call print        ; 调用打印函数

  call print_nl     ; 调用打印换行函数

  mov dx, 0x1f6b    ; 放入参数
  call print_hex    ; 调用打印 16 进制函数

  jmp $

%include "boot_sect_print.asm"
%include "boot_sect_print_hex.asm"

HELLO_MSG:
  db 'Hello, World!', 0

  times 510-($-$$) db 0
  dw 0xaa55
```

`boot_sect_print_hex.asm`:

```asm
; 依赖于 boot_sect_print.asm
; 参数在 dx 中
print_hex:
  pusha               ; 保存寄存器状态
  
  mov cx, 5           ; 首先设置 HEX_OUT 的最后一位

.print_hex_loop:
  cmp cx, 1           ; 判断是否到达 HEX_OUT 的第一位 (x)
  je .print_hex_done  ; 如果是，结束循环

  mov ax, dx          ; 将 dx 中的数据放入 ax
  and ax, 0xf         ; 取出 ax 的最后一位

  mov bx, HEX_DIGITS  ; 取出 HEX_DIGITS 的地址
  add bx, ax          ; 计算出对应的字符的地址
  mov al, [bx]        ; 取出对应的字符

  mov bx, HEX_OUT     ; 取出 HEX_OUT 的地址
  add bx, cx          ; 计算出要写入的位置
  mov [bx], al        ; 将字符写入 HEX_OUT

  shr dx, 4           ; 将 dx 右移 4 位
  dec cx              ; 准备处理下一位
  jmp .print_hex_loop ; 继续循环

.print_hex_done:
  mov bx, HEX_OUT
  call print          ; 调用打印函数

  popa                ; 恢复寄存器状态
  ret                 ; 返回
  
HEX_DIGITS:
  db '0123456789ABCDEF'

HEX_OUT:
  db '0x0000', 0
```

同时，在 `sect_boot_print.asm` 中添加打印换行函数：

```asm
print_nl:
  pusha        ; 保存寄存器状态
  
  mov ah, 0x0e ; 设置 TTY 模式

  mov al, 0x0a ; 换行符
  int 0x10     ; 打印换行符
  mov al, 0x0d ; 回车符
  int 0x10     ; 打印回车符
  
  popa         ; 恢复寄存器状态
  ret          ; 返回
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

`boot_sect.asm`:

```asm
[org 0x7c00]
  mov [BOOT_DRIVE], dl   ; 保存启动驱动器号

  mov bp, 0x8000         ; 将栈指针移动到安全位置
  mov sp, bp

  mov bx, 0x9000         ; 存储数据的位置在 [es:bx] 中，其中 es = 0x0000
  mov dh, 0x04           ; 读取 4 个扇区 (0x01 .. 0x80)
  mov dl, [BOOT_DRIVE]   ; 0 = floppy, 1 = floppy2, 0x80 = hdd, 0x81 = hdd2
  call disk_load

  mov dx, [0x9000]       ; 扇区 2 磁道 0 磁头 0 的第一个字
  call print_hex

  call print_nl

  mov dx, [0x9000 + 1536] ; 扇区 5 磁道 0 磁头 0 的第一个字
  call print_hex

  jmp $

%include "boot_sect_print.asm"
%include "boot_sect_print_hex.asm"
%include "boot_sect_disk.asm"

  BOOT_DRIVE: db 0

  times 510 - ($-$$) db 0
  dw 0xaa55

  times 256 dw 0xdead ; 扇区 2 磁道 0 磁头 0
  times 256 dw 0xbeaf ; 扇区 3 磁道 0 磁头 0
  times 256 dw 0xface ; 扇区 4 磁道 0 磁头 0
  times 256 dw 0xbabe ; 扇区 5 磁道 0 磁头 0
```

`boot_sect_disk.asm`:

```asm
; bx 存储数据要保存的位置
; dh 存储要读取的扇区数
; dl 存储要读取的驱动器号
disk_load:
  push dx         ; 保存要读取的扇区数

  mov ah, 0x02    ; 表明是读取

  mov al, dh      ; 要读取的扇区数
  mov dh, 0x00    ; 从第 0 个磁头 (0x0 .. 0xF) 开始
  mov ch, 0x00    ; 从第 0 个磁道 (0x0 .. 0x3FF, 其中最高两位在 cl 中) 开始
  mov cl, 0x02    ; 从第 2 个扇区 (0x01 .. 0x11) 开始
  
  int 0x13        ; BIOS 磁盘服务中断
  jc .disk_error  ; 如果读取失败，跳转

  pop dx          ; 要读取的扇区数
  cmp dh, al      ; 检查读取的扇区数是否正确
  jne .disk_error ; 如果不正确，跳转

  ret

.disk_error:
  mov bx, DISK_ERROR_MSG
  call print
  jmp $

DISK_ERROR_MSG: db "[ERR] Disk read error", 0
```

编译运行后，你会看到 `0xdead` 和 `0xbabe` 被打印在屏幕上。

## 32 位保护模式

### 16 位实模式

计算机是充满妥协的，当你设计出一个新东西的时候，总是要考虑向下兼容。

对于刚开始启动的计算机来讲，当然不知道操作系统是多少位的。为了兼容，它只能先进入一个 16 位的模式——`16 位实模式`。实模式是 Intel 8086 处理器的一种工作模式，在实模式下，CPU 只能访问 1MB 的内存，而且只能使用 16 位的寄存器。

我们刚刚就一直在实模式下工作。但是，实模式有着很多缺点。因此，我们在实模式下读取到一些硬盘数据后，便可以顺势进入 `32 位保护模式`，享受到更大的内存、更多更大的寄存器、更丰富的功能。具体来讲有以下几点：

- 寄存器全部变为 32 位，我们向之前的寄存器名称前添加 `e` 来表明这一点，例如 `eax`、`ebx`；
- 增加了 2 个新的段寄存器 `fs` 和 `gs`；
- 内存偏移增加至 32 位，因此我们可以访问到 4 GB 的内存；
- 支持了虚拟内存、内存保护等功能。
