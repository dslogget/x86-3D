    %include "WIN32N.INC"
    %include "WIN32FUNCS.INC"
    %include "Matrix.inc"
    %include "test.inc"
    %include "StringFuncs.inc"

    global _SetPixelD@20
    global _Bresenham@36
    global _DrawTriangle@20

    section .data

    section .rdata

    section .bss

    section .text

    ;ScreenStruct:
    ;pBmpBuf         0x00
    ;BmpBufPWidth     0x04
    ;bmpPB           0x08
    ;bmpBWidth       0x0C
    ;pDepthBuffer    0x10
    ;BmpBSize        0x14

_DrawTriangle@20:     ;pScreen, pVec1, pVec2, pVec3, col
    push ebp
    mov ebp, esp
    push ebx
    push edi
    push esi
    
    mov ebx, [ebp + 8 + 4*1]
    mov edi, [ebp + 8 + 4*2]
    mov esi, [ebp + 8 + 4*3]

    push dword [ebp + 8 + 4*4]
    push dword [edi + 8]
    push dword [edi + 4]
    push dword [edi]
    push dword [ebp + 8 + 4*4]
    push dword [ebx + 8]
    push dword [ebx + 4]
    push dword [ebx]
    push dword [ebp + 8 + 4*0]
    call _Bresenham@36 ;pScreenStruct, pixX1, pixY1, fDepth1, colref1, pixX2, pixY2, fDepth2, colref2

    push dword [ebp + 8 + 4*4]
    push dword [esi + 8]
    push dword [esi + 4]
    push dword [esi]
    push dword [ebp + 8 + 4*4]
    push dword [edi + 8]
    push dword [edi + 4]
    push dword [edi]
    push dword [ebp + 8 + 4*0]
    call _Bresenham@36 ;pScreenStruct, pixX1, pixY1, fDepth1, colref1, pixX2, pixY2, fDepth2, colref2

    push dword [ebp + 8 + 4*4]
    push dword [ebx + 8]
    push dword [ebx + 4]
    push dword [ebx]
    push dword [ebp + 8 + 4*4]
    push dword [esi + 8]
    push dword [esi + 4]
    push dword [esi]
    push dword [ebp + 8 + 4*0]
    call _Bresenham@36 ;pScreenStruct, pixX1, pixY1, fDepth1, colref1, pixX2, pixY2, fDepth2, colref2


    pop esi
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 20





_SetPixelD@20:      ;pScreenStruct, pixX, pixY, fDepth, colref
    push ebp
    mov ebp, esp
    push ebx

    mov ebx, [ebp + 8]


    ;Get depth buffer row offset index
    mov eax, dword  [ebx + 4*1]
    mov ecx, dword [ebp + 8 + 4*2]
    mul ecx 
    shl eax, 2
    

    ;get depth buffer pointer
    mov edx, dword [ebx + 4*4]
    
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

    mov edx, dword [ebx]
    push edx
    mov eax, dword [ebx + 0x0C]
    mov ecx, dword [ebp + 8 + 4*2]
    mul ecx
    add dword [esp], eax
    mov eax, dword [ebx + 0x08]
    mov ecx, dword [ebp + 8 + 4*1]
    mul ecx
    add dword [esp], eax
    pop edx
    ;get index ^^^^

    ;get to work setting colours
    mov ecx, dword [edx]
    and ecx, 0xFF000000
    or ecx, dword [ebp + 8 + 4*4]
    mov dword [edx], ecx


PixelD_exit:
    pop ebx
    mov esp, ebp
    pop ebp
    ret 20




_Bresenham@36: ;pScreenStruct, pixX1, pixY1, fDepth1, colref1, pixX2, pixY2, fDepth2, colref2
    push ebp
    mov ebp, esp
    sub esp, 20 ;ebp - 4 = adjust; ebp - 8 = x; ebp - 12 = y; tmp; diff depth
    mov dword [ebp-4], 1
    push esi
    ;rise
    push edi
    ;run
    push ebx

    mov edi, [ebp + 8 + 4*6]
    sub edi, [ebp + 8 + 4*2]
    push edi
    sar edi, 31
    xor dword [esp], edi
    sub dword [esp], edi
    pop edi

    mov ebx, [ebp + 8 + 4*5]
    sub ebx, [ebp + 8 + 4*1]
    push ebx
    sar ebx, 31
    xor dword [esp], ebx
    sub dword [esp], ebx
    pop ebx
    
    cmp edi, ebx
    ja Bresenham_UseYAxis
                ;Check if x1 < x2 
                mov eax, dword [ebp + 8 + 4*1]
                mov edx, dword [ebp + 8 + 4*5]
                cmp eax, edx
                jle Bresenham_skipSwapX

                mov dword [ebp + 8 + 4*5], eax
                mov dword [ebp + 8 + 4*1], edx

                mov eax, dword [ebp + 8 + 4*2]
                mov edx, dword [ebp + 8 + 4*6]

                mov dword [ebp + 8 + 4*6], eax
                mov dword [ebp + 8 + 4*2], edx

                mov eax, dword [ebp + 8 + 4*3]
                mov edx, dword [ebp + 8 + 4*7]

                mov dword [ebp + 8 + 4*7], eax
                mov dword [ebp + 8 + 4*3], edx

                mov eax, dword [ebp + 8 + 4*4]
                mov edx, dword [ebp + 8 + 4*8]

                mov dword [ebp + 8 + 4*8], eax
                mov dword [ebp + 8 + 4*4], edx
            Bresenham_skipSwapX:  

                mov eax, dword [ebp + 8 + 4*1]
                mov dword [ebp - 8], eax

                mov eax, dword [ebp + 8 + 4*2]
                mov dword [ebp - 12], eax



                mov edi, [ebp + 8 + 4*6]
                sub edi, [ebp + 8 + 4*2]

                cmp edi, 0
                jge Bresenham_SkipSetSlopeX
                mov dword [ebp - 4], -1

            Bresenham_SkipSetSlopeX:

                push edi
                sar edi, 31
                xor dword [esp], edi
                sub dword [esp], edi
                pop edi



                ;load fDepth2
                lea eax, [ebp + 8 + 4*7]
                fld dword [eax]
                ;sub fDepth1
                lea eax, [ebp + 8 + 4*3]
                fsub dword [eax]
                lea eax, [ebp - 20]
                fstp dword [eax]




                mov ebx, [ebp + 8 + 4*5]
                sub ebx, [ebp + 8 + 4*1]
                shl edi, 1



                ;threshold = run = ebx

                ;error = esi

                mov esi, dword 0
            BresenhamX_lp:
                mov eax, dword [ebp - 8]
                cmp eax, dword [ebp + 8 + 4*5]
                ja Bresenham_exit

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
                push dword 0
                fist dword [esp]

                lea eax, [ebp - 20]
                ;multiply fraction by diff
                fmul dword [eax]
                lea eax, [ebp + 8 + 4*3]
                fadd dword [eax]

                add esp, 4

                push dword [ebp + 8 + 4*8]
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
                    ;Check if y1 < y2 
                mov eax, dword [ebp + 8 + 4*2]
                mov edx, dword [ebp + 8 + 4*6]
                cmp eax, edx
                jle Bresenham_skipSwapY

                mov dword [ebp + 8 + 4*6], eax
                mov dword [ebp + 8 + 4*2], edx

                mov eax, dword [ebp + 8 + 4*1]
                mov edx, dword [ebp + 8 + 4*5]

                mov dword [ebp + 8 + 4*5], eax
                mov dword [ebp + 8 + 4*1], edx

                mov eax, dword [ebp + 8 + 4*3]
                mov edx, dword [ebp + 8 + 4*7]

                mov dword [ebp + 8 + 4*7], eax
                mov dword [ebp + 8 + 4*3], edx

                mov eax, dword [ebp + 8 + 4*4]
                mov edx, dword [ebp + 8 + 4*8]

                mov dword [ebp + 8 + 4*8], eax
                mov dword [ebp + 8 + 4*4], edx
            Bresenham_skipSwapY:  

                mov eax, dword [ebp + 8 + 4*1]
                mov dword [ebp - 12], eax

                mov eax, dword [ebp + 8 + 4*2]
                mov dword [ebp - 8], eax



                mov edi, [ebp + 8 + 4*5]
                sub edi, [ebp + 8 + 4*1]

                cmp edi, 0
                jge Bresenham_SkipSetSlopeY
                mov dword [ebp - 4], -1

            Bresenham_SkipSetSlopeY:

                push edi
                sar edi, 31
                xor dword [esp], edi
                sub dword [esp], edi
                pop edi



                ;load fDepth2
                lea eax, [ebp + 8 + 4*7]
                fld dword [eax]
                ;sub fDepth1
                lea eax, [ebp + 8 + 4*3]
                fsub dword [eax]
                lea eax, [ebp - 20]
                fstp dword [eax]




                mov ebx, [ebp + 8 + 4*6]
                sub ebx, [ebp + 8 + 4*2]
                shl edi, 1



                ;threshold = run = ebx

                ;error = esi

                mov esi, dword 0
            BresenhamY_lp:
                mov eax, dword [ebp - 8]
                cmp eax, dword [ebp + 8 + 4*6]
                ja Bresenham_exit

                ;interpolate pixel depth

                ;load y
                lea eax, [ebp - 8]
                fild dword [eax]

                ;get dist along y
                lea eax, [ebp + 8 + 4*2]
                fisub dword [eax]

                ;div by rise
                lea eax, [ebp - 16]
                mov dword [eax], ebx
                fidiv dword [eax]
                push dword 0
                fist dword [esp]

                lea eax, [ebp - 20]
                ;multiply fraction by diff
                fmul dword [eax]
                lea eax, [ebp + 8 + 4*3]
                fadd dword [eax]

                add esp, 4

                push dword [ebp + 8 + 4*8]
                push dword 0
                fstp dword [esp]
                push dword [ebp - 8]
                push dword [ebp - 12]
                push dword [ebp + 8]
                call _SetPixelD@20

                add dword [ebp - 8], 1

                add esi, edi
                cmp esi, ebx
                jl BresenhamY_lp

                shl ebx, 1
                sub esi, ebx
                shr ebx, 1

                mov eax, dword [ebp - 4]
                add dword [ebp - 12], eax
                jmp BresenhamY_lp
    

Bresenham_exit:

    pop ebx
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret 36
