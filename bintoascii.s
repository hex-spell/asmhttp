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
#	- RAX: uint32 number to convert
#	- RSI: char* destination
#	- RDX: max length
# - output registers:
#	- RAX: size of the resulting string (with null terminator)
# look https://stackoverflow.com/questions/8021772/assembly-language-how-to-do-modulo for modulo of 10 operation
#---------------------------------------------
decimal_to_ascii:
    #mov $1234, %eax          # dividend low half
    #mov $0, %edx            # dividend high half = 0.  prefer  xor edx,edx
    #mov $10, %ebx            # divisor can be any register or memory
    #div %ebx       # Divides 1234 by 10.
        # EDX =   4 = 1234 % 10  remainder
        # EAX = 123 = 1234 / 10  quotient
    #mov %eax, quotient
    #mov %edx, remainder
    #ret

   #loop:
   #---modulo of 10
   #---dividend minus result
   #---save result + 48 (0 in ascii) as single byte in the destination
   #---compare dividend and 10
   #---if greater jump to loop
    mov $0, %r8
    mov %rdx, %r9
    mov $0, %rdx #clear higher bytes
    mov $0, %rbx #||
    mov $10, %ebx            # divisor can be any register or memory
decimal_to_ascii_loop:
    mov $0, %edx            # dividend high half = 0.  prefer  xor edx,edx
    div %ebx       # Divides 1234 by 10.
        # EDX =   4 = 1234 % 10  remainder
        # EAX = 123 = 1234 / 10  quotient
    add $48, %edx
    push %rdx
    add $1, %r8
    cmp %r8, %r9
    jle decimal_to_ascii_copy_loop
    cmp $0, %eax
    jnz decimal_to_ascii_loop
decimal_to_ascii_copy_loop:
    mov %r8, %rdx #save the string length
decimal_to_ascii_copy_loop_begin:
    #this segfaults
    pop %rax
    movb %al, (%rsi)
    add $1, %rsi
    sub $1, %r8
    cmp $0, %r8
    jle decimal_to_ascii_copy_loop
    mov %rdx, %rax
    ret
    
.bss
.lcomm string_destination, 1000
.text

.globl _start
_start:
    write $1, $message, $14 
    mov $1234, %eax          # dividend low half
    mov $string_destination, %rsi
    mov $10, %rdx
    call decimal_to_ascii

    movq $60, %rax # exit(0)
    movq $0, %rdi
    syscall
