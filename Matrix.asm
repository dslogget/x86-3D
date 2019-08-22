    ;Vector is 4d 
    ;Matrix will be made of 4 4d row vectors
    ;Values will be float
    ;Will be an array like structure 
    ;Will be using stdcall convention

    %include "StringFuncs.inc"



    global _MultiplyMatMat@12
    global _MultiplyMatVec@12
    global _ConstructViewMatrix@32
    global _Dot3DVecVec@8
    global _Cross3DVecVec@12
    global _Add3DVecVec@12
    global _Sub3DVecVec@12
    global _MultiplyVecFloat@16
    global _ConvertToPixSpace@12
    global _Matrix_Transpose@4
    global _ConstructRotationMatrixX@8
    global _ConstructRotationMatrixY@8
    global _ConstructRotationMatrixZ@8
    global _ConstructPlayerMatrix@8
   

    section .rdata

FOVConvFact dd 114.5915590261646417535963
DegPerRad   dd 57.295779513082320876798154


    section .data

    section .bss

    section .text

_ConstructPlayerMatrix@8: ; pPlayerStruct, pMatRet
    push ebp
    mov ebp, esp
    sub esp, dword 4*4*4 ;Temp Matrix
    push ebx
    push esi
    push edi

    ;ebx - temp mat
    lea ebx, [ebp - 4*4*4]
    ;edi - matRet
    mov edi, dword [ebp + 8 + 4*1]
    ;esi - player
    mov esi, dword [ebp + 8 + 4*0]

    push dword 4*4
    push dword 0x00000000
    push dword edi
    call _memsetDWORD@12

    fld1
    fst dword [edi + 16*0 + 4*0]
    fst dword [edi + 16*1 + 4*1]
    fst dword [edi + 16*2 + 4*2]
    fstp dword [edi + 16*3 + 4*3]

    ;translate
    mov eax, dword [esi + 12*0 + 4*0]
    xor eax, dword 0x80000000
    mov dword [edi + 16*0 + 4*3], eax

    mov eax, dword [esi + 12*0 + 4*1]
    xor eax, dword 0x80000000
    mov  dword [edi + 16*1 + 4*3], eax

    mov eax, dword [esi + 12*0 + 4*2]
    xor eax, dword 0x80000000
    mov dword [edi + 16*2 + 4*3], eax




    push ebx
    mov eax, dword [esi + 12*1 + 4*0]
    xor eax, dword 0x80000000
    push eax
    call _ConstructRotationMatrixX@8

    push edi
    push edi
    push ebx
    call _MultiplyMatMat@12



    push ebx
    mov eax, dword [esi + 12*1 + 4*1]
    xor eax, dword 0x80000000
    push eax
    call _ConstructRotationMatrixY@8

    push edi
    push edi
    push ebx
    call _MultiplyMatMat@12

    push ebx
    mov eax, dword [esi + 12*1 + 4*2]
    xor eax, dword 0x80000000
    push eax
    call _ConstructRotationMatrixZ@8

    push edi
    push edi
    push ebx
    call _MultiplyMatMat@12




    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 8




_ConstructRotationMatrixX@8: ;angle (degrees), pMatRet
    push ebp
    mov ebp, esp
    push dword 0 ;sine
    push dword 0 ;cosine

    push dword 4*4
    push dword 0x00000000
    push dword [ebp + 8 + 4*1]
    call _memsetDWORD@12

    fld dword [ebp + 8]
    fdiv dword [DegPerRad]
    fsincos

    fstp dword [ebp - 4 - 4*1]
    fstp dword [ebp - 4 - 4*0]

    mov eax, dword [ebp + 8 + 4*1]

    fld1
    fstp dword [eax + 16*0 + 4*0]

    mov ecx, dword [ebp - 4 - 4*0]
    mov dword [eax + 16*2 + 4*1], ecx
    xor ecx, 0x80000000
    mov dword [eax + 16*1 + 4*2], ecx

    mov ecx, dword [ebp - 4 - 4*1]
    mov dword [eax + 16*1 + 4*1], ecx
    mov dword [eax + 16*2 + 4*2], ecx

    fld1
    fstp dword [eax + 16*3 + 4*3]

    mov esp, ebp
    pop ebp
    ret 8


_ConstructRotationMatrixY@8: ;angle (degrees), pMatRet
    push ebp
    mov ebp, esp
    push dword 0 ;sine
    push dword 0 ;cosine

    push dword 4*4
    push dword 0x00
    push dword [ebp + 8 + 4*1]
    call _memsetDWORD@12

    fld dword [ebp + 8]
    fdiv dword [DegPerRad]
    fsincos

    fstp dword [ebp - 4 - 4*1]
    fstp dword [ebp - 4 - 4*0]

    mov eax, dword [ebp + 8 + 4*1]

    fld1
    fstp dword [eax + 16*1 + 4*1]

    mov ecx, dword [ebp - 4 - 4*0]
    mov dword [eax + 16*0 + 4*2], ecx
    xor ecx, 0x80000000
    mov dword [eax + 16*2 + 4*0], ecx

    mov ecx, dword [ebp - 4 - 4*1]
    mov dword [eax + 16*0 + 4*0], ecx
    mov dword [eax + 16*2 + 4*2], ecx

    fld1
    fstp dword [eax + 16*3 + 4*3]

    mov esp, ebp
    pop ebp
    ret 8

_ConstructRotationMatrixZ@8: ;angle (degrees), pMatRet
    push ebp
    mov ebp, esp
    push dword 0 ;sine
    push dword 0 ;cosine

    push dword 4*4
    push dword 0x00000000
    push dword [ebp + 8 + 4*1]
    call _memsetDWORD@12

    fld dword [ebp + 8]
    fdiv dword [DegPerRad]
    fsincos

    fstp dword [ebp - 4 - 4*1]
    fstp dword [ebp - 4 - 4*0]

    mov eax, dword [ebp + 8 + 4*1]

    fld1
    fstp dword [eax + 16*2 + 4*2]

    mov ecx, dword [ebp - 4 - 4*0]
    mov dword [eax + 16*1 + 4*0], ecx
    xor ecx, 0x80000000
    mov dword [eax + 16*0 + 4*1], ecx

    mov ecx, dword [ebp - 4 - 4*1]
    mov dword [eax + 16*0 + 4*0], ecx
    mov dword [eax + 16*1 + 4*1], ecx

    fld1
    fstp dword [eax + 16*3 + 4*3]

    mov esp, ebp
    pop ebp
    ret 8



_Matrix_Transpose@4:
    push ebp
    mov ebp, esp
    sub esp, ((4*4)*4) ;Cols of mat
    push ebx
    push edi

    ;get cols
    mov eax, dword [ebp + 8]
    mov ecx, dword 4
    mov edi, ebp

Matrix_Transpose_lp1:
    push ecx

    mov ecx, dword 4
Matrix_Transpose_lp2:
    push ecx
    shl ecx, 4
    lea edx, [edi]
    sub edx, ecx
    pop ecx

    push edi
    mov edi, dword [eax]
    mov dword [edx], edi
    pop edi

    add eax, dword 4

    loop Matrix_Transpose_lp2

    add edi, 4
    pop ecx
    loop Matrix_Transpose_lp1

    mov ecx, dword 4*4
    mov eax, dword [ebp + 8]
    lea ebx, [ebp - 4*4*4]

Matrix_Transpose_Cpy:
    mov edx, dword [ebx]
    mov dword [eax], edx
    add eax, dword 4
    add ebx, dword 4
    loop Matrix_Transpose_Cpy


    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4





_MultiplyVecFloat@16:; pVec, nMembers, fFloat, pVecRes
    push ebp
    mov ebp, esp
    push ebx

    mov eax, dword [ebp + 8 + 4*0]
    mov ecx, dword [ebp + 8 + 4*1]
    mov edx, dword [ebp + 8 + 4*3]
    lea ebx, [ebp + 8 + 4*2]
MultiplyVecFloat_lp:

    fld dword [eax]
    fmul dword [ebx]
    fstp dword [edx]
    add eax, dword 4
    add edx, dword 4

    loop MultiplyVecFloat_lp

    pop ebx
    mov esp, ebp
    pop ebp 
    ret 16

_ConvertToPixSpace@12:; pScreen, pVec, pVecRes
    push ebp
    mov ebp, esp

    mov eax, dword [ebp + 8 + 4*1]
    mov ecx, dword [ebp + 8 + 4*2]
    mov edx, dword [ebp + 8 + 4*0]
    add edx, dword 4

    fld1
    fadd dword [eax]
    push dword 2
    fidiv dword [esp]
    fimul dword [edx]
    fistp dword [ecx]

    add eax, dword 4
    add ecx, dword 4
    add edx, dword 4*5

    fld1
    fadd dword [eax]
    fidiv dword [esp]
    add esp, dword 4
    fimul dword [edx]
    fistp dword [ecx]

    add eax, dword 4
    add ecx, dword 4

    mov edx, dword [eax]
    mov dword [ecx], edx

    mov esp, ebp
    pop ebp
    ret 12

_Sub3DVecVec@12:; pVec1, pVec2, pVecRes
    push ebp
    mov ebp, esp
    sub esp, dword 4*4*1

    mov ecx, dword [ebp + 8 + 4*1]

    mov eax, dword [ecx + 4*0]
    xor eax, 0x80000000
    mov dword [esp + 4*0], eax

    mov eax, dword [ecx + 4*1]
    xor eax, 0x80000000
    mov dword [esp + 4*1], eax

    mov eax, dword [ecx + 4*2]
    xor eax, 0x80000000
    mov dword [esp + 4*2], eax

    mov eax, esp
    push dword [ebp + 8 + 4*2]
    push dword eax
    push dword [ebp + 8 + 4*0]
    call _Add3DVecVec@12

    mov esp, ebp
    pop ebp
    ret 12



_Add3DVecVec@12:; pVec1, pVec2, pVecRes
    push ebp
    mov ebp, esp

    mov eax, dword [ebp + 8 + 4*0]
    mov edx, dword [ebp + 8 + 4*1]
    mov ecx, dword [ebp + 8 + 4*2]

    
    fld dword [eax]
    fadd dword [edx]
    fstp dword [ecx]
    add eax, dword 4
    add edx, dword 4
    add ecx, dword 4
    fld dword [eax]
    fadd dword [edx]
    fstp dword [ecx]
    add eax, dword 4
    add edx, dword 4
    add ecx, dword 4
    fld dword [eax]
    fadd dword [edx]
    fstp dword [ecx]
    
    mov esp, ebp
    pop ebp
    ret 12

_Dot3DVecVec@8:; pVec1, pVec2; ret dotprod in ST0
    push ebp
    mov ebp, esp
    mov eax, dword [ebp + 8 + 4*0]
    mov ecx, dword [ebp + 8 + 4*1]

    fld dword [eax]
    fmul dword [ecx]
    add eax, dword 4
    add ecx, dword 4
    fld dword [eax]
    fmul dword [ecx]
    add eax, dword 4
    add ecx, dword 4
    fld dword [eax]
    fmul dword [ecx]
    faddp
    faddp

    mov esp, ebp
    pop ebp
    ret 8

_Cross3DVecVec@12: ; pVec1, pVec2; pVecRet
    push ebp
    mov ebp, esp
    push ebx

    mov eax, dword [ebp + 8 + 4*0]
    mov ebx, dword [ebp + 8 + 4*1]
    mov ecx, dword [ebp + 8 + 4*2]

    ;s1
    fld dword [eax + 4*1]
    fmul dword [ebx + 4*2]
    fld dword [eax + 4*2]
    fmul dword [ebx + 4*1]
    fsubrp
    fstp dword [ecx]
    add ecx, dword 4

    ;s2
    fld dword [eax + 4*2]
    fmul dword [ebx + 4*0]
    fld dword [eax + 4*0]
    fmul dword [ebx + 4*2]
    fsubrp
    fstp dword [ecx]
    add ecx, dword 4

    ;s3
    fld dword [eax + 4*0]
    fmul dword [ebx + 4*1]
    fld dword [eax + 4*1]
    fmul dword [ebx + 4*0]
    fsubrp
    fstp dword [ecx]

    
    pop ebx
    mov esp, ebp
    pop ebp
    ret 12


_ConstructViewMatrix@32: ;HoriFOV, width, height, near, far, pMatToRet
    push ebp
    mov ebp, esp

    push 4*4*4
    push dword 0
    push dword [ebp + 28]
    call _memset@12

    mov edx, [ebp + 28]
    
    ;convert HoriFOV to Rads and div by 2
    fld dword [ebp + 8]
    fdiv dword [FOVConvFact]
    ;take tangent
    fptan
    fdivrp
    ;invert
    fstp dword [edx + 0*16 + 0*4]

    ;input vertical
    fild dword [ebp + 12]
    fidiv dword [ebp + 16]
    fmul dword [edx + 0*16 + 0*4]
    fstp dword [edx + 1*16 + 1*4]

    fld dword [ebp + 20]
    lea eax, [ebp + 24]
    fsubr dword [eax]
    
    fdivr dword [eax]

    fst dword [edx + 2*16 + 2*4]
    fchs
    fmul dword [ebp + 20]
    fstp dword [edx + 2*16 + 3*4]

    fld1
    fstp dword [edx + 3*16 + 2*4]

    mov esp, ebp
    pop ebp
    ret 6*4



;This will multiply a 4x4 vec by a 4d col vec
_MultiplyMatVec@12: ; pMat, pVec, pVecToRet 
    push ebp
    mov ebp, esp
    push ebx


    mov edx, dword [ebp + 8 + 4*2] ; load return

    mov eax, dword [ebp + 8 + 4*0]  ; load mat
    mov ecx, dword 4
MultiplyMatVec_lp1:
    push ecx

    mov ecx, dword 4
    fldz
    mov ebx, dword [ebp + 8 + 4*1] ; load vec
MultiplyMatVec_lp2:
    fld dword [eax]                 ;load mat val
    add eax, 4                      
    fmul dword [ebx]                ;multiply by vec val
    add ebx, 4
    faddp                           ;add the result
    loop MultiplyMatVec_lp2

    fstp dword [edx]
    add edx, 4

    pop ecx
    loop MultiplyMatVec_lp1


    pop ebx
    mov esp, ebp
    pop ebp
    ret 12


_MultiplyMatMat@12: ; pMat1, pMat2, pMatToRet 
    push ebp
    mov ebp, esp
    sub esp, ((4*4)*4) ;Cols of mat2
    push ebx
    push edi

    ;get cols
    mov eax, dword [ebp + 12]
    mov ecx, dword 4
    mov edi, ebp

MultiplyMatMat_lp1:
    push ecx

    mov ecx, dword 4
MultiplyMatMat_lp2:
    push ecx
    shl ecx, 4
    lea edx, [edi]
    sub edx, ecx
    pop ecx

    push edi
    mov edi, dword [eax]
    mov dword [edx], edi
    pop edi

    add eax, dword 4

    loop MultiplyMatMat_lp2

    add edi, 4
    pop ecx
    loop MultiplyMatMat_lp1

    mov ecx, dword 4
    mov edi, [ebp + 8 + 4*2]
    
MultiplyMatMat_lp3:
    push ecx
    shl ecx, 4

    lea edx, [ebp]
    sub edx, ecx


    push dword edi
    push dword edx
    push dword [ebp + 8] 
    call _MultiplyMatVec@12

    add edi, dword 16
    pop ecx
    loop MultiplyMatMat_lp3

    push dword [ebp + 8 + 4*2]
    call _Matrix_Transpose@4

    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 12

    




