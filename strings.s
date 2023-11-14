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
    #cmp $0, %cl #byte 0 of rcx is null (null terminator)
    #jz strcopy_finish
    add $1, %rdi
    add $1, %rsi
    add $1, %rax #counting chars
    sub $1, %rdx
    cmp $0, %rdx
    jnz strcopy_loop
strcopy_finish:
    ret

