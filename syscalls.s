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

.macro brk brkl
    movq $12, %rax #sys_brk
    movq \brkl, %rdi #brk long
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

.macro recvfrom fd, ubuf_ptr, size, flags, sockaddr_ptr, addr_len_ptr
    movq $45, %rax #sys_recvfrom
    movq \fd, %rdi
    movq \ubuf_ptr, %rsi
    movq \size, %rdx
    movq \flags, %r10
    movq \sockaddr_ptr, %r8
    movq \addr_len_ptr, %r9
    syscall
.endm

#dirent_ptr is linux_dirent64*
.macro getdents64 fd, dirent_ptr, count
    movq $217, %rax #sys_recvfrom
    movq \fd, %rdi
    movq \dirent_ptr, %rsi
    movq \count, %rdx
    syscall
.endm

.macro getdents fd, dirent_ptr, count
    movq $78, %rax #sys_recvfrom
    movq \fd, %rdi
    movq \dirent_ptr, %rsi
    movq \count, %rdx
    syscall
.endm


