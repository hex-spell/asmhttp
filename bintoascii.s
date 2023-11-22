.data
message: .string "hello world!\n\0"
binary: .int 4848
.bss

.text
.macro write fd, buf, len
    movq $1, %rax #sys_write
    movq \fd, %rdi #std out (fd 1)
    movq \buf, %rsi #initial char ptr
    movq \len, %rdx #count of chars to print
    syscall
.endm

#---------------------------------------------
# - decimal_to_ascii 
# - input registers:
#	- RDI: int
#	- RSI: char* destination
#	- RDX: max length
# - output registers:
#	- RAX: size of the resulting string (with null terminator)
# look https://stackoverflow.com/questions/8021772/assembly-language-how-to-do-modulo for modulo of 10 operation
#---------------------------------------------
strcopy_multi:
   #loop:
   #---compare dividend < 10
   #---if less jump out of loop
   #---modulo of 10
   #---dividend minus result
   #---save result + 48 (0 in ascii) as single byte in the destination
   #---goto loop

.globl _start
_start:
    write $1, $message, $14 

    movq $60, %rax # exit(0)
    movq $0, %rdi
    syscall
