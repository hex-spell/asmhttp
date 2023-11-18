#---------------------------------------------
# - the string pointer is not being sent correctly
#	the first char is always null
#	troubleshoot idea: print memory chunk that contains linux_dirent
#	and translate the bytes to ascii characters, to see where
#	the string exactly is. I'm sure I'm getting the offsets wrong
#---------------------------------------------
#---------------------------------------------
# - looks like every file name is preceded by these bytes:
#   0x20 0x00 0x08
#	I can search for those bytes and then copy the string from there,
#	stopping when I see a null terminator (0x00 byte)
#---------------------------------------------
#---------------------------------------------
# - this worked, but now I get "index.asciiyA" for some reason 
#	I have to analize this struct more
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
    movq $0, %r9
    movq $0, %r10
    movq $0, %r11
map_site_cache_loop:
    movb 16(%rdi), %r9b #byte at offset 16 is dirent length
    cmpb $0x08, 18(%rdi) #0x08 is dirent type file
    jnz map_site_cache_goto_next_entry
map_site_cache_string_found:
    push %rdi
    push %rdx
    movq $10, %rcx
    addq $19, %rdi
    movq $25, %rdx #max 25 chars for now
    call strcopy
    add %rax, %r10 #r10 keeps track of the total string length
    pop %rdx
    pop %rdi
map_site_cache_goto_next_entry:
    add %r9, %rdi #move dirent pointer to next dirent struct
    add $1, %r11
    cmp $5, %r11 #max 5 files for now
    jle map_site_cache_loop
    ret
