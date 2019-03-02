%include "asm_io.inc"

SECTION .data

pegBase: db "XXXXXXXXXXXXXXXXXXXXXX",10,0	; the base of the peg configuration
spaces: db "                  ",0		; spaces used to make the peg configuration look nice
pegWidth: dd 11					; half the width of the peg configuration


err1: db "incorrect number of command line arguments",10,0
err2: db "incorrect command line argument",10,0
msg1: db "Initial Configuration",10,0
msg2: db "Final Configuration",10,0

SECTION .bss

peg: resd 9    		; array to hold the disk values
disk1: resb 40 		; used to hold number of spaces on a disk (so the peg configuration is properly centered)
disk2: resb 40 		; used to display the number of disks, using "o"
diskNum: resd 4		; holds the # of disks inputted by the user


SECTION .text
	global asm_main

; Subprogram that displays the pegs
; @params: number of disks and the stack address
showp:
	enter 0,0
	pusha

	;# of disks at location ebp+8
	;address of peg at location ebp+12

	mov eax, [ebp+8]	; contains the # of disks

	; the peg must be printed from top to bottom. The top value is stored at the end of the peg array
	; Therefore, must move the address of the last value in the peg array into register, and work backwards through the array
	sub eax, dword 1
	mov ebx, dword 4
	mul ebx	
	mov ebx, [ebp+12]	; contains the address to the first peg
	add ebx, eax		; ebx now points to the last value in the peg array

	mov esi, [ebp+8]	; contains the # of disks

	; Outer Loop cycles through each of the disks and displays the number of disks on that disk
	OUTER_LOOP: cmp esi, dword 0
		je END_OUTER_LOOP
		
		mov eax, disk1	     ; eax points to beginning of disk1
		mov ecx, dword [ebx] ; size of the disk at that location
		
		; comoute required amount of spaces to keep the peg configuration centered
		; computed by subtracting the # of disks from pegWidth
		mov edi, dword 0
		mov edi, [pegWidth]
		sub edi, ecx	
	
		; a simple loop that adds the neccesary amount of spaces to the array disk1 (which eax points to)
		INNER_LOOP_1: cmp edi, dword 0
			je END_INNER_LOOP_1

				mov [eax], byte ' ' 
				inc eax
				dec edi
		
			jmp INNER_LOOP_1
		END_INNER_LOOP_1:
		mov [eax], dword 0 ; insert null character to declare end of disk1
		
		; same as previous loop, only adding the number of disks required for the specific peg
		mov eax, disk2
		mov edi, dword [ebx] ; size of the disk
			
		INNER_LOOP_2: cmp edi, dword 0
			je END_INNER_LOOP_2

				mov [eax], byte 'o' 
				inc eax
				dec edi
		
			jmp INNER_LOOP_2
		END_INNER_LOOP_2:
		mov [eax], dword 0 ; insert null character to declare end of disk2
		
		; display the disk
		mov eax, spaces
		call print_string
		mov eax, disk1
		call print_string
		mov eax, disk2
		call print_string
		mov al, byte '|'
		call print_char
		mov eax, disk2
		call print_string
		mov eax, disk1
		call print_string
		call print_nl		
		
		dec esi
		sub ebx, dword 4
	
		jmp OUTER_LOOP
	END_OUTER_LOOP:

	
	; display the base of the peg configuration, than wait for user input before continuing
	mov eax, spaces
	call print_string
	mov eax, pegBase
	call print_string
	call read_char	; wait untill user presses key before continuing
	
	popa
	leave
	ret


; Subprogram responsible for sorting of the pegs
; Please note that the program does not display the configuration during the swapping process, only after the swappimg ends.
sorthem:

	enter 0,0

	;# of disks at location ebp+8
	;address of peg at location ebp+12

	mov ecx, [ebp+8]
	mov ebx, [ebp+12]

	; only true after sorthem has recursivley called itself (# of disks - 1) times
	cmp ecx, 1
	je end_sorthem

	sub ecx, dword 1
	add ebx, dword 4 

	push ebx
	push ecx
	call sorthem
	pop ecx		; holds # of disks
	pop ebx		; holds address of a peg

	; this part of srthem is called after the recusion has finished going down and it's working its way back up
	; undo the subtraction/addition done previously
	add ecx, dword 1
	sub ebx, dword 4
	
	mov eax, ecx 	; store for later use

	; keep iterating through the loop until either the end is reached
	; or the peg of interest is in the right spot

	LOOP: cmp ecx, dword 1
		je END_LOOP
		
		mov esi, dword [ebx]		; holds current peg
		mov edi, dword [ebx+4]		; holds next peg

		cmp esi, edi
		ja END_LOOP   ; esi is larger than edi, disk is in the right spot, end loop
		; Not larger, swap the two
		mov [ebx], edi
		mov [ebx+4], esi		

		add ebx, dword 4
		dec ecx
		jmp LOOP
	END_LOOP:

	; see if ecx is equal to its value before the loop
	; if so, no swap was made, don't call showp
	cmp eax, ecx
	je end_sorthem
 
	mov eax, [diskNum] 	; grab the # of disks to pass to sortp
	push peg	
	push eax
	call showp
	add esp, 8
		
	end_sorthem:
	leave
	ret

asm_main:
	enter 0,0
	pusha

	;retreive the command line argument
	;There should only be 1 argument, a value between 2 and 9
	mov eax, dword [ebp+8]
	cmp eax, dword 2
	jne ERROR_1	

	mov ebx, dword [ebp+12]	; ebx points to argv[]
	mov ecx, dword [ebx+4]	;ecx points to argv[1]
	
	;byte [ecx+1] must be zero
	mov al, byte [ecx+1]
	cmp al, byte 0
	jne ERROR_2

	;check that argument is between 2 and 9
	mov al, byte [ecx]
	cmp al, '2'
	jb ERROR_2

	cmp al, '9'
	ja ERROR_2

	; Argument is good

	; call the subprogram rconf to create a random initial peg configuration
	mov eax, dword 0
	mov al, byte [ecx]
	sub al, '0'
	;now eax contains the argument value
	
	push eax	; push the number of disks onto the stack
	push peg 	; push the address of the array representing the peg onto the stack
	call rconf	; rconf messes up registers, so gotta re-get some values		
	add esp, 8

	mov ebx, dword [ebp+12]	; ebx points to argv[]
	mov ecx, dword [ebx+4]	; ecx points to argv[1]

	;print message
	call print_nl
	mov eax, spaces
	call print_string
	mov eax, msg1
	call print_string
	call print_nl
	
	mov eax, dword 0
	mov al, byte [ecx]
	sub al, '0'
	;now the value for the number of disks is in eax
	
	mov [diskNum], eax	; store the # of disks for later use

	; display the initial peg configuration
	push peg	; address of peg
	push eax	; # of disks
	call showp

	; pass the peg configuration to sorthem to be sorted
	; didn't move esp, so the values that we want to pass are still on the stack
	call sorthem

	; display message and final configuration
	mov eax, spaces
	call print_string
	mov eax, msg2
	call print_string
	call print_nl
	
	; didn't move esp, so the values that we want to pass are still on the stack
	call showp
	add esp, 8

	jmp MAIN_END

	ERROR_1:
		mov eax, err1
		call print_string
		jmp MAIN_END

	ERROR_2:
		mov eax, err2
		call print_string
		jmp MAIN_END

	MAIN_END:
		popa
		mov eax, 0
		leave
		ret

