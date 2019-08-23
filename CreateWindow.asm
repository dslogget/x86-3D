    
    global _init

    %include "test.inc"
    %include "LoadTriangles.inc"
    %include "StringFuncs.inc"
    %include "WIN32N.INC"
    %include "WIN32FUNCS.INC"
    %include "Drawing.inc"
    %include "Matrix.inc"
    %include "FileLoading.inc"



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
ffar dd 200.0
fnear dd 0.5
DegPerRad   dd 57.295779513082320876798154





    section .data
player:
PlPos: dd 0.0, 0.0, 0.0
PlRot: dd 0.0, 0.0, 0.0
PlMoveSpeed: dd 0.005
PlRotSpeed: dd 0.1


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
BmpDWSize       dd 0

currrentTime    dq 0
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
PlayerMatrix: resd 4*4

ObjTransformMats:
TranslationMatrix: resd 4*4
RotationMatrix: resd 4*4

TransformMatrix: resd 4*4

FileReadBuf: resb 80









    section .text

_wndProc@16:
    push ebp
    mov ebp, esp

    push ebx
    push esi
    push edi

    xor eax, eax


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
    inc eax
    mov dword [clientWidth], eax
    mov dword [BmpBufPWidth], eax
    mov eax, dword [esp + 12]
    inc eax
    mov dword [clientHeight], eax
    mov dword [BmpBufPHeight], eax
    add esp, 4*4




    call _GetProcessHeap@0
    mov ecx, eax

    mov eax, dword [clientWidth]
    mov ebx, dword [clientHeight]
    mul ebx
    mov dword [DepthBufferSize], eax
    mov ebx, dword 4
    mul ebx


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

        xor eax, eax
        mov ax, word [bih_biBitCount]
        mov ecx, dword 8
        xor edx, edx
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

        mov eax, dword [BmpBSize]
        mov ecx, dword 4
        xor edx, edx
        div ecx
        mov dword [BmpDWSize], eax


    push dword ViewMatrix
    push dword [ffar]
    push dword [fnear]
    push dword [clientHeight]
    push dword [clientWidth]
    push dword [fov]
    call _ConstructViewMatrix@32 ;HoriFOV, width, height, near, far, pMatToRet
    
    push dword 4*4
    push dword 0x00000000
    push dword TranslationMatrix
    call _memsetDWORD@12

    push settingsfile
    call _OpenFileRead@4
    push eax

    push dword 80
    push FileReadBuf
    push dword eax
    call _ReadToNextLine@12

    mov eax, dword [esp]

    push dword 80
    push FileReadBuf
    push dword eax
    call _ReadToNextLine@12

    fld1
    fst dword [TranslationMatrix + 16*0 + 4*0]
    fst dword [TranslationMatrix + 16*1 + 4*1]
    fst dword [TranslationMatrix + 16*2 + 4*2]
    fst dword [TranslationMatrix + 16*3 + 4*3]
    fstp dword [TranslationMatrix + 16*1 + 4*3]
    
    mov eax, dword [esp]
    push FileReadBuf
    push eax
    call _ReadNumbers@8
    push FileReadBuf
    call _atof@4 ; x
    fstp dword [TranslationMatrix + 16*2 + 4*3]

    call _CloseHandle@4


    push nMeshes
    push pMeshes
    push nVertices
    push pVertices
    call _LoadTriangles@16
    jmp break
case2:
    jmp break
case3:
 

    push dword 0
    call _PostQuitMessage@4
    xor eax, eax
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
    call _memsetDWORD@12

    push dword [BmpDWSize]
    push dword 0x00
    push dword [pBmpBuf]
    call _memsetDWORD@12

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

    cmp eax, 0
    jne skip2
    call _GetLastError@0
    call _printEAX
    call _debug
skip2:
            ;Apply Transform to Triangle and render it
    sub esp, dword 4*4*3 ;Allocate space for the resultant Triangle/Pole

    push dword PlayerMatrix
    push dword player
    call _ConstructPlayerMatrix@8

    push dword RotationMatrix
    push dword [angle]
    call _ConstructRotationMatrixY@8

    push TransformMatrix
    push RotationMatrix
    push TranslationMatrix
    call _MultiplyMatMat@12

    push TransformMatrix
    push TransformMatrix
    push PlayerMatrix
    call _MultiplyMatMat@12 

    push dword TransformMatrix
    push dword TransformMatrix
    push dword ViewMatrix
    call _MultiplyMatMat@12

    ;Draw all tris
    mov ecx, dword [nMeshes]
draw_Tris:
    push ecx
        sub ecx, dword 1
        mov eax, ecx
        mov ecx, dword 12
        mul ecx

        push 0x00FFFFFF
        mov ecx, dword [pMeshes]
        add ecx, eax
        push dword ecx
        push dword [pVertices]
        push TransformMatrix
        push ScreenStruct
        call _ProcessTriangle@20  ;pScreenStruct, pTransformMatrix, pVertices, pIndices colref
    pop ecx
    sub ecx, dword 1
    jnz draw_Tris

    add esp, 4*4*3

    ;SETDIBITS

    mov eax, dword [esp]

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

    call _DeleteObject@4

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
    xor eax, eax
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

    ;call _GetTickCount@0
    ;sub eax, dword [lastRedraw]
    ;cmp eax, dword 16
    ;jb lp
    


    ;call _debug  

    push dword RDW_INVALIDATE | RDW_NOERASE | RDW_NOFRAME | RDW_INTERNALPAINT | RDW_UPDATENOW;RDW_INTERNALPAINT|RDW_ERASENOW|RDW_ALLCHILDREN
    push dword 0
    push dword 0
    push dword [hWind]
    call _RedrawWindow@16

    push dword currrentTime
    call _QueryPerformanceCounter@4
    mov ecx, dword [currrentTime]
    mov eax, ecx
    sub eax, dword [lastRedraw]
    mov dword [lastRedraw], ecx
    xor edx, edx
    mov ecx, dword 1000
    div ecx
    mov dword [deltaTime], eax

    ;speed = 1/10 per tick

    mov eax, dword 1
    mov ecx, dword [deltaTime]
    mul ecx
    mov ecx, 10
    xor edx, edx
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
    xor edx, edx
    div ecx

    fild dword [tickspersec]
    fidiv dword [deltaTime]
    push dword 0
    fistp dword [esp]
    push dword titlebuf
    call _uitoa@8
    add eax, titlebuf
    mov [eax], dword 0

    push titlebuf
    push dword [hWind]
    call _SetWindowTextA@8
    ;INSERT CONTROL LOOP

;KEYS
    fld dword [PlRot + 4*1]
    ;convert to rads
    fdiv dword [DegPerRad]
    fsincos 

    push dword 'W'
    call _GetAsyncKeyState@4

    test eax, dword 0x80000000
    jz No_W

    fld dword [PlPos + 4*2]
    fld dword [PlMoveSpeed]
    fimul dword [deltaTime]
    fmul st0, st2
    faddp  
    fstp dword [PlPos + 4*2]

    fld dword [PlPos + 4*0]
    fld dword [PlMoveSpeed]
    fimul dword [deltaTime]
    fmul st0, st3
    faddp  
    fstp dword [PlPos + 4*0]
    ;call _debug

No_W:

    push dword 'S'
    call _GetAsyncKeyState@4

    test eax, dword 0x80000000
    jz No_S

    fld dword [PlPos + 4*2]
    fld dword [PlMoveSpeed]
    fimul dword [deltaTime]
    fmul st0, st2
    fsubp  
    fstp dword [PlPos + 4*2]

    fld dword [PlPos + 4*0]
    fld dword [PlMoveSpeed]
    fimul dword [deltaTime]
    fmul st0, st3
    fsubp  
    fstp dword [PlPos + 4*0]
    ;call _debug

No_S:

    push dword 'A'
    call _GetAsyncKeyState@4

    test eax, dword 0x80000000
    jz No_A

    fld dword [PlPos + 4*2]
    fld dword [PlMoveSpeed]
    fimul dword [deltaTime]
    fmul st0, st3
    faddp  
    fstp dword [PlPos + 4*2]

    fld dword [PlPos + 4*0]
    fld dword [PlMoveSpeed]
    fimul dword [deltaTime]
    fmul st0, st2
    fsubp  
    fstp dword [PlPos + 4*0]
    ;call _debug

No_A:

    push dword 'D'
    call _GetAsyncKeyState@4

    test eax, dword 0x80000000
    jz No_D

    fld dword [PlPos + 4*2]
    fld dword [PlMoveSpeed]
    fimul dword [deltaTime]
    fmul st0, st3
    fsubp  
    fstp dword [PlPos + 4*2]

    fld dword [PlPos + 4*0]
    fld dword [PlMoveSpeed]
    fimul dword [deltaTime]
    fmul st0, st2
    faddp  
    fstp dword [PlPos + 4*0]
    ;call _debug

No_D:

    push dword VK_SPACE
    call _GetAsyncKeyState@4

    test eax, dword 0x80000000
    jz No_Space

    fld dword [PlPos + 4*1]
    fld dword [PlMoveSpeed]
    fimul dword [deltaTime]
    fsubp
    fstp dword [PlPos + 4*1]
    ;call _debug

No_Space:


    push dword 'C'
    call _GetAsyncKeyState@4

    test eax, dword 0x80000000
    jz No_C

    fld dword [PlPos + 4*1]
    fld dword [PlMoveSpeed]
    fimul dword [deltaTime]
    faddp
    fstp dword [PlPos + 4*1]
    ;call _debug
No_C:


    fstp st0
    fstp st0


    push dword 'Q'
    call _GetAsyncKeyState@4

    test eax, dword 0x80000000
    jz No_Q

    fld dword [PlRot + 4*1]
    fld dword [PlRotSpeed]
    fimul dword [deltaTime]
    fsubp
    fstp dword [PlRot + 4*1]
    ;call _debug
No_Q:

    push dword 'E'
    call _GetAsyncKeyState@4

    test eax, dword 0x80000000
    jz No_E

    fld dword [PlRot + 4*1]
    fld dword [PlRotSpeed]
    fimul dword [deltaTime]
    faddp
    fstp dword [PlRot + 4*1]
    ;call _debug
No_E:






    jmp lp 


    



exit:

    add esp, 64
    pop ebx
    mov esp, ebp
    pop ebp


    ret
