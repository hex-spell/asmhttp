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
    movq $0, %r8
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
    push %r9
    push %r11

    push %rsi
    addq $1, %rsi #byte for entry length
    movq $10, %rcx
    addq $19, %rdi
    #NOTE: this might cause an off by one error in the future
    #I have to take the null terminator into account
    movq $47, %rdx #max 46 chars for now (47 with null terminator)
    call strcopy
    #--add entry length at the beginning
    addq %rax, %r10 #r10 keeps track of the total string length
    movq %rsi, %r8
    popq %rsi
    movb %al, (%rsi)

    push %r8
    push %r10
    push %rdi
    push %rsi
    movq %r8, %rsi #rsi = file buffer pointer
    movq %rsi, %rdi
    addq $1, %rdi #rdi = file name
    call read_file
    pop %rsi
    pop %rdi
    pop %r10
    pop %r8

    movq %r8, %rsi #return rsi to end of file name

    addq $8, %rsi #move 8 bytes to skip file buffer pointer
    movq %rax, (%rsi) #assign file size
    addq $8, %rsi #move 8 bytes to skip file size
    addq $17, %r10 #1 byte for entry length, 8 for address, 8 for size

    pop %r11
    pop %r9
    pop %rdx
    pop %rdi
map_site_cache_goto_next_entry:
    add %r9, %rdi #move dirent pointer to next dirent struct
    add $1, %r11
    cmp $5, %r11 #max 5 files for now
    jle map_site_cache_loop
    ret

#---------------------------------------------
# x86 calling convention volatile args: RDI, RSI, RDX, RCX, R8, R9
#---------------------------------------------
# - read_file - read a file into dynamic memory
# - input registers:
#	- RDI: char* filename (null terminated)
#	- RSI: uint64* file buffer pointer (value assigned by this func)
# - output registers:
#	- RAX: size of file read to memory 
#---------------------------------------------:
read_file:
    #this is really dumb and not efficient at all
    push %rdi
    push %rsi
    movq %rdi, %r8 #r8 now has the char* filename
    open %r8, $0x8000, $0

    movq %rax, %r8 #r8 now has the file descriptor
    lseek %r8, $0, $2
    movq %rax, %r9 #r9 now has the file size
    lseek %r8, $0, $0
    #allocate memory for the website file
    mmap $0, %r9, $0x3, $0x22, $-1, $0
    movq %rax, %r10 #r10 now has the file buffer allocation pointer 
    #read the website file into memory
    read %r8, %r10, %r9
    pop %rsi
    pop %rdi
    #move the buff pointer to output address location
    movq %r10, (%rsi)
    close %r8
    movq %r9, %rax
    ret

#------------------------------------------------------
# TODO: map the dirent array
# to my own struct array format to act as a cache
# that would be:
#	struct linux_dirent64 {
#	    ino64_t        d_ino;    /* 64-bit inode number */
#	    off64_t        d_off;    /* 64-bit offset to next structure */
#	    unsigned short d_reclen; /* Size of this dirent */ short=16 bits
#	    unsigned char  d_type;   /* File type */
#	    char           d_name[]; /* Filename (null-terminated) */
#	}
#
#	struct directory {
#	    char name_length
#	    char* name (null terminated) (hard limited to 46 chars)
#	    int64 buff_ptr
#	    int64 file_size
#	} max: 64 bytes per entry
# 
# NOTE: the mapping is done, but I map everything, instead of
# opening files when users request them, so what's below is a nice to have
# but not yet implemented
#
# The idea is to traverse this struct array
# searching for the filename
# if the file size is 0, that means that the file
# was not read to ram yet
# so I'd have to:
#	- call the open() syscall
#	- mmap the results
#	- change the values of file_size and buff_ptr in
#	    the array
#	- continue with the accept request flow
#
# Then the next time an user makes a request
# the file is already in memory, and I can skip the
# open() part
# NOTE: I can use the stack to keep track of the address
# of both file_size and buff_ptr
# Both are int64, so I should be able to push and pop
# To regular 64 bit registers without having to save
# pointers in .bss
#------------------------------------------------------

