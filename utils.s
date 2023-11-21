.bss
.lcomm concatenated_file_dir_ptr, 8
.text
#---------------------------------------------
# x86 calling convention volatile args: RDI, RSI, RDX, RCX, R8, R9
#---------------------------------------------
# - map_site_cache - map linux_dirent64 struct to cache
# - input registers:
#	- RDI: linux_dirent64*
#	- RSI: directory[]*
#	- RDX : char* base directory
#	- RCX: amount of dirent entries to map
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

    #--- map memory for the concatenated directory and file name
    push %rdi
    push %rsi
    push %rdx
    push %r10
    push %r11
    push %r8
    push %r9
    mmap $0, $4096, $0x3, $0x22, $-1, $0
    movq %rax, concatenated_file_dir_ptr
    pop %r9
    pop %r8
    pop %r11
    pop %r10
    pop %rdx
    pop %rsi
    pop %rdi

map_site_cache_loop:
    movb 16(%rdi), %r9b #byte at offset 16 is dirent length
    cmpb $0x08, 18(%rdi) #0x08 is dirent type file
    jnz map_site_cache_goto_next_entry
map_site_cache_string_found:
    push %rdi
    push %rdx
    push %r9
    push %r11

    #--- copy base directory to concat buffer
    push %rsi
    push %rdi
    push %rcx
    movq %rdx, %rdi #move base directory str* to strcopy args
    movq concatenated_file_dir_ptr, %rsi 
    call strcopy_raw
    movq %rsi, %r8 #save the pointer to the end of the string
    pop %rcx
    pop %rdi
    pop %rsi

    #--- copy filename from dirent to directory* and concat
    push %rsi
    addq $1, %rsi #byte for entry length
    movq $10, %rcx
    addq $19, %rdi
    #NOTE: this might cause an off by one error in the future
    #I have to take the null terminator into account
    push %rdx
    push %rcx
    push %r8
    movq %r8, %rdx #end of base dir string*
    movq $47, %rcx #max 46 chars for now (47 with null terminator)
    call strcopy_multi
    pop %r8
    pop %rcx
    pop %rdx

    #--- add entry length at the beginning
    addq %rax, %r10 #r10 keeps track of the total string length
    movq %rsi, %r8
    popq %rsi
    movb %al, (%rsi)

    #--- read file into memory and save adress in directory*
    push %r8
    push %r10
    push %rdi
    push %rsi
    movq %r8, %rsi #rsi = file buffer pointer
    movq concatenated_file_dir_ptr, %rdi #rdi = file dir
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
.bss
.lcomm read_file_fd, 8
.lcomm read_file_size, 8
.lcomm read_file_buffer_ptr, 8
.text
read_file:
    #this is really dumb and not efficient at all
    push %rdi
    push %rsi
    movq %rdi, %r8 #r8 now has the char* filename
    open %r8, $0x8000, $0

    movq %rax, read_file_fd #r8 now has the file descriptor
    lseek read_file_fd, $0, $2
    movq %rax, read_file_size #r9 now has the file size
    lseek read_file_fd, $0, $0
    #allocate memory for the website file
    mmap $0, read_file_size, $0x3, $0x22, $-1, $0
    movq %rax, read_file_buffer_ptr #r10 now has the file buffer allocation pointer 
    #read the website file into memory
    read read_file_fd, read_file_buffer_ptr, read_file_size
    pop %rsi
    pop %rdi
    #move the buff pointer to output address location
    movq read_file_buffer_ptr, %r8
    movq %r8, (%rsi)
    close read_file_fd
    movq read_file_size, %rax
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

