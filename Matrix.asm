    ;Vector is 4d 
    ;Matrix will be made of 4 4d row vectors
    ;Values will be float
    ;Will be an array like structure 
    ;Will be using stdcall convention

    %include "StringFuncs.inc"



    global _MultiplyMatMat@12
    global _MultiplyMatVec@12
    global _ConstructViewMatrix@32
   

    section .rdata

FOVConvFact dd 114.5915590261646417535963


    section .data

    section .bss

    section .text

_ConstructViewMatrix@32: ;HoriFOV, width, height, near, far, pMatToRet
    push ebp
    mov ebp, esp

    push 4*4*4
    push dword 0
    push dword [ebp + 28]
    call _memset@12

    mov edx, [ebp + 28]
    
    ;convert HoriFOV to Rads and div by 2
    lea eax, [ebp + 8]
    fld dword [eax]
    fdiv dword [FOVConvFact]
    ;take tangent
    fptan
    fdivrp
    ;invert
    lea eax, [edx + 0*16 + 0*4]
    fstp dword [eax]

    ;input vertical
    lea eax, [ebp + 12]
    fild dword [eax]
    lea eax, [ebp + 16]
    fidiv dword [eax]
    lea eax, [edx + 0*16 + 0*4]
    fmul dword [eax]
    lea eax, [edx + 1*16 + 1*4]
    fstp dword [eax]

    lea eax, [ebp + 20]
    fld dword [eax]
    lea eax, [ebp + 24]
    fsubr dword [eax]
    
    fdivr dword [eax]

    lea eax, [edx + 2*16 + 2*4]
    fst dword [eax]
    fchs
    lea eax, [ebp + 20]
    fmul dword [eax]
    lea eax, [edx + 2*16 + 3*4]
    fstp dword [eax]

    fld1
    lea eax, [edx + 3*16 + 2*4]
    fstp dword [eax]

    mov esp, ebp
    pop ebp
    ret 6*4



;This will multiply a 4x4 vec by a 4d col vec
_MultiplyMatVec@12: ; pMat, pVec, pVecToRet 
    push ebp
    mov ebp, esp
    push ebx


    mov edx, dword [ebp + 16]

    mov eax, dword [ebp + 8]
    mov ecx, dword 4
MultiplyMatVec_lp1:
    push ecx

    mov ecx, dword 4
    fldz
    mov ebx, dword [ebp + 12]
MultiplyMatVec_lp2:
    fld dword [eax]
    add eax, 4
    fmul dword [ebx]
    add ebx, 4
    faddp
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
    add ecx, ecx
    add ecx, ecx
    add ecx, ecx
    add ecx, ecx
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
    mov edi, [ebp + 16]
    
MultiplyMatMat_lp3:
    push ecx
    add ecx, ecx
    add ecx, ecx
    add ecx, ecx
    add ecx, ecx

    lea edx, [ebp]
    sub edx, ecx


    push dword edi
    add edi, dword 16 
    push dword edx
    push dword [ebp + 8] 
    call _MultiplyMatVec@12
    pop ecx
    loop MultiplyMatMat_lp3

    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 12

    




