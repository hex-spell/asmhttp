.macro pushcallersaved
    PUSH %rdi
    PUSH %rsi
    PUSH %rdx
    PUSH %r10
    PUSH %r8 
    PUSH %r9 
.endm

.macro popcallersaved
    POP %r9 
    POP %r8 
    POP %r10
    POP %rdx
    POP %rsi
    POP %rdi
.endm

