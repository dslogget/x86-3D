    %include "WIN32N.INC"
    %include "WIN32FUNCS.INC"
    %include "Matrix.inc"
    %include "test.inc"
    %include "StringFuncs.inc"

    global _SetPixelD@20
    global _Bresenham@36
    global _DrawTriangle@20
    global _FillTriangle@20
    global _ProcessTriangle@20  ;pScreenStruct, pTransformMatrix, pVertices, pIndices colref

    section .data

    section .rdata
LIGHTPRODCONSTX: dd 0.0
LIGHTPRODCONSTY: dd 0.0
LIGHTPRODCONSTZ: dd 1.0


    section .bss

    section .text

_FillTriangle@20: ;pScreen, pVec1, pVec2, pVec3, col
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
        ;Split triangle into two flat top/bottom if not already

    ;sort vertices y value
    ;   sort v0 v1
    ;   sort v1 v2
    ;   sort v0 v1

    mov eax, dword [ebp + 8 + 4*1]
    mov ecx, dword [ebp + 8 + 4*2]
    mov esi, dword [ebp + 8 + 4*3]

    mov ebx, [eax + 4*1]
    mov edx, [ecx + 4*1]
    mov edi, [esi + 4*1]

;sorting
    cmp ebx, edx
    jg FillTriangle_SkipSort1
    xchg ebx, edx
    xchg eax, ecx
FillTriangle_SkipSort1:

    cmp edx, edi
    jg FillTriangle_SkipSort2
    xchg edx, edi
    xchg ecx, esi
FillTriangle_SkipSort2:

    cmp ebx, edx
    jg FillTriangle_SkipSort3
    xchg ebx, edx
    xchg eax, ecx
FillTriangle_SkipSort3:
;sorting

    cmp ebx, edx
    je FillTriangle_FlatTop

    cmp edx, edi
    je FillTriangle_FlatBottom


    ;Calculate the other point for flat
    ;We know y value will be edx
    ;So what x-value will give a y of edx?
    ;([ecx + 4] - [eax + 4])/([esi + 4] - [eax + 4]) * ([esi] - [eax]) + [eax] = x
    sub esp, dword 4*3; For tmp point

    cvtsi2ss xmm0, edx
    cvtsi2ss xmm1, edi
    cvtsi2ss xmm2, [esi]

    cvtsi2ss xmm3, [eax]
    cvtsi2ss xmm4, ebx

    subss xmm2, xmm3
    subss xmm1, xmm4
    subss xmm0, xmm4
    divss xmm0, xmm1

    movss xmm4, xmm0
    ;Quotient

    mulss xmm0, xmm2
    addps xmm0, xmm3

    cvtss2si ebx, xmm0
    mov dword [esp], ebx
    mov dword [esp + 4], edx

    movss xmm0, [eax + 4*2]
    movss xmm1, [esi + 4*2]
    subss xmm0, xmm1
    mulss xmm0, xmm4
    addss xmm0, xmm1

    movss [esp + 4*2], xmm0
    mov ebx, esp

    push dword 0x0000FFFF
    push dword esi
    push dword ecx
    push dword ebx;[ebp + 8 + 4*1]
    push dword [ebp + 8 + 4*0]
    
    push dword 0x00FFFF00
    push dword eax
    push dword ecx
    push dword ebx;[ebp + 8 + 4*1]
    push dword [ebp + 8 + 4*0]
    call _DrawTriangle@20
    call _DrawTriangle@20

    add esp, dword 4*3

    jmp FillTriangle_Exit
FillTriangle_FlatTop:




    push dword 0x00FF0000
    push dword [ebp + 8 + 4*3]
    push dword [ebp + 8 + 4*2]
    push dword [ebp + 8 + 4*1]
    push dword [ebp + 8 + 4*0]
    call _DrawTriangle@20


    jmp FillTriangle_Exit
FillTriangle_FlatBottom:

    push dword 0x00000FF
    push dword [ebp + 8 + 4*3]
    push dword [ebp + 8 + 4*2]
    push dword [ebp + 8 + 4*1]
    push dword [ebp + 8 + 4*0]
    call _DrawTriangle@20

    jmp FillTriangle_Exit
FillTriangle_Exit:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 20







    ;ScreenStruct:
    ;pBmpBuf         0x00
    ;BmpBufPWidth     0x04
    ;bmpPB           0x08
    ;bmpBWidth       0x0C
    ;pDepthBuffer    0x10
    ;BmpBSize        0x14
_ProcessTriangle@20:  ;pScreenStruct, pTransformMatrix, pVertices, pIndices, colref
    push ebp
    mov ebp, esp
    push ebx
    push esi
    sub esp, dword 4*4*3 ;Allocate space for the resultant Triangle

            mov ebx, dword [ebp + 8 + 4*2]
            mov esi, dword [ebp + 8 + 4*3]

            mov ecx, dword [esi]
            add esi, dword 4
            shl ecx, 4
            lea eax, [esp + 4*4*0]
            push dword eax
            lea eax, [ebx + ecx]
            push eax
            push dword [ebp + 8 + 4*1]
            call _MultiplyMatVec@12

            mov ecx, esp
            lea eax, [esp + 4*4*0]
            push dword eax                  ;Vertex

            fld1
            fdiv dword [ecx + 4*4*0 + 4*3]
            push dword 0                    ;depth
            fstp dword [esp]

            lea eax, [ecx + 4*4*0]
            push dword 4                    ;nMembers
            push eax                        ;Vertex
            call _MultiplyVecFloat@16; pVec, nMembers, fFloat, pVecRes
            ;scale


            mov ecx, dword [esi]
            add esi, dword 4
            shl ecx, 4
            lea eax, [esp + 4*4*1]
            push dword eax
            lea eax, [ebx + ecx]
            push eax
            push dword [ebp + 8 + 4*1]
            call _MultiplyMatVec@12


            mov ecx, esp
            lea eax, [esp + 4*4*1]
            push dword eax                  ;Vertex

            fld1
            fdiv dword [ecx + 4*4*1 + 4*3]
            push dword 0                    ;depth
            fstp dword [esp]

            lea eax, [ecx + 4*4*1]
            push dword 4                    ;nMembers
            push eax                        ;Vertex
            call _MultiplyVecFloat@16; pVec, nMembers, fFloat, pVecRes
            ;scale

            mov ecx, dword [esi]
            add esi, dword 4
            shl ecx, 4
            lea eax, [esp + 4*4*2]
            push dword eax
            lea eax, [ebx + ecx]
            push eax
            push dword [ebp + 8 + 4*1]
            call _MultiplyMatVec@12

            mov ecx, esp
            test dword [ecx + 4*4*2 + 4*3], dword 0x80000000
            jnz ProcessTriangle_exit

            lea eax, [esp + 4*4*2]
            push dword eax                  ;Vertex


            fld1
            fdiv dword [ecx + 4*4*2 + 4*3]
            push dword 0                    ;depth
            fstp dword [esp]

            lea eax, [ecx + 4*4*2]
            push dword 4                    ;nMembers
            push eax                        ;Vertex
            call _MultiplyVecFloat@16; pVec, nMembers, fFloat, pVecRes
            ;scale



            ;GetNormal and cull
            ;v0 - v1
            ;cross
            ;v2 - v1
            ;extract vRes Z value
            ;if neg render

            mov ebx, esp ; vertices
            sub esp, 4*4*3
            mov esi, esp ; Vecs
            
            lea eax, [esi + 4*4*2]
            push eax
            lea eax, [ebx + 4*4*1]
            push dword eax
            lea eax, [ebx + 4*4*0]
            push dword eax
            call _Sub3DVecVec@12

            lea eax, [esi + 4*4*1]
            push eax
            lea eax, [ebx + 4*4*1]
            push dword eax
            lea eax, [ebx + 4*4*2]
            push dword eax
            call _Sub3DVecVec@12

            lea eax, [esi + 4*4*0]
            push eax
            lea eax, [esi + 4*4*2]
            push dword eax
            lea eax, [esi + 4*4*1]
            push dword eax
            call _Cross3DVecVec@12



ProcessTriangle_if1:
            test dword [esi + 4*2], 0x80000000
            jz ProcessTriangle_endif1
            add esp, dword 4*4*3
            jmp ProcessTriangle_exit
ProcessTriangle_endif1:
            add esp, dword 4*4*3

    
            




            lea eax, [esp + 4*4*0]
            push eax
            push eax
            push dword [ebp + 8 + 4*0]
            call _ConvertToPixSpace@12

            lea eax, [esp + 4*4*1]
            push eax
            push eax
            push dword [ebp + 8 + 4*0]
            call _ConvertToPixSpace@12

            lea eax, [esp + 4*4*2]
            push eax
            push eax
            push dword [ebp + 8 + 4*0]
            call _ConvertToPixSpace@12



    ;Check all points are within screen

    mov ecx, dword 3*4*4
    mov ebx, dword [ebp + 8 + 4*0]
ProcessTriangle_CheckInBounds:
    mov edx, dword [esp + ecx - 1*4*4 + 4*0]

    cmp edx , dword 0
    jb ProcessTriangle_exit

    cmp edx, dword [ebx + 4*1]
    jae ProcessTriangle_exit

    mov edx, dword [esp + ecx - 1*4*4 + 4*1]

    cmp edx , dword 0
    jb ProcessTriangle_exit

    cmp edx, dword [ebx + 4*6]
    jae ProcessTriangle_exit


    sub ecx, dword 4*4
    jnz ProcessTriangle_CheckInBounds
        

    mov ecx, esp

    push dword [ebp + 8 + 4*4]
    lea eax, [ecx + 4*4*2]
    push dword eax
    lea eax, [ecx + 4*4*1]
    push dword eax
    lea eax, [ecx + 4*4*0]
    push dword eax
    push dword [ebp + 8 + 4*0]
    call _FillTriangle@20


ProcessTriangle_exit:
    add esp, dword 4*4*3
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 20




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
    xor edx, edx
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
    ;fld dword [ebp + 8 + 4*3] ;point depth = ST(0)
    movss xmm0, dword [ebp + 8 + 4*3]
    cmp dword [edx], dword 0
    je SetPixelD_else1
    comiss xmm0, [edx]
    ;fcomi

SetPixelD_if1:
    jb SetPixelD_else1                     
    ;fstp st0
    jmp PixelD_exit
SetPixelD_else1:
    ;fstp dword [edx]
    movss dword [edx], xmm0
    push dword [ebx]

    xor edx, edx
    mov eax, dword [ebx + 0x0C]
    mov ecx, dword [ebp + 8 + 4*2]
    mul ecx
    add dword [esp], eax
    xor edx, edx
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
                fld dword [ebp + 8 + 4*7]
                ;sub fDepth1
                fsub dword [ebp + 8 + 4*3]
                fstp dword [ebp - 20]




                mov ebx, [ebp + 8 + 4*5]
                sub ebx, [ebp + 8 + 4*1]
                shl edi, 1



                ;threshold = run = ebx

                ;error = esi

                xor esi, esi
            BresenhamX_lp:
                mov eax, dword [ebp - 8]
                cmp eax, dword [ebp + 8 + 4*5]
                ja Bresenham_exit

                ;interpolate pixel depth

                ;load x
                fild dword [ebp - 8]

                ;get dist along x
                lea eax, [ebp + 8 + 4*1]
                fisub dword [eax]

                ;div by run
                mov dword [ebp - 16], ebx
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
                fld dword [ebp + 8 + 4*7]
                ;sub fDepth1
                fsub dword [ebp + 8 + 4*3]
                fstp dword [ebp - 20]




                mov ebx, [ebp + 8 + 4*6]
                sub ebx, [ebp + 8 + 4*2]
                shl edi, 1



                ;threshold = run = ebx

                ;error = esi

                xor esi, esi
            BresenhamY_lp:
                mov eax, dword [ebp - 8]
                cmp eax, dword [ebp + 8 + 4*6]
                ja Bresenham_exit

                ;interpolate pixel depth

                ;load y
                fild dword [ebp - 8]

                ;get dist along y
                lea eax, [ebp + 8 + 4*2]
                fisub dword [eax]

                ;div by rise
                mov dword [ebp - 16], ebx
                fidiv dword [eax]
                push dword 0
                fist dword [esp]

                lea eax, [ebp - 20]
                ;multiply fraction by diff
                fmul dword [eax]
                fadd dword [ebp + 8 + 4*3]

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
