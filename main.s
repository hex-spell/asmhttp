.data
index_page:
    .string "./public_html/index.http\0"
server_listening_msg:
    .string "chat server listening on port 11111\n\0"
strcomp_msg:
    .string "strcomp!\n\0"
strcomp_msg_eq: #(debug)
    .string "equals!\n\0"
# directory scan
open_directory:
    .string "./public_html/"
# delimiters
space_delimiter:
    .string " "
newline_delimiter:
    .string "\n"
# http verbs
http_get:
    .string "GET"
http_post:
    .string "POST"


.bss
#index.http file opening vars
.lcomm html_fd, 8
.lcomm file_size, 8
.lcomm file_buff_ptr, 8

#directory scan vars
.lcomm dir_fd, 8
.lcomm dirent_ptr, 8
.lcomm dirent_size, 8
.lcomm directory_ptr, 8

#server socket vars
.lcomm socket_fd, 8
.lcomm sockaddr, 8

#client socket vars
.lcomm current_client_fd, 8
.lcomm current_client_msg_buff_ptr, 8

#charseek vars, used to get path from request
.lcomm substr_begin_ptr, 8
.lcomm substr_end_ptr, 8
.lcomm substr_length, 8


.text
.include "syscalls.s"
.include "macros.s"
.include "strings.s"
.include "utils.s"
 

.globl _start
_start:
    #create dir fd
    open $open_directory, $0x10000, $0
    movq %rax, dir_fd
    #getting dirent
    mmap $0, $16384, $0x3, $0x22, $-1, $0
    movq %rax, dirent_ptr
    getdents64 dir_fd, dirent_ptr, $16384
    movq %rax, dirent_size
    #write $1, dirent_ptr, dirent_size
    #mapping dirent
    mmap $0, $16384, $0x3, $0x22, $-1, $0
    movq %rax, directory_ptr
    movq dirent_ptr, %rdi
    movq directory_ptr, %rsi
    movq $open_directory, %rdx
    call map_site_cache
    write $1, directory_ptr, $100

    
    #read index page file
    open $index_page, $0x8000, $0

    #check for file open error
    #cmp %rax, $0
    #jle exit_program_error

    movq %rax, html_fd
    lseek html_fd, $0, $2
    movq %rax, file_size
    lseek html_fd, $0, $0
    #allocate memory for the website file
    mmap $0, file_size, $0x3, $0x22, $-1, $0
    movq %rax, file_buff_ptr
    #read the website file into memory
    movq file_buff_ptr, %r14
    read html_fd, %r14, file_size 
    close html_fd
    #write $1, %r14, file_size

    #start server
    socket $2, $1, $0

    #check for socket open error
    #cmp %rax, $0
    #jle exit_program_error

    movq %rax, socket_fd

    #thank god I found this https://gist.github.com/geyslan/5174296
    #I had no idea how to handle structs or the stack

    push $0 #INADDR_ANY = 0 (uint32_t)
    pushw $0x672b #port in byte reverse order = 11111 (uint16_t)
    pushw $2 #AF_INET = 2 (unsigned short int)
    movq %rsp, sockaddr #stack pointer = struct pointer atm
    
    #TODO: err handling for bind and listen
    bind socket_fd, sockaddr, $16
    listen socket_fd, $128

    write $1, $server_listening_msg, $37

    #allocate memory (4096kb) for the client request
    mmap $0, $4096, $0x3, $0x22, $-1, $0
    movq %rax, current_client_msg_buff_ptr

accept_loop:
    #null addr and addrlen, I don't care about the client for now
    accept socket_fd, $0, $0 
    movq %rax, current_client_fd
    recvfrom current_client_fd, current_client_msg_buff_ptr, $4096, $0, $0, $0
    #write $1, current_client_msg_buff_ptr, $4
    #calling convention args: RDI, RSI, RDX, RCX, R8, R9
    # is get?
    #movq $http_get, %rdi
    #movq current_client_msg_buff_ptr, %rsi
    #movq $3, %rdx
    #call strcomp

    #print requested path to screen
    movq current_client_msg_buff_ptr, %rdi
    movq space_delimiter, %rsi
    movq $32, %rdx
    call charseek 
    add $1, %rdi
    movq %rdi, substr_begin_ptr
    movq $32, %rdx
    call charseek
    add $1, %rdi
    movq %rdi, substr_end_ptr
    movq %rax, substr_length
    write $1, substr_begin_ptr, substr_length
    write $1, $newline_delimiter, $1

    #write response to client
    movq file_buff_ptr, %r14
    write current_client_fd, %r14, file_size
    close current_client_fd
    jmp accept_loop

    close socket_fd
    jmp exit_program

exit_program:
    movq $60, %rax # exit(0)
    movq $0, %rdi
    syscall

exit_program_error:
    movq $60, %rax # exit(1)
    movq $1, %rdi
    syscall
