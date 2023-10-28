.data
index_page:
    .string "./index.http\0"
server_listening_msg:
    .string "chat server listening on port 11111\n\0"

.bss
.lcomm html_fd, 8
.lcomm file_size, 8
.lcomm file_buff_ptr, 8
.lcomm socket_fd, 8
.lcomm sockaddr, 8
.lcomm current_client_fd, 8

.text
.macro write fd, buf, len
    movq $1, %rax #sys_write
    movq \fd, %rdi #std out (fd 1)
    movq \buf, %rsi #initial char ptr
    movq \len, %rdx #count of chars to print
    syscall
.endm

.macro open filename, flags, modes
    movq $2, %rax #sys_open
    movq \filename, %rdi #filename
    movq \flags, %rsi #read only flag
    movq \modes, %rdx #no modes
    syscall
.endm

.macro close fd
    movq $3, %rax #sys_close
    movq \fd, %rdi #file descriptor
    syscall
.endm

.macro fstat fd, buf
    movq $4, %rax #sys_stat
    movq \fd, %rdi #file descriptor
    movq \buf, %rsi #struct pointer
    syscall
.endm

.macro mmap addr, len, prot, flags, fd, off
    movq $9, %rax #sys_mmap
    movq \addr, %rdi #addr
    movq \len, %rsi #initial char ptr
    movq \prot, %rdx #desired memory protection
    movq \flags, %r10 #memory updates visible to other processes or not
    movq \fd, %r8 #file descriptor in case we want to use swap mem
    movq \off, %r9 #offset
    syscall
.endm

.macro read fd, buf, len
    movq $0, %rax #sys_read
    movq \fd, %rdi #std out (fd 1)
    movq \buf, %rsi #initial char ptr
    movq \len, %rdx #count of chars to print
    syscall
.endm

.macro lseek fd, off, origin
    movq $8, %rax #sys_lseek
    movq \fd, %rdi #file descriptor
    movq \off, %rsi #offset
    movq \origin, %rdx #origin
    syscall
.endm

.macro socket family, type, protocol
    movq $41, %rax #sys_socket
    movq \family, %rdi
    movq \type, %rsi
    movq \protocol, %rdx
    syscall
.endm

.macro bind fd, sockaddr, addrlen
    movq $49, %rax #sys_socket
    movq \fd, %rdi #socket fd
    movq \sockaddr, %rsi #sockaddr struct ptr
    movq \addrlen, %rdx #address length
    syscall
.endm

.macro listen sockfd, backlog
    movq $50, %rax #sys_listen
    movq \sockfd, %rdi
    movq \backlog, %rsi #max length of incoming requests queue
    syscall
.endm

.macro accept fd, sockaddr, addrlen
    movq $43, %rax #sys_accept
    movq \fd, %rdi #socket fd
    movq \sockaddr, %rsi #sockaddr struct ptr
    movq \addrlen, %rdx #address length
    syscall
.endm

.globl _start
_start:
	#read index page file
	open $index_page, $0, $0

	#check for file open error
	#cmp %rax, $0
	#jle exit_program_error

	movq %rax, html_fd
	lseek html_fd, $0, $2
	movq %rax, file_size
	lseek html_fd, $0, $0
	mmap $0, file_size, $0x1, $0x22, $-1, $0
	movq %rax, file_buff_ptr
	read html_fd, $file_buff_ptr, file_size 
	close html_fd
	write $1, $file_buff_ptr, file_size

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

accept_loop:
	#null addr and addrlen, I don't care about the client for now
	accept socket_fd, $0, $0 
	movq %rax, current_client_fd
	write current_client_fd, $file_buff_ptr, file_size
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
