; ==================================================================
; AsalOS -- An Operating System kernel written in Assembly
; by Asal Handapangoda.
; ==================================================================

    BITS 16
    ORG 0000h

start:
    mov ax, cs
    mov ds, ax
    mov es, ax

    call clear_screen
    mov si, welcome_string
    call print_string
    call print_newline

    ; Block letters for "OS"
    mov si, line1
    call print_string
    call print_newline

    mov si, line2
    call print_string
    call print_newline

    mov si, line3
    call print_string
    call print_newline

    mov si, line4
    call print_string
    call print_newline

    mov si, line5
    call print_string
    call print_newline

main_loop:
    call print_newline
    mov si, prompt_string
    call print_string

    mov di, command_buffer
    call read_string

    mov si, command_buffer
    mov di, info_cmd
    call string_compare
    je handle_info_cmd

    mov si, command_buffer
    mov di, help_cmd
    call string_compare
    je handle_help_cmd

    mov si, command_buffer
    mov di, clear_cmd
    call string_compare
    je handle_clear_cmd

    mov si, unknown_cmd_string
    call print_newline
    call print_string
    jmp main_loop

handle_info_cmd:
    call show_hardware_info
    jmp main_loop

handle_help_cmd:
    call print_newline
    mov si, help_menu_string
    call print_string
    call print_newline
    jmp main_loop

handle_clear_cmd:
    call clear_screen
    jmp main_loop

; ------------------------------------------------------------------
; HARDWARE INFO ROUTINES
; ------------------------------------------------------------------

show_hardware_info:
    pusha
    call print_newline
    call detect_memory
    call detect_cpu
    call detect_drives
    call detect_mouse
    call detect_serial_ports
    call detect_cpu_features
    popa
    ret

detect_memory:
    mov si, mem_base_label
    call print_string
    int 12h
    mov [base_mem_kb], ax
    call print_decimal
    call print_k_suffix

    mov si, mem_ext_label
    call print_string
    mov ah, 0x88
    int 0x15
    mov [ext_mem_kb], ax
    call print_decimal
    call print_k_suffix

    mov si, mem_ext2_label
    call print_string
    mov ax, 0xE801
    int 0x15
    jc .no_e801
    mov [ext2_mem_16k_blocks], cx
    mov [ext2_mem_64k_blocks], dx
    mov dx, 0
    mov ax, [ext2_mem_64k_blocks]
    mov cx, 16
    div cx
    mov [ext2_mem_mb], ax
    call print_decimal
    call print_M_suffix
    jmp .sum_total

.no_e801:
    mov si, not_supported_str
    call print_string
    mov word [ext2_mem_mb], 0

.sum_total:
    mov eax, 0
    movzx ebx, word [base_mem_kb]
    add eax, ebx
    movzx ebx, word [ext_mem_kb]
    add eax, ebx
    movzx ebx, word [ext2_mem_mb]
    mov ecx, 1024
    imul ebx, ecx
    add eax, ebx
    mov edx, 0
    mov ecx, 1024
    div ecx
    call print_decimal
    call print_M_suffix
    ret

detect_cpu:
    mov si, cpu_vendor_label
    call print_string
    mov eax, 0
    cpuid
    mov [cpu_vendor_str+0], ebx
    mov [cpu_vendor_str+4], edx
    mov [cpu_vendor_str+8], ecx
    mov si, cpu_vendor_str
    call print_string
    call print_newline

    mov eax, 0x80000002
    cpuid
    mov [cpu_type_str+0], eax
    mov [cpu_type_str+4], ebx
    mov [cpu_type_str+8], ecx
    mov [cpu_type_str+12], edx
    mov eax, 0x80000003
    cpuid
    mov [cpu_type_str+16], eax
    mov [cpu_type_str+20], ebx
    mov [cpu_type_str+24], ecx
    mov [cpu_type_str+28], edx
    mov eax, 0x80000004
    cpuid
    mov [cpu_type_str+32], eax
    mov [cpu_type_str+36], ebx
    mov [cpu_type_str+40], ecx
    mov [cpu_type_str+44], edx
    mov si, cpu_type_str
    call print_string
    call print_newline
    ret

detect_drives:
    mov si, hdd_label
    call print_string
    push es
    mov ax, 0x0040
    mov es, ax
    mov al, [es:0x0075]
    mov ah, 0
    pop es
    call print_decimal
    call print_newline
    ret

detect_mouse:
    mov si, mouse_label
    call print_string
    mov ax, 0
    int 0x33
    cmp ax, 0
    je .no_mouse
    mov si, mouse_found_str
    call print_string
    jmp .done
.no_mouse:
    mov si, mouse_notfound_str
    call print_string
.done:
    call print_newline
    ret

detect_serial_ports:
    mov si, serial_count_label
    call print_string
    push es
    mov ax, 0x0040
    mov es, ax
    mov cx, 0
    mov si, 0
.loop:
    mov dx, [es:si]
    cmp dx, 0
    je .next
    inc cx
.next:
    add si, 2
    cmp si, 8
    jne .loop
    mov ax, cx
    call print_decimal
    call print_newline
    mov si, serial_addr_label
    call print_string
    mov ax, [es:0]
    pop es
    call print_decimal
    call print_newline
    ret

detect_cpu_features:
    mov si, features_label
    call print_string
    mov eax, 1
    cpuid
    mov [feature_flags_edx], edx
    test edx, 1 << 0
    jz .no_fpu
    mov si, fpu_str
    call print_string
.no_fpu:
    test edx, 1 << 23
    jz .no_mmx
    mov si, mmx_str
    call print_string
.no_mmx:
    test edx, 1 << 25
    jz .no_sse
    mov si, sse_str
    call print_string
.no_sse:
    test edx, 1 << 26
    jz .no_sse2
    mov si, sse2_str
    call print_string
.no_sse2:
    call print_newline
    ret

; ------------------------------------------------------------------
; UTILITY ROUTINES
; ------------------------------------------------------------------

print_string:
    mov ah, 0Eh
.repeat:
    lodsb
    cmp al, 0
    je .done
    int 10h
    jmp .repeat
.done:
    ret

print_newline:
    push ax
    mov ah, 0Eh
    mov al, 0Dh
    int 10h
    mov al, 0Ah
    int 10h
    pop ax
    ret

print_k_suffix:
    pusha
    mov si, k_str
    call print_string
    call print_newline
    popa
    ret

print_M_suffix:
    pusha
    mov si, M_str
    call print_string
    call print_newline
    popa
    ret

read_string:
    pusha
    mov bx, di
.read_loop:
    mov ah, 00h
    int 16h
    cmp al, 0Dh
    je .done_reading
    cmp al, 08h
    je .backspace
    mov [di], al
    mov ah, 0Eh
    int 10h
    inc di
    jmp .read_loop
.backspace:
    cmp di, bx
    je .read_loop
    dec di
    mov byte [di], 0
    mov ah, 0Eh
    mov al, 08h
    int 10h
    mov al, ' '
    int 10h
    mov al, 08h
    int 10h
    jmp .read_loop
.done_reading:
    mov byte [di], 0
    popa
    ret

string_compare:
    pusha
.loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .notequal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
.notequal:
    popa
    cmp ax, bx
    ret
.equal:
    popa
    cmp ax, ax
    ret

print_decimal:
    pusha
    mov cx, 0
    mov ebx, 10
.div_loop:
    mov edx, 0
    div ebx
    push edx
    inc cx
    cmp eax, 0
    jne .div_loop
.print_loop:
    pop eax
    add al, '0'
    mov ah, 0Eh
    int 10h
    loop .print_loop
    popa
    ret

clear_screen:
    pusha
    mov ah, 0x00
    mov al, 0x03
    int 10h
    popa
    ret

; ------------------------------------------------------------------
; KERNEL DATA
; ------------------------------------------------------------------

welcome_string      db 'Welcome AsalOS by Asal Handapangoda!', 0
line1               db '$$$$$   $$$$$$ ', 0
line2               db '$   $   $     ', 0
line3               db '$   $   $$$$_  ', 0
line4               db '$   $        $ ', 0
line5               db '$$$$$   $$$$$$ ', 0
prompt_string       db 'AsalOS :) >> ', 0
unknown_cmd_string  db 'Unknown command', 0
info_cmd            db 'info', 0
help_cmd            db 'help', 0
clear_cmd           db 'clear', 0
help_menu_string    db 'info - Hardware Information', 0Dh, 0Ah, 'clear - Clear Screen', 0Dh, 0Ah, 0

mem_base_label      db 'Base Memory size: ', 0
mem_ext_label       db 'Extended memory between (1M - 16M): ', 0
mem_ext2_label      db 'Extended memory above 16M: ', 0
mem_total_label     db 'Total memory: ', 0

cpu_vendor_label    db 'CPU Vendor: ', 0
cpu_desc_label      db 'CPU description: ', 0
hdd_label           db 'Number of hard drives: ', 0
mouse_label         db 'Mouse Status: ', 0
serial_count_label  db 'Number of serial port: ', 0
serial_addr_label   db 'Base I/O address for serial port 1: ', 0
features_label      db 'CPU Features: ', 0

mouse_found_str     db 'The Mouse Found', 0
mouse_notfound_str  db 'Not Found', 0
not_supported_str   db 'Not Supported', 0

k_str               db 'k', 0
M_str               db 'M', 0
fpu_str             db 'FPU ', 0
mmx_str             db 'MMX ', 0
sse_str             db 'SSE ', 0
sse2_str            db 'SSE2 ', 0

command_buffer      times 64 db 0
cpu_vendor_str      times 13 db 0
cpu_type_str        times 49 db 0

base_mem_kb         dw 0
ext_mem_kb          dw 0
ext2_mem_16k_blocks dw 0
ext2_mem_64k_blocks dw 0
ext2_mem_mb         dw 0
feature_flags_edx   dd 0