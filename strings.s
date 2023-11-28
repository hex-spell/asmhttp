#---------------------------------------------
# x86 calling convention volatile args: RDI, RSI, RDX, RCX, R8, R9
#---------------------------------------------
# - strcomp - string compare
# - input registers:
#	- RDI: char* 1
#	- RSI: char* 2
#	- RDX: string length limit (in bytes)
#	    -	I use this value as a backwards counter for a loop
# - output registers:
#	- RAX:
#	    = 1 -> strings are equal
#	    = 0 -> strings are not equal
# - used volatile registers:
#	- RCX: to dereference char*1 before compare
#	- R8: to dereference char*2 before compare
#---------------------------------------------
strcomp:
    cmp $0, %rdx
    jz strcomp_eq
    movq (%rdi), %rcx
    movq (%rsi), %r8
    cmp %cl, %r8b #byte 0 of rcx and r8 respectively
    jnz strcomp_neq
    add $1, %rdi
    add $1, %rsi
    sub $1, %rdx
    jmp strcomp
strcomp_neq:
    movq $0, %rax
    ret
strcomp_eq:
    movq $1, %rax
    ret

#---------------------------------------------
#---------------------------------------------
# - charseek - seek char pos in string
# - input registers:
#	- RDI: char* (string)
#	- RSI: char (character to seek)
#	- RDX: int (maxlenth)
# - output registers:
#	- RAX: int64, char position relative to string mem location
#		or size of the substring created from the beginning of the string
#		to the char found
#	#TODO: stop using RDI for output, and use memory and pointers instead
#	the x86 calling convention says that I should use RAX as the only
#	register for output
#
#	- RDI: char*, memory location for that character
# - protip: you can call this multiple times and it will keep seeking past the first hit (if you don't change rsi)
#---------------------------------------------
charseek:
    movq $0, %rax
charseek_loop:
    cmp $0, %rdx
    jz charseek_not_found
    movq (%rdi), %rcx
    cmp %cl, %sil #byte 0 of rcx and rsi respectively
    jz charseek_found
    add $1, %rdi
    add $1, %rax #counting chars
    sub $1, %rdx
    jmp charseek_loop
charseek_not_found:
    movq $-1, %rax
    ret
charseek_found:
    ret

#---------------------------------------------
# - strcopy - (address to address)
# - input registers:
#	- RDI: char* origin (null terminated)
#	- RSI: char* destination
#	- RDX: int64 (maxlenth)
# - output registers:
#	- RAX: size of the resulting string (with null terminator)
# - used volatile registers:
#	- RCX: used to dereference origin char before moving it to destination
#---------------------------------------------
strcopy:
    movq $0, %rax
strcopy_loop:
    movq (%rdi), %rcx
    movq %rcx, (%rsi)
    cmp $0, %cl #byte 0 of rcx is null (null terminator)
    jz strcopy_finish
    add $1, %rdi
    add $1, %rsi
    add $1, %rax #counting chars
    sub $1, %rdx
    cmp $0, %rdx
    jnz strcopy_loop
strcopy_finish:
    #-- add null terminator --
    movb $0x00, (%rsi)
    add $1, %rsi
    add $1, %rax
    ret

#---------------------------------------------
# - strcopy_raw - (address to address)
# - input registers:
#	- RDI: char* origin (null terminated)
#	- RSI: char* destination
#	- RDX: int64 (maxlenth)
# - output registers:
#	- RAX: size of the resulting string (with null terminator)
# - used volatile registers:
#	- RCX: used to dereference origin char before moving it to destination
#---------------------------------------------
strcopy_raw:
    movq $0, %rax
strcopy_raw_loop:
    movq (%rdi), %rcx
    movq %rcx, (%rsi)
    cmp $0, %cl #byte 0 of rcx is null (null terminator)
    jz strcopy_raw_finish
    add $1, %rdi
    add $1, %rsi
    add $1, %rax #counting chars
    sub $1, %rdx
    cmp $0, %rdx
    jnz strcopy_raw_loop
strcopy_raw_finish:
    ret

#---------------------------------------------
# - strcopy_multi - (address to two addresses)
# - input registers:
#	- RDI: char* origin (null terminated)
#	- RSI: char* destination
#	- RDX: char* destination 2
#	- RCX: int64 (maxlenth)
# - output registers:
#	- RAX: size of the resulting string (with null terminator)
# - used volatile registers:
#	- R8: used to dereference origin char before moving it to destination
#---------------------------------------------
strcopy_multi:
    movq $0, %rax
strcopy_multi_loop:
    movq (%rdi), %rcx
    movq %rcx, (%rsi)
    movq %rcx, (%rdx)
    cmp $0, %cl #byte 0 of rcx is null (null terminator)
    jz strcopy_multi_finish
    add $1, %rdi
    add $1, %rsi
    add $1, %rdx
    add $1, %rax #counting chars
    sub $1, %r8
    cmp $0, %r8
    jnz strcopy_multi_loop
strcopy_multi_finish:
    #-- add null terminator --
    movb $0x00, (%rsi)
    movb $0x00, (%rdx)
    add $1, %rsi
    add $1, %rdx
    add $1, %rax
    ret

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
    mov $0, %r8
    mov %rdx, %r9
    mov $0, %rdx #clear higher bytes
    mov $0, %rbx #||
    mov $10, %ebx            # divisor can be any register or memory
decimal_to_ascii_loop:
    xor %edx, %edx            # dividend high half = 0.  prefer  xor edx,edx
    div %ebx
    add $48, %edx
    push %rdx
    add $1, %r8
    cmp %r8, %r9
    jz decimal_to_ascii_copy_loop
    cmp $0, %eax
    jnz decimal_to_ascii_loop
decimal_to_ascii_copy_loop:
    mov %r8, %rdx #save the string length
decimal_to_ascii_copy_loop_begin:
    cmp $0, %r8
    jle decimal_to_ascii_copy_loop_end
    pop %rax
    movb %al, (%rsi)
    add $1, %rsi
    sub $1, %r8
    cmp $0, %r8
    jge decimal_to_ascii_copy_loop
decimal_to_ascii_copy_loop_end:
    mov %rdx, %rax
    ret

