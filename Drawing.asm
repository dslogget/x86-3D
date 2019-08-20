    %include "WIN32N.INC"
    %include "WIN32FUNCS.INC"
    %include "Matrix.inc"
    %include "test.inc"
    %include "StringFuncs.inc"

    global _SetPixelD@20
    global _Bresenham@32

    section .data

    section .rdata

    section .bss

    section .text

    ;Screen:
    ;   0x00    hdc
    ;   0x04    height
    ;   0x08    width
    ;   0x0C    pDepthBuffer

_SetPixelD@20:      ;pScreenStruct, pixX, pixY, fDepth, colref
    push ebp
    mov ebp, esp
    push ebx

    mov ebx, [ebp + 8]


    ;Get depth buffer row offset index
    mov eax, dword  [ebx + 4*2]
    mov ecx, dword [ebp + 8 + 4*2]
    mul ecx 
    shl eax, 2
    

    ;get depth buffer pointer
    mov edx, dword [ebx + 4*3]
    
    ;get final index
    add edx, eax
    mov eax, dword [ebp + 8 + 4*1]
    shl eax, 2
    add edx, eax

    ;Load vals to compare
    lea ecx, [ebp + 8 + 4*3]
    fld dword [ecx] ;point depth = ST(0)
    cmp dword [edx], dword 0
    je SetPixelD_else1
    fcom dword [edx] ;Stored depth
    fstsw ax 
    and ax, 0b0100011100000000 ;extract Cs
    xor ax, 0b0000000100000000 ;Check if new point is 
SetPixelD_if1:
    jz SetPixelD_else1;if zero then new point is smaller
    fstp st0
    jmp PixelD_exit
SetPixelD_else1:
    fstp dword [edx]

    push dword [ebp + 8 + 4*4]
    push dword [ebp + 8 + 4*2]
    push dword [ebp + 8 + 4*1]
    push dword [ebx]
    call _SetPixel@16


PixelD_exit:
    pop ebx
    mov esp, ebp
    pop ebp
    ret 20




_Bresenham@32: ;pScreenStruct, pixX1, pixY1, fDepth1, pixX2, pixY2, fDepth2, colref
    push ebp
    mov ebp, esp
    ;pScreenStruct
    sub esp, 16 ;ebp - 4 = adjust; ebp - 8 = x; ebp - 12 = y; tmp
    mov dword [ebp-4], 1
    push esi
    ;rise
    push edi
    ;run
    push ebx



    ;Check if x1 < x2 
    mov eax, dword [ebp + 8 + 4*1]
    mov edx, dword [ebp + 8 + 4*4]
    cmp eax, edx
    jle Bresenham_skipSwap

    mov dword [ebp + 8 + 4*4], eax
    mov dword [ebp + 8 + 4*1], edx

    mov eax, dword [ebp + 8 + 4*2]
    mov edx, dword [ebp + 8 + 4*5]

    mov dword [ebp + 8 + 4*5], eax
    mov dword [ebp + 8 + 4*2], edx

    mov eax, dword [ebp + 8 + 4*3]
    mov edx, dword [ebp + 8 + 4*6]

    mov dword [ebp + 8 + 4*6], eax
    mov dword [ebp + 8 + 4*3], edx
Bresenham_skipSwap:  

    mov ebx, dword [ebp + 8 + 4*1]
    mov dword [ebp - 8], ebx

    mov ebx, dword [ebp + 8 + 4*2]
    mov dword [ebp - 12], ebx



    mov edi, [ebp + 8 + 4*5]
    sub edi, [ebp + 8 + 4*2]

    cmp edi, 0
    jge Bresenham_SkipSetSlope
    mov dword [ebp - 4], -1

Bresenham_SkipSetSlope:

    push edi
    sar edi, 31
    xor dword [esp], edi
    sub dword [esp], edi
    pop edi


    mov ebx, [ebp + 8 + 4*4]
    sub ebx, [ebp + 8 + 4*1]
    
    cmp edi, ebx
    jg Bresenham_UseYAxis
    shl edi, 1



    ;threshold = run = ebx

    ;error = esi

    mov esi, dword 0
BresenhamX_lp:
    mov eax, dword [ebp - 8]
    cmp eax, dword [ebp + 8 + 4*4]
    jg Bresenham_exit

    ;interpolate pixel depth

    ;load x
    lea eax, [ebp - 8]
    fild dword [eax]

    ;get dist along x
    lea eax, [ebp + 8 + 4*1]
    fisub dword [eax]

    ;div by run
    lea eax, [ebp - 16]
    mov dword [eax], ebx
    fidiv dword [eax]

    ;load fDepth2
    lea eax, [ebp + 8 + 4*6]
    fld dword [eax]
    ;sub fDepth1
    lea eax, [ebp + 8 + 4*3]
    fsub dword [eax]
    ;multiply by fraction
    fmulp
    fadd dword [eax]

    push dword [ebp + 8 + 4*7]
    push dword 0
    fstp dword [esp]
    push dword [ebp - 12]
    push dword [ebp - 8]
    push dword [ebp + 8]
    call _SetPixelD@20

    add dword [ebp - 8], 1

    add esi, edi
    cmp esi, ebx
    jl BresenhamX_lp

    shl ebx, 1
    sub esi, ebx
    shr ebx, 1

    mov eax, dword [ebp - 4]
    add dword [ebp - 12], eax
    jmp BresenhamX_lp

Bresenham_UseYAxis:

Bresenham_exit:

    pop ebx
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret 32
