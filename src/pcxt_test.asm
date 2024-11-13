        CPU 8086
        BITS 16

;Available Memory
; Dram memory
; 00000h-----+--------RAM 1MBytes
; F7FFFh-----|
; Eeprom memory
; F8000h-----+--------ROM 32KBytes
; F9000h-----|
; FA000h-----|
; FB000h-----|
; FC000h-----|
; FD000h-----|
; FE000h-----|
; FF000H-----|
; FFFFFh-----|


%imacro setloc  1.nolist
%assign pad_bytes (%1-($-$$)-START)
%if pad_bytes < 0
%assign over_bytes -pad_bytes
%error Preceding code extends beyond setloc location by over_bytes bytes
%endif
%if pad_bytes > 0
%warning Inserting pad_bytes bytes
 times  pad_bytes db 0FFh
%endif
%endm
;History
;

%define	START		0E000h		; BIOS starts at offset 08000h
%define DATE		'22/10/24'
%define MODEL_BYTE	0FEh		; IBM PC/XT
%define VERSION		'1.0.03'	; BIOS version

%define context_off  0x0
%define context_seg  0x2
%define context_len  0x4
%define context_val  0x6000

bioscseg	equ	0F000h
dramcseg        equ     06000h
biosdseg	equ	0040h

post_reg	equ	80h
serial_timeout	equ	7Ch	; byte[4] - serial port timeout values
equip_serial	equ	00h	; word[4] - addresses of serial ports
unused_reg	equ	0C0h	; used for hardware detection and I/O delays
equipment_list	equ	10h	; word - equpment list

reg_addr_dump   equ     0x0400
reg_buff_read   equ     0x0402  ; buffer 255 bytes
reg_counter     equ     0x0500  ; char counter in the buffer
reg_intr        equ     0x0501  ; next variable
reg_next_dumm   equ     0x0502  ; next variable

        org	START

           jmp     init

        ;setloc	0E000h

%define DATASEG 0x7000    ; Data Segment Same as stack until we add setting Segments to Monitor
%define USERCODESEG 0x7000    ; Data Segment Same as stack until we add setting Segments to Monitor
%define STACKSEG 0x7000   ; Stack Segment is current top of 512K RAM minus 256 bytes for Monitor use
%define MONCODESEG 0xF000 ; Monitor Code Segment

%define DIVIDE0VECTOR 0x0000 ; IP and CS for divide by 0
%define SINGLESTEPVECTOR 0x0004 ; IP and CS for Single Step
%define NMIVECTOR 0x0008  ; IP and CS for Non Maskable Interrupt
%define INT3VECTOR 0x000c ; IP and CS for INT 3 Software Interrupt
%define OVERFLOWVECTOR 0x0010 ; IP and CS for Overflow

init:
    cli
    xor ax,ax
    mov ds,ax  ; Interupt Vectors start at [0000:0000] and are 4 bytes each IP then CS

    MOV DI, 0 ; START AT 0 (ASSUMES DS IS SET UP)
    MOV CX, 255 ; DO 256 TIMES ; left the last vector for
FILL_A:
    MOV word [DI], UNWANTED_INT
    ADD DI, 4 ; FILL OFFSETS
    LOOP FILL_A
    MOV DI, 2 ; START AT 2
    MOV CX, 255 ; DO 256 TIMES
FILL_B:
    MOV word [DI], 0000h
    ADD DI, 4 ; FILL SEGMENTS
    LOOP FILL_B

; Define Divide by 0 error vector (Display Registers)
    mov [ds:DIVIDE0VECTOR], word dummy
    mov [ds:DIVIDE0VECTOR+2],word  MONCODESEG
; Define Single Step vector (Display Registers)
    mov [ds:SINGLESTEPVECTOR], word dummy
    mov [ds:SINGLESTEPVECTOR+2], word MONCODESEG
; Define NMI Vector and Code Segment
;   Set up NMI to point here
    mov [ds:NMIVECTOR], word dummy
    mov [ds:NMIVECTOR+2], word MONCODESEG
; Define Software Interrupt INT 3 Vector and Code Segment
    mov [ds:INT3VECTOR], word dummy
    mov [ds:INT3VECTOR+2], word MONCODESEG
; Define Overflow Error Vector and Code Segment (Display Registers)
    mov [ds:OVERFLOWVECTOR], word dummy
    mov [ds:OVERFLOWVECTOR+2], word MONCODESEG
     				; clear direction flag
        mov ax, 0x0000
        mov es, ax
        mov ax, 0x0000                  ; Segmento Stack
        mov ss, ax
        mov ax, 0xF000
        mov ds, ax
	mov cs, ax
        xor sp, sp


        ;PPI 99 PortA = input PortB = output PortC = input
        mov AL, 0x99
        out 0x63, AL


        jmp teste_uart



UNWANTED_INT:
        iret
dummy:
   ; Put rest of registers on the stack (now has Flags and dummy IP and CS if after reset)
   ; After INT 3 or NMI then Flags, CS and IP are on stack already
   ; pusha does not exist on 8088/8086!
   push sp  
   push ax
   push cx
   push dx
   push bx
   push bp
   push si
   push di
   ; Save User Program Stack pointer current value, is restored on Continue or set on GO   default FDFE
;   mov [ds:STACKSTART], sp; NMISR               sts      STACKSTART         ; Save current stack pointer at STACKSTART $13F8 (after NMI or RESET)
;;; PUT YOUR CODE HERE
;   mov sp, [ds:STACKSTART] ; Restore sp from end of push on NMI/INT 3   
   pop di
   pop si
   pop bp
   pop bx
   pop dx
   pop cx
   pop ax
   pop sp ; This should result in the same sp value before iret as is in STACKSTART
   iret            ;                  rti                        ; Return from interupt, which will load program counter from X value returned from BADDR
%include "DRV16C550_8088.asm"		
%include "screen.asm"	

        setloc	0FFF0h			; Power-On Entry Point
reset:
        jmp 0xF000:init

        setloc	0FFF5h			; ROM Date in ASCII
        db	DATE			; BIOS release date MM/DD/YY
        db	20h

        setloc	0FFFEh			; System Model byte
        db	MODEL_BYTE
        db	0ffh
