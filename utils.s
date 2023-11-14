#---------------------------------------------
# x86 calling convention volatile args: RDI, RSI, RDX, RCX, R8, R9
#---------------------------------------------
# - map_site_cache - map linux_dirent64 struct to cache
# - input registers:
#	- RDI: linux_dirent64*
#	- RSI: directory[]*
#	- RDX: amount of dirent entries to map
#	    -	I use this value as a backwards counter for a loop
# - output registers:
#	- RAX: amount of entries mapped
# - used volatile registers:
#	- RCX: to dereference offset to next struct in origin
#---------------------------------------------:
map_site_cache:
    movq $0, %rax
map_site_cache_loop:
    #!this crashes on the second iteration
    movq %rdi, %r8
    add $2, %r8
    movq (%r8), %rcx
    #I added this cause I don't know if the access syntax changes
    #the source reg as a side effect (I must research this)
    #movq 2(%rdi), %rcx # (reclen (only first 16 bits))
    movq $0xFFFFFFFFFFFF, %r8
    and %r8, %rcx
    #the meaningful info starts after this address, idk why
    #maybe this offset can go away after I implement the byte search
    #explained below
    add $64, %rdi
    movq %rcx, %rdx
    #sub $64, %rdx
    push %rax
    push %rdi
    push %rdx
    push %rcx
    #----------------------------------------------------------------
    # - the string pointer is not being sent correctly
    #	the first char is always null
    #	troubleshoot idea: print memory chunk that contains linux_dirent
    #	and translate the bytes to ascii characters, to see where
    #	the string exactly is. I'm sure I'm getting the offsets wrong
    #----------------------------------------------------------------
    #----------------------------------------------------------------
    # - looks like every file name is preceded by these bytes:
    #   0x20 0x00 0x08
    #	I can search for those bytes and then copy the string from there,
    #	stopping when I see a null terminator (0x00 byte)
    #----------------------------------------------------------------
    call strcopy
    # not saving rsi on purpose, that way I can
    # continue wrinting where I left off
    pop %rcx
    pop %rdx
    pop %rdi
    pop %rax
    #sub $1, %rdx
    #cmp $0, %rdx
    #jnz map_site_cache_loop
    ret
