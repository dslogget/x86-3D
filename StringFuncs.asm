    global _uitoa@8
    global _strlen@4
    global _atoui@4
    global _itoa@8
    global _ftoa@8
    global _atoi@8
    global _atof@4
    global _memset@12
    global _memsetDWORD@12

    %include "test.inc"
    %include "WIN32FUNCS.INC"

    extern h_stdout

    section .rdata
DEC_LUT dd 1000000000,100000000,10000000,1000000,100000,10000,1000,100,10,1,0



    section .text
_atof@4: ;pBuf
    push ebp
    mov ebp, esp
    push dword 10
    push dword 0
    push ebx
    
    mov ebx, dword [ebp + 8 + 4*0]
    ;get left half of dp
    fldz

atof_lp1:
    cmp byte [ebx], 0
    je atof_exit
    cmp byte [ebx], '.'
    je atof_lpend1
    cmp byte [ebx], '-'
    jne atof_skipSetNeg
    mov [ebp - 4 - 4*1], dword 1
    inc ebx
    jmp atof_lp1
atof_skipSetNeg:
    fimul dword [ebp - 4 - 4*0]
    ;mul by 10

    movzx ecx, byte [ebx]
    sub cl, byte '0'
    ;convert ascii to number
    push ecx
    fiadd dword [esp]
    add esp, dword 4
    ;add to total

    inc ebx
    jmp atof_lp1
atof_lpend1:
    inc ebx

    fldz
atof_lp2:
    cmp byte [ebx], 0
    je atof_lpend2


    movzx ecx, byte [ebx]
    sub cl, byte '0'
    ;convert ascii to number
    push ecx
    fild dword [esp]
    add esp, dword 4
    ;mov to fpu

    fidiv dword [ebp - 4 - 4*0]
    ;divide by exp
    fadd

    mov eax, dword [ebp - 4 - 4*0]
    mov ecx, dword 10
    mul ecx
    mov dword [ebp - 4 - 4*0], eax
    ;inc exp

    inc ebx
    jmp atof_lp2
atof_lpend2:
    fadd

atof_exit:
    cmp dword [ebp - 4 - 4*1], 0
    je atof_exit_skip_set
    fchs
atof_exit_skip_set:
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4



_atoi@8: ;param1: arrayptr; param2: neg return num
    push ebp
    mov ebp, esp

    mov ecx, dword [ebp + 12]
    mov [ecx], dword 0

    ;edx is neg true

    push dword [ebp + 8]
    call _atoui@4

    mov ecx, dword [ebp + 8]
atoi_lp:
    cmp [ecx], byte '-'
    je atoi_lp_setneg
    cmp [ecx], byte 0
    je atoi_lp_end

    inc ecx

    jmp atoi_lp
atoi_lp_setneg:
    mov ecx, [ebp + 12]
    mov [ecx], dword 1
    neg eax
atoi_lp_end:

    mov esp, ebp
    pop ebp
    ret 8




_atoui@4: ;param1: arrayptr; return num
    push ebp
    mov ebp, esp
    push ebx
    push esi

    xor ebx, ebx
    xor eax, eax
    mov ecx, dword [ebp + 8]
    mov esi, dword 10

atoui_lp:
    mov bl, byte [ecx]
atoui_if1:
    cmp bl, byte 0
    jne atoui_elseif1_1
    jmp atoui_exit
atoui_elseif1_1:
    cmp bl, '0'
    jae atoui_elseif1_2
    add ecx, 1
    jmp atoui_lp
atoui_elseif1_2:
    cmp bl, '9'
    jbe atoui_endif1
    add ecx, 1
    jmp atoui_lp
atoui_endif1:
    
    mul esi
    sub ebx, dword '0'
    add eax, ebx
    add ecx, 1
    jmp atoui_lp

atoui_exit:
    ;call _printEAX

    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4

_ftoa@8: ;buf, float; ret len
    push ebp
    mov ebp, esp
    push ebx
    push edi
    sub esp, 8


    mov ebx, [ebp + 8]
ftoa_if1:
    test dword [ebp + 12], (1<<31)
    jz ftoa_endif1

    mov byte [ebx], '-'
    inc ebx

    and dword [ebp + 12], ~(1<<31)

ftoa_endif1:

    mov dword [ebp -4*2 - 8], 0
    fld dword [ebp + 12]
    

    fisttp dword [ebp -4*2 - 4]

    push dword [ebp -4*2 - 4]
    push dword ebx
    call _itoa@8
ftoa_if2:
    cmp eax, dword 0
    jne ftoa_endif2
    mov byte [ebx], '0'
    mov eax, dword 1
ftoa_endif2:
    add [ebp -4*2 - 8], eax
    add ebx, eax

    ;cmp eax, 1
    ;je ftoa_exit

    ;call _printEAX
    ;call _printCRLF

    fld dword [ebp + 12]
    lea edi, [ebp -4*2 - 4]
    fisub dword [edi]
    mov dword [ebp -4*2 - 4], 1000000000
    fimul dword [edi]
    fistp dword [edi]

    ;jmp ftoa_exit
    mov byte [ebx], '.'
    add ebx, 1
    add dword [ebp -4*2 - 8], 1 

    push dword [ebp -4*2 - 4]
    push dword ebx
    call _uitoa@8
ftoa_if3:
    cmp eax, dword 0
    jne ftoa_endif3
    mov byte [ebx], '0'
    mov eax, dword 1
ftoa_endif3:

ftoa_exit:
    add eax, [ebp -4*2 - 8]
    add ebx, eax

    add esp, 8
    pop edi
    pop ebx
    mov ebp, esp
    pop ebp
    ret 8


_itoa@8: ;param1: buf ;param2:int ;return length
    push ebp
    mov ebp, esp
    push ebx
    push edi
    sub esp, 4

    mov ebx, dword [ebp + 8]
    mov edi, dword [ebp + 12]

itoa_if1:                 
    cmp edi, 0
    jge itoa_else1
    neg edi
    mov byte [ebx], '-'
    inc ebx
    mov [ebp -4*2 - 4], dword 1
    jmp itoa_endif1
itoa_else1:
    mov [ebp -4*2 - 4], dword 0
itoa_endif1: 

    push dword edi
    push dword ebx
    call _uitoa@8
    add eax, dword [ebp -4*2 - 4]


    add esp, 4
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 8



_uitoa@8: ;param1: buf ;param2:int ;return length
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov ebx, [ebp + 8]  ;buf ptr
    mov ecx, [ebp + 12] ;int
    xor eax, eax
    mov edi, dword DEC_LUT

uitoa_while1:
    mov esi, [edi]
    cmp esi, dword 0
    je uitoa_wend1
    

    xor edx, edx

uitoa_while2:
        cmp ecx, esi
        jb uitoa_wend2

        sub ecx, esi
        inc edx
        jmp uitoa_while2
uitoa_wend2:
    cmp eax, dword 0
    jne uitoa_if
    cmp edx, dword 0
    je uitoa_endif
uitoa_if:
    add edx, dword '0'
    mov byte [ebx], dl
    inc ebx
    inc eax
uitoa_endif:
    add edi, 4
    jmp uitoa_while1
uitoa_wend1:
    mov byte [ebx], byte 0

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 8


_strlen@4: ;param1: byte ptr
    push ebp
    mov ebp, esp
    push ebx
    
    xor eax, eax ;toRet = 0
    mov ebx, [ebp + 8] ;retrieve param

strlen_while:
    cmp byte [ebx], byte 0
    je strlen_endw

    inc eax
    inc ebx
    jmp strlen_while
strlen_endw:

    pop ebx
    mov esp, ebp
    pop ebp
    ret 4



_memset@12: ;param1: ptr ;param2: byte val ;param3 num of bytes
    push ebp
    mov ebp, esp

    mov eax, dword [ebp + 8]
    mov edx, dword [ebp + 12]
    mov ecx, dword [ebp + 16]
memset_while:
    mov byte [eax], dl
    inc eax
    sub ecx, dword 1
    jnz memset_while
memset_wend:
    xor eax, eax

    mov esp, ebp
    pop ebp
    ret 12



_memsetDWORD@12: ;param1: ptr ;param2: dword val ;param3 num of dwords
    push ebp
    mov ebp, esp

    mov eax, dword [ebp + 8]
    mov edx, dword [ebp + 12]
    mov ecx, dword [ebp + 16]
memsetDWORD_while:
    mov dword [eax], edx
    add eax, dword 4
    sub ecx, dword 1
    jnz memsetDWORD_while
memsetDWORD_wend:
    xor eax, eax

    mov esp, ebp
    pop ebp
    ret 12