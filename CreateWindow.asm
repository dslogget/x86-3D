    
    global _init

    %include "test.inc"
    %include "LoadTriangles.inc"
    %include "StringFuncs.inc"
    %include "WIN32N.INC"
    %include "WIN32FUNCS.INC"
    %include "Drawing.inc"
    %include "Matrix.inc"



    %define classStyle 0x0020|0x0002|0x0001
    %define wndStyle 0x80000
    
    section .rdata
className db "MyWindowClass",0
settingsfile db "Settings.txt",0
tickspersec dd 1000

testTriangle    dd -0.5, -1.0, 0.0, 1.0
                dd 0.5, -1.0, 0.0, 1.0
                dd 0.0, 0.0, 0.5, 1.0

fov dd 90.0
ffar dd 100.0
fnear dd 0.5





    section .data

poleBottom dd 0.0, 0.0, 0.0, 1.0
poleTop dd 0.0, -1.0, 0.0, 1.0

angle: dd 0
angularSpeed: dd 0.05


hWind   dd 0

windowHeight:    dd 500
windowWidth:     dd 500

clientHeight    dd 500
clientWidth     dd 500



ScreenStruct:
pBmpBuf         dd 0
BmpBufPWidth    dd 0
bmpPB           dd 3
bmpBWidth       dd 0
pDepthBuffer    dd 0
BmpBSize        dd 0
BmpBufPHeight   dd 0

lastRedraw      dd 0
deltaTime       dd 0

DepthBufferSize dd 0

depth dd 0.5
depth2 dd 0.25
depth3 dd 0.75

lineY dd 10


hInst dd 0
pVertices   dd 0
nVertices   dd 0
pMeshes     dd 0
nMeshes     dd 0

    section .bss
titlebuf resb 50

bmpinfo:
bmpinfoheader:
bih_biSize:             resd 1
bih_biWidth:            resd 1
bih_biHeight:           resd 1
bih_biPlanes:           resw 1
bih_biBitCount:         resw 1
bih_biCompression:      resd 1
bih_biSizeImage:        resd 1
bih_biXPelsPerMeter:    resd 1
bih_biYPelsPerMeter:    resd 1
bih_biClrUsed:          resd 1
bih_biClrImportant:     resd 1
bmpinfoheader_size equ $-bmpinfoheader
    resd 2
bmpinfo_size equ $-bmpinfo


ViewMatrix: resd 4*4

TranslationMatrix: resd 4*4

TransformMatrix: resd 4*4

RotationMatrix: resd 4*4








    section .text

_wndProc@16:
    push ebp
    mov ebp, esp

    push ebx
    push esi
    push edi

    mov eax, dword 0


    mov ebx, dword [ebp + 12]

    xor ebx, dword WM_CREATE
    jz case1
    xor ebx, dword WM_CREATE^WM_COMMAND
    jz case2
    xor ebx, dword WM_COMMAND^WM_DESTROY
    jz case3
    xor ebx, dword WM_DESTROY^WM_PAINT
    jz case4
    xor ebx, dword WM_PAINT^WM_ERASEBKGND
    jz case5
    jmp dft
case1:
    sub esp, dword 4*4
    push esp
    push dword [ebp + 8]
    call _GetClientRect@8
    mov eax, dword [esp + 8]
    add eax, dword 1
    mov dword [clientWidth], eax
    mov dword [BmpBufPWidth], eax
    mov eax, dword [esp + 12]
    add eax, dword 1
    mov dword [clientHeight], eax
    mov dword [BmpBufPHeight], eax
    add esp, 4*4




    call _GetProcessHeap@0
    mov ecx, eax

    mov eax, 4
    mov ebx, dword [clientHeight]
    mul ebx
    mov ebx, dword [clientWidth]
    mul ebx

    mov dword [DepthBufferSize], eax

    push eax
    push 0
    push ecx
    call _HeapAlloc@12
    mov dword [pDepthBuffer], eax

    ;Setup bmpbuffer

        ;header
        push dword bmpinfo_size
        push dword 0x00
        push dword bmpinfo
        call _memset@12

        mov dword [bih_biSize], bmpinfoheader_size
        mov eax, dword [clientWidth]
        mov dword [bih_biWidth], eax
        mov eax, dword [clientHeight]
        neg eax
        mov dword [bih_biHeight], eax
        mov word [bih_biPlanes], 1
        mov word [bih_biBitCount], 24
        mov dword [bih_biCompression], BI_RGB

        mov eax, dword 0
        mov ax, word [bih_biBitCount]
        mov ecx, dword 8
        div ecx
        mov dword [bmpPB], eax

        mov ecx, dword [bih_biWidth]
        mul ecx
        add eax, dword 3
        and eax, dword -3
        mov dword [bmpBWidth], eax

        ;Get bytes to alloc
        mov ecx, dword [clientHeight]
        mul ecx

        mov edx, eax
        mov dword [BmpBSize], eax
        call _GetProcessHeap@0

        push edx
        push 0
        push eax
        call _HeapAlloc@12
        mov dword [pBmpBuf], eax


    push dword ViewMatrix
    push dword [ffar]
    push dword [fnear]
    push dword [clientHeight]
    push dword [clientWidth]
    push dword [fov]
    call _ConstructViewMatrix@32 ;HoriFOV, width, height, near, far, pMatToRet
    
    push dword 4*4*4
    push dword 0x00
    push dword TranslationMatrix
    call _memset@12

    fld1
    fst dword [TranslationMatrix + 16*0 + 4*0]
    fst dword [TranslationMatrix + 16*1 + 4*1]
    fst dword [TranslationMatrix + 16*2 + 4*2]
    fst dword [TranslationMatrix + 16*3 + 4*3]
    fst dword [TranslationMatrix + 16*1 + 4*3]
    fadd st0
    fadd st0
    fstp dword [TranslationMatrix + 16*2 + 4*3]


    push dword [clientHeight]
    push dword [clientWidth]
    push nMeshes
    push pMeshes
    push nVertices
    push pVertices
    call _LoadTriangles@24 ;ppVertices, pnVertices, ppMeshes, pnMeshes, screenwidth, screenheight
    jmp break
case2:
    jmp break
case3:
 

    push dword 0
    call _PostQuitMessage@4
    mov eax, dword 0
    jmp break


case4:
    sub esp, 148
    mov esi, esp

    push dword esi
    lea ebx, [ebp + 8]
    push dword [ebx]
    call _BeginPaint@8
    push dword 0 ;hBMP


    cmp eax, 0
    jne skip
    call _GetLastError@0
    call _printEAX
    call _debug
skip:
    ;setup screenbuffer
    push dword [DepthBufferSize]
    push dword 0x00
    push dword [pDepthBuffer]
    call _memset@12

    push dword [BmpBSize]
    push dword 0x00
    push dword [pBmpBuf]
    call _memset@12

    push dword [esi]
    call _CreateCompatibleDC@4
    mov edi, eax


    push dword [clientHeight]
    push dword [clientWidth]
    push dword [esi]
    call _CreateCompatibleBitmap@12
    push eax
    ;mov dword [esp], eax 

    push eax
    push edi
    call _SelectObject@8






    ;Draw Gradient Triangle

   ;push dword GRADIENT_FILL_TRIANGLE
   ;push dword [nMeshes]
   ;push dword [pMeshes]
   ;push dword [nVertices]
   ;push dword [pVertices]
   ;push dword edi
   ;call _GdiGradientFill@24

    cmp eax, 0
    jne skip2
    call _GetLastError@0
    call _printEAX
    call _debug
skip2:
            ;Apply Transform to Triangle and render it
    sub esp, dword 4*4*3 ;Allocate space for the resultant Triangle

    push dword RotationMatrix
    push dword [angle]
    call _ConstructRotationMatrixY@8

    push RotationMatrix
    push RotationMatrix
    push TranslationMatrix
    call _MultiplyMatMat@12

    push dword TransformMatrix
    push dword RotationMatrix
    push dword ViewMatrix
    call _MultiplyMatMat@12
    ;Form the transform matrix
    
            lea eax, [esp + 4*4*0]
            push dword eax
            push dword testTriangle + 4*4*0
            push dword TransformMatrix
            call _MultiplyMatVec@12

            mov ecx, esp
            lea eax, [esp + 4*4*0]
            push dword eax                  ;Vertex

            fld1
            lea eax, [ecx + 4*4*0 + 4*3]
            fdiv dword [eax]
            push dword 0                    ;depth
            fstp dword [esp]

            lea eax, [ecx + 4*4*0]
            push dword 4                    ;nMembers
            push eax                        ;Vertex
            call _MultiplyVecFloat@16; pVec, nMembers, fFloat, pVecRes
            ;scale

            lea eax, [esp + 4*4*0]
            push eax
            push eax
            push ScreenStruct
            call _ConvertToPixSpace@12


            lea eax, [esp + 4*4*1]
            push dword eax
            push dword testTriangle + 4*4*1
            push dword TransformMatrix
            call _MultiplyMatVec@12

            mov ecx, esp
            lea eax, [esp + 4*4*1]
            push dword eax                  ;Vertex

            fld1
            lea eax, [ecx + 4*4*1 + 4*3]
            fdiv dword [eax]
            push dword 0                    ;depth
            fstp dword [esp]

            lea eax, [ecx + 4*4*1]
            push dword 4                    ;nMembers
            push eax                        ;Vertex
            call _MultiplyVecFloat@16; pVec, nMembers, fFloat, pVecRes
            ;scale

            lea eax, [esp + 4*4*1]
            push eax
            push eax
            push ScreenStruct
            call _ConvertToPixSpace@12


            lea eax, [esp + 4*4*2]
            push dword eax
            push dword testTriangle + 4*4*2
            push dword TransformMatrix
            call _MultiplyMatVec@12

            mov ecx, esp
            lea eax, [esp + 4*4*2]
            push dword eax                  ;Vertex

            fld1
            lea eax, [ecx + 4*4*2 + 4*3]
            fdiv dword [eax]
            push dword 0                    ;depth
            fstp dword [esp]

            lea eax, [ecx + 4*4*2]
            push dword 4                    ;nMembers
            push eax                        ;Vertex
            call _MultiplyVecFloat@16; pVec, nMembers, fFloat, pVecRes
            ;scale

            lea eax, [esp + 4*4*2]
            push eax
            push eax
            push ScreenStruct
            call _ConvertToPixSpace@12

    mov ecx, esp

    push dword 0x00FFFFFF
    lea eax, [ecx + 4*4*2]
    push dword eax
    lea eax, [ecx + 4*4*1]
    push dword eax
    lea eax, [ecx + 4*4*0]
    push dword eax
    push ScreenStruct
    call _DrawTriangle@20
    ;draw pole 

            lea eax, [esp + 4*4*0]
            push dword eax
            push dword poleTop 
            push dword TransformMatrix
            call _MultiplyMatVec@12

            mov ecx, esp
            lea eax, [esp + 4*4*0]
            push dword eax                  ;Vertex

            fld1
            lea eax, [ecx + 4*4*0 + 4*3]
            fdiv dword [eax]
            push dword 0                    ;depth
            fstp dword [esp]

            lea eax, [ecx + 4*4*0]
            push dword 4                    ;nMembers
            push eax                        ;Vertex
            call _MultiplyVecFloat@16; pVec, nMembers, fFloat, pVecRes
            ;scale

            lea eax, [esp + 4*4*0]
            push eax
            push eax
            push ScreenStruct
            call _ConvertToPixSpace@12

            lea eax, [esp + 4*4*1]
            push dword eax
            push dword poleBottom
            push dword TransformMatrix
            call _MultiplyMatVec@12

            mov ecx, esp
            lea eax, [esp + 4*4*1]
            push dword eax                  ;Vertex

            fld1
            lea eax, [ecx + 4*4*1 + 4*3]
            fdiv dword [eax]
            push dword 0                    ;depth
            fstp dword [esp]

            lea eax, [ecx + 4*4*1]
            push dword 4                    ;nMembers
            push eax                        ;Vertex
            call _MultiplyVecFloat@16; pVec, nMembers, fFloat, pVecRes
            ;scale

            lea eax, [esp + 4*4*1]
            push eax
            push eax
            push ScreenStruct
            call _ConvertToPixSpace@12


            mov ecx, esp
            push dword 0x00FF00FF
            push dword [ecx + 4*4*1 + 4*2]
            push dword [ecx + 4*4*1 + 4*1]
            push dword [ecx + 4*4*1 + 4*0]
            push dword 0x00FF00FF
            push dword [ecx + 4*4*0 + 4*2]
            push dword [ecx + 4*4*0 + 4*1]
            push dword [ecx + 4*4*0 + 4*0]
            push dword ScreenStruct
            call _Bresenham@36 ;pScreenStruct, pixX1, pixY1, fDepth1, colref1, pixX2, pixY2, fDepth2, colref2
            
            mov ecx, esp
            push dword 0x00FF00FF
            push dword [ecx + 4*4*1 + 4*2]
            push dword [ecx + 4*4*1 + 4*1]
            push dword [ecx + 4*4*1 + 4*0]
            add dword [esp], 1
            push dword 0x00FF00FF
            push dword [ecx + 4*4*0 + 4*2]
            push dword [ecx + 4*4*0 + 4*1]
            push dword [ecx + 4*4*0 + 4*0]
            add dword [esp], 1
            push dword ScreenStruct
            call _Bresenham@36 ;pScreenStruct, pixX1, pixY1, fDepth1, colref1, pixX2, pixY2, fDepth2, colref2

            mov ecx, esp
            push dword 0x00FF00FF
            push dword [ecx + 4*4*1 + 4*2]
            push dword [ecx + 4*4*1 + 4*1]
            push dword [ecx + 4*4*1 + 4*0]
            sub dword [esp], 1
            push dword 0x00FF00FF
            push dword [ecx + 4*4*0 + 4*2]
            push dword [ecx + 4*4*0 + 4*1]
            push dword [ecx + 4*4*0 + 4*0]
            sub dword [esp], 1
            push dword ScreenStruct
            call _Bresenham@36 ;pScreenStruct, pixX1, pixY1, fDepth1, colref1, pixX2, pixY2, fDepth2, colref2







    add esp, 4*4*3
















;
    ;mov eax, dword [depth]
    ;sub esp, dword 4*3*3
;
    ;mov edx, dword [lineY]
    ;mov dword [esp + 4*0], edx
    ;mov dword [esp + 4*1], edx
    ;mov dword [esp + 4*2], eax
;
    ;mov dword [esp + 4*3], 100
    ;mov dword [esp + 4*4], 300
    ;mov dword [esp + 4*5], eax
;
    ;mov dword [esp + 4*6], 200
    ;mov dword [esp + 4*7], 150
    ;mov dword [esp + 4*8], eax
;
    ;push dword 0x00FFFFFF
    ;lea eax, [esp + 4*3*2 + 4*1]
    ;push dword eax
    ;lea eax, [esp + 4*3*1 + 4*2]
    ;push dword eax
    ;lea eax, [esp + 4*3*0 + 4*3]
    ;push dword eax
    ;push ScreenStruct
    ;call _DrawTriangle@20
    ;add esp, dword 4*3*3
;
;


    ;push dword 0x00FFFF00
    ;push dword [depth3]
    ;push dword 151
    ;push dword 1279
    ;push dword 0x00FFFF00
    ;push dword [depth3]
    ;push dword 151
    ;push dword 0
    ;push ScreenStruct
    ;call _Bresenham@36

    ;SETDIBITS

    pop eax

    push dword 0
    push dword bmpinfo
    push dword [pBmpBuf]
    push dword [clientHeight]
    push dword 0
    push eax
    push edi
    call _SetDIBits@28





    ;bitblt
    push dword SRCCOPY
    push dword 0
    push dword 0
    push edi
    push dword [clientHeight]
    push dword [clientWidth]
    push dword 0
    push dword 0
    push dword [esi]
    call _BitBlt@36

    ;deleteDC
    push edi
    call _DeleteDC@4

    ;call _debug

endp:
    push dword esi
    push dword [ebx]
    call _EndPaint@8



    
    add esp, 148
    jmp break
case5:
    jmp break
dft:
    lea eax, [ebp + 20]
    push dword [eax]
    sub eax, 4
    push dword [eax]
    sub eax, 4
    push dword [eax]
    sub eax, 4
    push dword [eax]
    call _DefWindowProcA@16
    jmp pexit
break:
    mov eax, dword 0
pexit:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 16




_init:
    push ebp
    mov ebp, esp
    push ebx


    push dword 0
    push esp
    push settingsfile
    call _ReadNextNumber@8
    mov [windowWidth], dword eax

    push esp
    push settingsfile
    call _ReadNextNumber@8
    mov [windowHeight], dword eax
    add esp, 4
    call _CloseFileHandle@0
    

    push dword 0
    call _GetModuleHandleA@4
    mov [hInst], eax

    sub esp, 40
    mov ebx, esp
        mov [ebx + 00], dword classStyle
        mov [ebx + 04], dword _wndProc@16
        mov [ebx + 08], dword 0
        mov [ebx + 12], dword 0
        mov eax, dword [hInst]
        mov [ebx + 16], eax ;hInst
        mov [ebx + 20], dword 0

        push dword 32512
        push dword 0
        call _LoadCursorA@8
        ;call load cursor
        mov [ebx + 24], eax
        mov [ebx + 28], dword 1
        mov [ebx + 32], dword 0
        mov [ebx + 36], dword className
    
    push ebx
    call _RegisterClassA@4
    
    cmp eax, dword 0
    je exit

    push dword 0
    push dword [hInst] ;hInst
    push dword 0
    push dword 0
    push dword [windowHeight]
    push dword [windowWidth]
    push dword 0;0x80000000
    push dword 0;0x80000000
    push wndStyle
    push className
    push className
    push dword 0
    call _CreateWindowExA@48
    
    mov edx, eax
    mov dword [hWind], eax

    cmp edx, dword 0
    je exit

    push 1
    push edx
    call _ShowWindow@8


    sub esp, dword 24
    lea ebx, [esp]
lp:
    ;Peek message
    push dword PM_REMOVE
    push dword 0
    push dword 0
    push dword 0
    push ebx
    call _PeekMessageA@20
    cmp eax, dword 0
    je noMsg

    lea eax, [ebx + 4*1]
    cmp dword [eax], WM_QUIT
    je exit

    push ebx
    call _TranslateMessage@4
    push ebx
    call _DispatchMessageA@4

noMsg:

    call _GetTickCount@0
    sub eax, dword [lastRedraw]
    cmp eax, dword 16
    jb lp
    


    ;call _debug  

    push dword RDW_INVALIDATE | RDW_NOERASE | RDW_NOFRAME | RDW_INTERNALPAINT | RDW_UPDATENOW;RDW_INTERNALPAINT|RDW_ERASENOW|RDW_ALLCHILDREN
    push dword 0
    push dword 0
    push dword [hWind]
    call _RedrawWindow@16

    call _GetTickCount@0
    mov ecx, eax
    sub eax, dword [lastRedraw]
    mov dword [deltaTime], eax
    mov dword [lastRedraw], ecx

    ;speed = 1/10 per tick

    mov eax, dword 1
    mov ecx, dword [deltaTime]
    mul ecx
    mov ecx, 10
    div ecx
    add eax, dword [lineY]
    cmp eax, [clientHeight]
    jb rstend
    mov eax, dword 10
rstend:
    mov dword [lineY], eax

    ;update angle
    fld dword [angle]
    fld1
    fimul dword [deltaTime]
    fmul dword [angularSpeed]
    faddp
    fstp dword [angle]




    mov eax, dword [tickspersec]
    mov ecx, dword [deltaTime]
    add ecx, 1
    div ecx

    push dword [deltaTime]
    push dword titlebuf
    call _uitoa@8
    add eax, titlebuf
    mov [eax], dword 0

    push titlebuf
    push dword [hWind]
    call _SetWindowTextA@8



    ;INSERT CONTROL LOOP


    jmp lp 


    



exit:

    add esp, 64
    pop ebx
    mov esp, ebp
    pop ebp


    ret
