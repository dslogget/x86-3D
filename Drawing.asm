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
    global _FillFlatBottomTriangle@20

    section .data

    section .rdata
LIGHTPRODCONSTX: dd 0.0;0.0
LIGHTPRODCONSTY: dd 2.0
LIGHTPRODCONSTZ: dd 0.4;1.0

thresholdcos:    dd 0.05

testDepth dd 0.05


    section .bss

    section .text

_FillFlatBottomTriangle@20: ;pScreen, pVec1, pVec2, pVec3, col
    push ebp
    mov ebp, esp
    sub esp, dword 4*7
    push ebx
    push esi
    push edi
    mov eax, dword [ebp + 8 + 4*1]
    mov ebx, dword [ebp + 8 + 4*2]
    mov ecx, dword [ebp + 8 + 4*3]

    mov esi, dword [ebx + 4]

    cmp [eax + 4], esi
    jbe FillFlatTop
    mov edi, dword [eax + 4*1]
    mov dword [ebp - 4 - 4*4], edi
    jmp FillFlatEnd
FillFlatTop:
    mov dword [ebp - 4 - 4*4], esi 
    mov esi, [eax + 4*1]
FillFlatEnd:


    ;"left" side first
    cvtsi2ss xmm0, [eax + 4]
    cvtsi2ss xmm1, [eax]
    cvtsi2ss xmm2, [ebx + 4]
    cvtsi2ss xmm3, [ebx]
    ;then "right"
    cvtsi2ss xmm6, [eax + 4]
    cvtsi2ss xmm7, [eax]
    cvtsi2ss xmm4, [ecx + 4]
    cvtsi2ss xmm5, [ecx]

    subss xmm0, xmm2
    subss xmm1, xmm3
    divss xmm1, xmm0

    subss xmm6, xmm4
    subss xmm7, xmm5
    divss xmm7, xmm6

    ;rise/run * x + c = y
    ;rise*x + c*run - y*run = 0
    ;x = (y - y0)*run/rise 


    ;xmm0 (a.y - b.y)
    ;xmm1 (a.x - b.x)/(a.y - b.y)
    ;xmm2 b.y
    ;xmm3 b.x
    ;
    ;xmm4 c.y
    ;xmm5 c.x
    ;xmm6 (a.y - c.y)
    ;xmm7 (a.x - c.x)/(a.y - c.y)

    movss dword [ebp - 4 - 4*0], xmm1
    movss dword [ebp - 4 - 4*1], xmm7

    ;mov ebx, dword [ebx + 4]
    movss [ebp - 4 - 4*2], xmm2

    movss [ebp - 4 - 4*3], xmm4

    ;Calc depthdiff
    movss xmm2, [eax + 4*2];L
    movss xmm3, [ebx + 4*2]

    movss xmm4, xmm2
    movss xmm5, [ecx + 4*2]

    subss xmm2, xmm3
    subss xmm4, xmm5

    divss xmm2, xmm0
    divss xmm4, xmm6
    ;slopes for depth
    movss [ebp - 4 - 4*5], xmm2
    movss [ebp - 4 - 4*6], xmm4


    mov edi, [ebp + 8 + 4*3]

FillFlatBottomTriangle_lp1:
    ;x left 
    cvtsi2ss xmm0, esi
    cvtsi2ss xmm1, esi
    subss xmm0, [ebp - 4 - 4*2]
    subss xmm1, [ebp - 4 - 4*3]

    movss xmm2, xmm0
    movss xmm3, xmm1


    mulss xmm0, [ebp - 4 - 4*0]
    mulss xmm1, [ebp - 4 - 4*1]

    mulss xmm2, [ebp - 4 - 4*5]
    mulss xmm3, [ebp - 4 - 4*6]

    addss xmm2, [ebx + 4*2]
    addss xmm3, [edi + 4*2]

    cvtss2si eax, xmm0
    cvtss2si ecx, xmm1
    add eax, [ebx]
    add ecx, [edi]



    push dword [ebp + 8 + 4*4]
    push dword 0
    movss [esp], xmm3
    push dword esi
    push dword ecx
    push dword [ebp + 8 + 4*4]
    push dword 0 
    movss [esp], xmm2
    push dword esi
    push dword eax
    push dword [ebp + 8 + 4*0]
    call _Bresenham@36 ;pScreenStruct, pixX1, pixY1, fDepth1, colref1, pixX2, pixY2, fDepth2, colref2

    add esi, dword 1
    cmp esi, dword [ebp - 4 - 4*4]
    jne FillFlatBottomTriangle_lp1


    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 20


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

    subss xmm2, xmm3;c.x - a.x
    subss xmm1, xmm4;c.y - a.y
    subss xmm0, xmm4;b.y - a.y
    divss xmm0, xmm1;(b.y - a.y)/(c.y - a.y)

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

    push dword [ebp + 8 + 4*4]
    push dword ecx
    push dword ebx;[ebp + 8 + 4*1]
    push dword eax
    push dword [ebp + 8 + 4*0]
    push dword [ebp + 8 + 4*4]
    push dword ecx
    push dword ebx;[ebp + 8 + 4*1]
    push dword esi
    push dword [ebp + 8 + 4*0]
    call _FillFlatBottomTriangle@20
    call _FillFlatBottomTriangle@20

    add esp, dword 4*3

    jmp FillTriangle_Exit
FillTriangle_FlatTop:
    cmp edx, edi
    je FillTriangle_Exit


    push dword [ebp + 8 + 4*4]
    push dword eax
    push dword ecx
    push dword esi
    push dword [ebp + 8 + 4*0]
    call _FillFlatBottomTriangle@20



    jmp FillTriangle_Exit
FillTriangle_FlatBottom:
    cmp ebx, edx
    je FillTriangle_Exit

    push dword [ebp + 8 + 4*4]
    push dword esi
    push dword ecx
    push dword eax
    push dword [ebp + 8 + 4*0]
    call _FillFlatBottomTriangle@20


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

            push esi
            call _NormaliseVec3D@4


            push dword [LIGHTPRODCONSTZ]
            push dword [LIGHTPRODCONSTY]
            push dword [LIGHTPRODCONSTX]

            push esp
            push esi
            call _Dot3DVecVec@8
            fld dword [thresholdcos]
            fcomip st0, st1
            jb NotMax
            ;fmul st0, st0
            ;fmul st0, st0
            ;fmul st0, st0
            fstp st0
            fld dword [thresholdcos]

NotMax:

            ;Colour each component
            push dword 0

            movzx eax, byte [ebp + 8 + 4*4] 
            mov [esp], dword eax 
            fild dword [esp]
            fmul st0, st1
            fistp dword [esp]
            mov ecx, dword [esp]
            cmp ecx, dword 0x000000FF
            jb NotMaxR
            mov ecx, dword 0x000000FF
            NotMaxR:
            mov byte [ebp + 8 + 4*4], cl

            movzx eax, byte [ebp + 8 + 4*4 + 1] 
            mov [esp], dword eax 
            fild dword [esp]
            fmul st0, st1
            fistp dword [esp]
            mov ecx, dword [esp]
            cmp ecx, dword 0x000000FF
            jb NotMaxG
            mov ecx, dword 0x000000FF
            NotMaxG:
            mov byte [ebp + 8 + 4*4 + 1], cl

            movzx eax, byte [ebp + 8 + 4*4 + 2] 
            mov [esp], dword eax 
            fild dword [esp]
            fmulp
            fistp dword [esp]
            mov ecx, dword [esp]
            cmp ecx, dword 0x000000FF
            jb NotMaxB
            mov ecx, dword 0x000000FF
            NotMaxB:
            mov byte [ebp + 8 + 4*4 + 2], cl



            add esp, dword 4*1

            add esp, dword 4*3


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

    ;push dword 0x0000FF00
    ;lea eax, [ecx + 4*4*2]
    ;push dword eax
    ;lea eax, [ecx + 4*4*1]
    ;push dword eax
    ;lea eax, [ecx + 4*4*0]
    ;push dword eax
    ;push dword [ebp + 8 + 4*0]
    
    push dword [ebp + 8 + 4*4]
    lea eax, [ecx + 4*4*2]
    push dword eax
    lea eax, [ecx + 4*4*1]
    push dword eax
    lea eax, [ecx + 4*4*0]
    push dword eax
    push dword [ebp + 8 + 4*0]
    call _FillTriangle@20

    ;call _DrawTriangle@20


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
    push esi

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
    ;lea edx, [edx + 4*eax]
    shl eax, 2
    add edx, eax
    prefetcht0 [edx]

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
    ;push dword [ebx]
    mov esi, dword [ebx]

    mov eax, dword [ebx + 0x0C]
    mov ecx, dword [ebp + 8 + 4*2]
    mul ecx
    ;add dword [esp], eax
    add esi, eax
    mov eax, dword [ebx + 0x08]
    mov ecx, dword [ebp + 8 + 4*1]
    mul ecx
    ;add dword [esp], eax
    add esi, eax
    mov edx, esi
    ;pop edx
    ;get index ^^^^

    ;get to work setting colours
    mov ecx, dword [edx]
    and ecx, 0xFF000000
    or ecx, dword [ebp + 8 + 4*4]
    mov dword [edx], ecx


PixelD_exit:
    pop esi
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



                ;calc diff/run

                movss xmm4, [ebp + 8 + 4*7]
                subss xmm4, [ebp + 8 + 4*3]
                

                mov ebx, [ebp + 8 + 4*5]
                sub ebx, [ebp + 8 + 4*1]
                cvtsi2ss xmm3, ebx
                cmp ebx, dword 0
                je BresenhamX_DIV0
                divss xmm4, xmm3
                BresenhamX_DIV0:

                movss [ebp - 20], xmm4

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

                cvtsi2ss xmm0, [ebp - 8]
                cvtsi2ss xmm1, [ebp + 8 + 4*1]
                movss xmm2, [ebp + 8 + 4*3]
                movss xmm4, [ebp - 20]

                ;get dist along x  
                subss xmm0, xmm1

                ;mult by fraction diff/run
                mulss xmm0, xmm4
                addss xmm0, xmm2


                push dword [ebp + 8 + 4*8]
                sub esp, dword 4
                movss [esp], xmm0
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


                movss xmm4, [ebp + 8 + 4*7]
                subss xmm4, [ebp + 8 + 4*3]

                mov ebx, [ebp + 8 + 4*6]
                sub ebx, [ebp + 8 + 4*2]
                cvtsi2ss xmm3, ebx
                cmp ebx, dword 0
                je BresenhamY_DIV0
                divss xmm4, xmm3
                BresenhamY_DIV0:
                movss [ebp - 20], xmm4
                


                shl edi, 1



                ;threshold = rise = ebx

                ;error = esi

                xor esi, esi
            BresenhamY_lp:
                mov eax, dword [ebp - 8]
                cmp eax, dword [ebp + 8 + 4*6]
                ja Bresenham_exit



                ;interpolate pixel depth

                ;load y

                cvtsi2ss xmm0, [ebp - 8]
                cvtsi2ss xmm1, [ebp + 8 + 4*2]
                movss xmm2, [ebp + 8 + 4*3]
                movss xmm4, [ebp - 20]

                ;get dist along y  
                subss xmm0, xmm1

                ;mult by fraction diff/rise
                mulss xmm0, xmm4
                addss xmm0, xmm2


                push dword [ebp + 8 + 4*8]
                sub esp, dword 4
                movss [esp], xmm0
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
