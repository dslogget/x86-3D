    
    global _init

    %include "test.inc"
    %include "LoadTriangles.inc"
    %include "StringFuncs.inc"
    %include "WIN32N.INC"
    %include "WIN32FUNCS.INC"
    %include "Drawing.inc"



    %define classStyle 0x0020|0x0002|0x0001
    %define wndStyle 0x80000
    
    section .rdata
className db "MyWindowClass",0
settingsfile db "Settings.txt",0
tickspersec dd 1000

    section .data

RedrawSent dd 0

hWind   dd 0

windowHeight:    dd 500
windowWidth:     dd 500

ScreenStruct:
hdc             dd 0
clientHeight    dd 500
clientWidth     dd 500
pDepthBuffer    dd 0

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

    section .text

_wndProc@16:
    push ebp
    mov ebp, esp
    and esp, -4

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
    mov dword [clientWidth], eax
    mov eax, dword [esp + 12]
    mov dword [clientHeight], eax
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

    push dword [esi]
    call _CreateCompatibleDC@4
    mov edi, eax
    mov dword [hdc], edi


    push dword [clientHeight]
    push dword [clientWidth]
    push dword [esi]
    call _CreateCompatibleBitmap@12

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


    mov ecx, dword 200
drawline:
    push ecx

    push dword 0x00FFFF00
    push dword [depth2]
    push dword 150
    push dword 300
    add dword [esp], ecx
    push dword [depth3]
    push dword 75
    push dword 95
    add dword [esp], ecx
    push ScreenStruct
    call _Bresenham@32
    mov ecx, dword [esp]

    ;add ecx, dword 100
    ;push dword 0x00FF00FF
    ;push dword [depth]
    ;push dword [lineY]
    ;push dword ecx
    ;push dword ScreenStruct
    ;call _SetPixelD@20




    pop ecx
    loop drawline


    ;push dword 0x00FFFF00
    ;push dword [depth2]
    ;push dword 150
    ;push dword 300
    ;push dword [depth3]
    ;push dword 75
    ;push dword 95
    ;push ScreenStruct
    ;call _Bresenham@32




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
    mov dword [hdc], 0

    ;call _debug

endp:
    push dword esi
    push dword [ebx]
    call _EndPaint@8

    call _GetTickCount@0
    mov ecx, eax
    sub eax, dword [lastRedraw]
    mov dword [deltaTime], eax
    mov dword [lastRedraw], ecx


    
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

    
    


    ;call _debug  

    push dword RDW_INVALIDATE | RDW_NOERASE | RDW_NOFRAME| RDW_INTERNALPAINT | RDW_UPDATENOW;RDW_INTERNALPAINT|RDW_ERASENOW|RDW_ALLCHILDREN
    push dword 0
    push dword 0
    push dword [hWind]
    call _RedrawWindow@16

    ;speed = 1 per tick

    mov eax, dword 1
    mov ecx, dword [deltaTime]
    mul ecx
    add eax, dword [lineY]
    cmp eax, [clientHeight]
    jb rstend
    mov eax, 10
rstend:
    mov dword [lineY], eax

    mov eax, dword [tickspersec]
    mov ecx, dword [deltaTime]
    add ecx, 1
    div ecx
    push dword 0
    push eax
    push dword titlebuf
    call _uitoa@8

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
