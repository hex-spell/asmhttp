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
#	- RCX: to dereference char*1 before compare
#	- R8: to dereference char*2 before compare
#---------------------------------------------:
map_site_cache:
    movq $0, %rax
map_site_cache_loop:
    add $5, %rsi

    sub $1, %rdx
    cmp $0, %rdx
    jnz map_site_cache_loop
