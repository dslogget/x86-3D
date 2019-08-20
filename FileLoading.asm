
    %include "WIN32N.INC"
    %include "WIN32FUNCS.INC"

    global _OpenFileRead@4
    global _ReadToNextLine@12

    section .rdata

    section .data

    section .bss

    section .text


_OpenFileRead@4:
    push ebp
    mov ebp, esp
    push dword 0
    push dword 0
    push dword OPEN_ALWAYS
    push dword 0
    push dword FILE_SHARE_READ
    push dword GENERIC_READ
    push dword [ebp + 8]
    call _CreateFileA@28
    mov esp, ebp
    pop ebp
    ret 4

_ReadToNextLine@12: ;h_file, buf, buflen
    push ebp
    mov ebp, esp
    push dword 0
    push ebx
    push edi
    push esi

    mov ebx, [ebp + 12]
    mov edi, [ebp + 16]
    add edi, ebx
    sub edi, dword 1
    mov [edi], byte 0 
    mov esi, [ebp + 8]


ReadToNextLine_lp1:

    cmp ebx, edi
    je ReadToNextLine_lp_end

    push dword 0
    lea eax, [ebp - 4]
    push dword eax
    push dword 1
    push dword ebx
    push dword esi
    call _ReadFile@20

    cmp [ebp - 4], dword 0
    je ReadToNextLine_lp_end

    cmp eax, dword 0
    je ReadToNextLine_lp_end

    cmp ebx, dword [ebp + 12]
    je ReadToNextLine_lp1_start
    cmp byte [ebx], 10
    je ReadToNextLine_lp_end
    cmp byte [ebx], 13
    je ReadToNextLine_lp_end
ReadToNextLine_lp1_start:
    cmp byte [ebx], 10
    je ReadToNextLine_lp1
    cmp byte [ebx], 13
    je ReadToNextLine_lp1

ReadToNextLine_lp1_body:
    add ebx, dword 1
    jmp ReadToNextLine_lp1
ReadToNextLine_lp_end:

    mov [ebx], dword 0

    mov eax, ebx
    sub eax, dword [ebp + 12]

    pop esi
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 12