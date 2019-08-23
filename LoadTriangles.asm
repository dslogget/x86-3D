    global _ReadNextNumber@8
    global _LoadTriangles@16 ;ppVertices, pnVertices, ppMeshes, pnMeshes
    global _ReadFloat@4
    global _CloseFileHandle@0
    
    %include "test.inc"
    %include "StringFuncs.inc"
    %include "FileLoading.inc"
    %include "WIN32N.INC"
    %include "WIN32FUNCS.INC"
    %define buflen 30


    section .rdata
filename    db "./test.txt", 0
fl0_5 dd 0.5
max_col_intensity dd 0xFF00

    section .data
h_file      dd 0

    section .text



_ReadFloat@4: ;filepath
    push ebp
    mov ebp, esp
    push esi
    
    push dword 0
    push esp
    push dword [ebp + 8]
    call _ReadNextNumber@8

    push eax
    fild dword [esp]
    pop eax

ReadFloat_if1:
    cmp eax, dword 0
    jne ReadFloat_endif1
    cmp [esp], dword 0
    je ReadFloat_endif1

    fchs

ReadFloat_endif1:

    ;use sign from last
    mov esi, dword [esp]
    push esp
    push dword [ebp + 8]
    call _ReadNextNumber@8
    add esp, 4

    cmp eax, dword 0
    je ReadFloat_exit

    push eax

    ;get bits needed to shift
    fldlg2
    fild dword [esp]
    fyl2x 
    fadd dword [fl0_5]
    frndint
    push dword 0
    fistp dword [esp]
    pop ecx  


    push edi
    mov edi, dword 10
    mov eax, dword 10
    cmp ecx, 0
    je ReadFloat_lp_end
ReadFloat_lp_start:
    sub ecx, dword 1
    jnz ReadFloat_lp
    jmp ReadFloat_lp_end
ReadFloat_lp:
    mul edi
    jmp ReadFloat_lp_start
ReadFloat_lp_end:
    pop edi

    fild dword [esp]
    push eax
    fidiv dword [esp]

ReadFloat_if2:
    cmp esi, dword 0
    je ReadFloat_endif2

    fchs

ReadFloat_endif2:

    fadd
    add esp, 4
ReadFloat_exit:

    pop esi
    mov esp, ebp
    pop ebp
    ret 4


_ReadNextNumber@8: ;filepath, neg
    push ebp
    mov ebp, esp
    push esi
    sub esp, 8 ;numreached, numBytesRead
    sub esp, buflen ;buffer
    mov [ebp -4*1 - 4], dword 0

ReadNextNumber_if1:
    cmp dword [h_file], 0
    jne ReadNextNumber_else1

    push dword 0
    push dword 0
    push dword OPEN_ALWAYS
    push dword 0
    push dword FILE_SHARE_READ
    push dword GENERIC_READ
    push dword [ebp + 8];
    call _CreateFileA@28
    mov dword [h_file], eax
    jmp ReadNextNumber_endif1
ReadNextNumber_else1:
    mov eax, dword [h_file]
ReadNextNumber_endif1:

    cmp eax, 0
    jne ReadNextNumber_skip
    call _GetLastError@0
    call _printEAX
    call _debug
    jmp ReadNextNumber_exit
ReadNextNumber_skip:


    xor esi, esi
ReadNextNumber_lp:
    push dword 0
    lea eax, [ebp -4*1 - 8]
    push dword eax
    push dword 1
    lea eax, [ebp -4*1 - 8 - buflen + esi]
    push dword eax
    push dword [h_file]
    call _ReadFile@20

    cmp eax, 0
    jne ReadNextNumber_skip2
    call _GetLastError@0
    call _printEAX
    call _debug
    jmp ReadNextNumber_exit
ReadNextNumber_skip2:


ReadNextNumber_if2:
    cmp [ebp -4*1 - 8], dword 0
    ja ReadNextNumber_endif2
ReadNextNumber_ret:

    cmp [ebp -4*1 - 4], dword 0
    jne ReadNextNumber_next
    mov eax, dword -1
    jmp ReadNextNumber_exit
ReadNextNumber_next:

    lea eax, [ebp -4*1 - 8 - buflen + esi]
    mov byte [eax], 0
    push dword [ebp + 12]
    lea eax, [ebp -4*1 - 8 - buflen]
    push dword eax
    call _atoi@8
    jmp ReadNextNumber_exit
ReadNextNumber_endif2: 

lea eax, [ebp -4*1 - 8 - buflen + esi]
ReadNextNumber_if3:
    cmp byte [eax], '0'
    jb ReadNextNumber_elseif3_1
    cmp byte [eax], '9'
    ja ReadNextNumber_elseif3_1
    mov [ebp -4*1 - 4], dword 1
    jmp ReadNextNumber_endif3
ReadNextNumber_elseif3_1:
    cmp [ebp -4*1 - 4], dword 0
    jne ReadNextNumber_ret
ReadNextNumber_endif3:
    
    add esi, 1


    cmp esi, dword (buflen - 1)
    jae ReadNextNumber_ret 
    jmp ReadNextNumber_lp


ReadNextNumber_exit:
    add esp, 8 ;file, heap
    add esp, buflen
    pop esi
    mov esp, ebp
    pop ebp
    ret 8





_LoadTriangles@16: ;ppVertices, pnVertices, ppIndices, pnIndices
    push ebp
    mov ebp, esp
    sub esp, dword 4 ; Heap
    sub esp, dword 80 ; buffer
    push ebx
    push esi

    push filename
    call _OpenFileRead@4
    mov esi, eax

    call _GetProcessHeap@0
    mov dword [ebp - 4 - 4*0], eax

    ;Vertices 

    lea edx, [ebp - 4 - 80]
    push edx
    push esi
    call _ReadNumbers@8
    lea edx, [ebp - 4 - 80]
    push edx
    call _atoui@4


    mov ecx, dword [ebp + 8 + 4*1]
    mov dword [ecx], eax

    shl eax, 4

    push dword eax
    push dword 0
    push dword [ebp - 4 - 4*0]
    call _HeapAlloc@12
    mov ecx, dword [ebp + 8 + 4*0]
    mov dword [ecx], eax

    ;Triangles
    lea edx, [ebp - 4 - 80]
    push edx
    push esi
    call _ReadNumbers@8
    lea edx, [ebp - 4 - 80]
    push edx
    call _atoui@4

    mov ecx, dword [ebp + 8 + 4*3]
    mov dword [ecx], eax

    shl eax, 4

    push dword eax
    push dword 0
    push dword [ebp - 4 - 4*0]
    call _HeapAlloc@12
    mov ecx, dword [ebp + 8 + 4*2]
    mov dword [ecx], eax

    mov ebx, dword [ebp + 8 + 4*1]
    mov ecx, dword [ebx] ; load num vertices


    mov eax, dword [ebp + 8 + 4*0] 
    mov ebx, dword [eax] ; load ptr to vert arr
LoadTriangles_lp1:
    push ecx
        lea edx, [ebp - 4 - 80]
        push edx
        push esi
        call _ReadNumbers@8
        lea edx, [ebp - 4 - 80]
        push edx
        call _atof@4 ; x
        fstp dword [ebx]

        add ebx, dword 4

        lea edx, [ebp - 4 - 80]
        push edx
        push esi
        call _ReadNumbers@8
        lea edx, [ebp - 4 - 80]
        push edx
        call _atof@4 ; y
        fstp dword [ebx]

        add ebx, dword 4

        lea edx, [ebp - 4 - 80]
        push edx
        push esi
        call _ReadNumbers@8
        lea edx, [ebp - 4 - 80]
        push edx
        call _atof@4 ; y
        fstp dword [ebx]


        add ebx, dword 4
        fld1
        fstp dword [ebx] ;w
        add ebx, dword 4

    pop ecx
    sub ecx, dword 1
    jnz LoadTriangles_lp1



    mov ebx, dword [ebp + 8 + 4*3]
    mov ecx, dword [ebx] ; load num indices

    mov eax, dword [ebp + 8 + 4*2] 
    mov ebx, dword [eax] ; load ptr to index arr

LoadTriangles_lp2:
    push ecx

        lea edx, [ebp - 4 - 80]
        push edx
        push esi
        call _ReadNumbers@8;0
        lea edx, [ebp - 4 - 80]
        push edx
        call _atoui@4

        mov dword [ebx], eax
        add ebx, dword 4

        lea edx, [ebp - 4 - 80]
        push edx
        push esi
        call _ReadNumbers@8;1
        lea edx, [ebp - 4 - 80]
        push edx
        call _atoui@4
        mov dword [ebx], eax
        add ebx, dword 4

        lea edx, [ebp - 4 - 80]
        push edx
        push esi
        call _ReadNumbers@8;2
        lea edx, [ebp - 4 - 80]
        push edx
        call _atoui@4
        mov dword [ebx], eax
        add ebx, dword 4

    pop ecx
    sub ecx, dword 1
    jnz LoadTriangles_lp2

    push dword esi
    call _CloseHandle@4

    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 16
    


_CloseFileHandle@0:
    push dword [h_file]
    call _CloseHandle@4
    mov [h_file], dword 0
    ret

