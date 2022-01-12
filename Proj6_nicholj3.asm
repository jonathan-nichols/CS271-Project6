TITLE String Primitives and Macros     (Proj6_nicholj3.asm)

; Author: Jonathan Nichols
; Last Modified: 3/16/21
; OSU email address: nicholj3@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 3/14/21
; Description: Takes user input numbers, converts back and forth between string and integer,
;				and displays basic stats about the data.

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Displays a prompt, then gets the users input and stores it in memory.
;
; Preconditions: none
;
; Postconditions: none
;
; Receives:
;			prompt = address of the prompt
;			stringAddr = address to store input
;			bufferSize = number of bytes in the buffer
;			length = number of bytes entered
;			
;
; returns: 
;			stringAddr = generated string address
; ---------------------------------------------------------------------------------


mGetString MACRO prompt:REQ, stringAddr:REQ, bufferSize:REQ, inputLength:REQ

	; preserve registers
	push	EDX
	push	ECX
	push	EAX
	
	; output the prompt
	mov		EDX, prompt
	call	WriteString

	; read the string
	mov		EDX, stringAddr
	mov		ECX, bufferSize
	call	ReadString
	mov		inputLength, EAX

	; restore registers
	pop		EAX
	pop		ECX
	pop		EDX

ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Outputs the string stored a specified memory location.
;
; Preconditions: none
;
; Postconditions: none
;
; Receives:
;			stringAddr = address to store input
;			
; returns: none
; ---------------------------------------------------------------------------------

mDisplayString MACRO stringAddr:REQ

	; preserve register
	push	EDX

	; output the string
	mov		EDX, stringAddr
	call	WriteString

	; restore register
	pop		EDX

ENDM


.data

inputString	BYTE	13 DUP(0)
outString	BYTE	13 DUP(0)
revString	BYTE	13 DUP(0)
delimiter	BYTE	", ",0
inputNum	SDWORD	0
inputLen	DWORD	?
numArray	SDWORD	10 DUP(?)
lenArray	DWORD	10 DUP(?)
sum			SDWORD	0
average		SDWORD	0
intro		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",13,10,"Written by: Jonathan Nichols",13,10,13,10
			BYTE	"Please provide 10 signed decimal integers.",13,10,"Each number needs to be small enough to fit into a 32 bit register. "
			BYTE	"After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.",13,10,13,10,0
prompt1		BYTE	"Please enter a signed number: ",0
prompt2		BYTE	"Please try again: ",0
error		BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10,0
title1		BYTE	13,10,"You entered the following numbers: ",13,10,0
title2		BYTE	"The sum of these numbers is: ",0
title3		BYTE	"The rounded average is : ",0
goodbye		BYTE	"Thanks for playing!",13,10,0

.code
main PROC

	; introduce the program
	mDisplayString OFFSET intro

	; read values
	mov		ECX, 10
	mov		EDI, OFFSET numArray
_readLoop:
		push	OFFSET inputString
		push	SIZEOF inputString
		push	OFFSET inputNum
		push	OFFSET inputLen
		push	OFFSET prompt1
		push	OFFSET prompt2
		push	OFFSET error
		call	ReadVal	

		; store the results in the arrays
		mov		EDX, inputNum
		mov		[EDI], EDX
		add		EDI, TYPE numArray
	loop	_readLoop

	; calculate sum and average
	push	OFFSET numArray
	push	TYPE numArray
	push	OFFSET sum
	push	OFFSET average
	call	CalculateStats

	; display numbers
	mDisplayString OFFSET title1
	mov		ESI, OFFSET numArray

	; display the first number
	mov		EDX, [ESI]
	add		ESI, TYPE numArray
	push	EDX
	push	OFFSET outString
	push	OFFSET revString
	call	WriteVal

	; display the other numbers with the delimter
	mov		ECX, 9
_writeLoop:
		mDisplayString OFFSET delimiter
		mov		EDX, [ESI]
		add		ESI, TYPE numArray
		push	EDX
		push	OFFSET outString
		push	OFFSET revString
		call	WriteVal
		
	loop	_writeLoop

	call	Crlf
	call	Crlf

	; display sum
	mDisplayString OFFSET title2
	mov		EDX, sum
	push	EDX
	push	OFFSET outString
	push	OFFSET revString
	call	WriteVal

	call	Crlf
	call	Crlf

	; display average
	mDisplayString OFFSET title3
	mov		EDX, average
	push	EDX
	push	OFFSET outString
	push	OFFSET revString
	call	WriteVal

	call	Crlf
	call	Crlf

	; say goodbye
	mDisplayString OFFSET goodbye

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
; 
; Reads a string, validates that it can be converted to a 32bit signed integer,
;	then converts the string to int.
;
; Preconditions: none
;
; Postconditions: none
;
; Receives: 
;			[ebp+32] = address of input buffer
;			[ebp+28] = size of input buffer
;			[ebp+24] = address of input number
;			[ebp+20] = address of number length
;			[ebp+16] = address of prompt1
;			[ebp+12] = address of prompt2
;			[ebp+8] = address of error
;
; returns: The data variable inputNum.
; ---------------------------------------------------------------------------------

ReadVal PROC

	; preserve registers and assign static pointer
	push	EBP
	mov		EBP, ESP
	push	ESI
	push	EDI
	push	ECX
	push	EDX
	push	EAX
	push	EBX

	; get user input
	mGetString [EBP+16], [EBP+32], [EBP+28], [EBP+20]
	
_validate:


	; setup registers
	mov		ESI, [EBP+32]
	mov		EDI, [EBP+24]
	mov		ECX, [EBP+20]
	mov		EDX, 0
	mov		EBX, 1

	; length  must be greater than 1 and less than 12
	cmp		ECX, 1
	jle		_error
	cmp		ECX, 12
	jge		_error

	; check if first digit is a sign, otherwise assume positive and skip ahead
	lodsb	
	dec		ECX
	cmp		AL, '+'
	je		_nextChar
	cmp		AL, '-'
	je		_negativeSign
	inc		ECX
	jmp		_noSign
	
_negativeSign:
	mov		EBX, -1

_nextChar:

		lodsb

	_noSign:
		; make sure that next value is a digit, then convert to number
		cmp		AL, 48
		jl		_error
		cmp		AL, 57
		jg		_error
		sub		AL, 48	

		; multiply input number by 10
		push	EBX
		push	EAX
		mov		EAX, EDX
		mov		EDX, 0
		mov		EBX, 10
		imul	EBX
		cmp		EDX, 0			; EDX should stay zero if no overflow occurred
		jne		_error
		mov		EDX, EAX		; store the result back in EDX
		pop		EAX

		; add the new digit and check carry flag
		movsx	EBX, AL
		add		EDX, EBX
		jo		_overflow
		pop		EBX

	loop	_nextChar
	jmp		_valid

_overflow:
	; clean up the pushed register
	pop		EBX

_error:
	; reset number, display error message, and prompt for new string
	mov		EDX, 0
	mDisplayString [EBP+8]
	mGetString	[EBP+12], [EBP+32], [EBP+28], [EBP+20]
	jmp		_validate


_valid:
	; adjust if negative and store the value
	mov		EAX, EDX
	imul	EBX
	mov		[EDI], EAX

	; restore registers
	pop		EBX
	pop		EAX
	pop		EDX
	pop		ECX
	pop		EDI
	pop		ESI
	pop		EBP
	ret		28



ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: CalculateStats
; 
; Takes an array of signed integers, then calculates the sum and rounded average.
;
; Preconditions: none
;
; Postconditions: none
;
; Receives: 
;			[ebp+20] = address of numArray
;			[ebp+16] = type of numArray
;			[ebp+12] = address of sum
;			[ebp+8] = address of average
;
; returns: The data variables sum and average.
; ---------------------------------------------------------------------------------


CalculateStats PROC
	
	; preserve registers and assign static pointer
	push	EBP
	mov		EBP, ESP
	push	ESI
	push	EDI
	push	ECX
	push	EAX

	; setup registers for the sum loop
	mov		ESI, [EBP+20]
	mov		ECX, 10
	mov		EAX, 0

	; calculate the sum
_sumLoop:
		add		EAX, [ESI]
		add		ESI, [EBP+16]
	loop	_sumLoop

	; store the sum
	mov		EDI, [EBP+12]
	mov		[EDI], EAX

	; calculate the average
	mov		ECX, 10
	cdq	
	idiv	ECX
	
	; store the average
	mov		EDI, [EBP+8]
	mov		[EDI], EAX

	; restore registers and return
	pop		EAX
	pop		ECX
	pop		EDI
	pop		ESI
	pop		EBP
	ret		16


CalculateStats ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
; 
; Reads a signed int, converts to string, and outputs to the screen.
;
; Preconditions: none
;
; Postconditions: Output string and reverse string variables will be changed.
;
; Receives: 
;			[ebp+16] = signed integer
;			[ebp+12] = output string
;			[ebp+8] = reverse string
;
; returns: none
; ---------------------------------------------------------------------------------

WriteVal PROC
	
	; preserve registers and assign static pointer
	push	EBP
	mov		EBP, ESP
	push	EDX
	push	EAX
	push	EBX
	push	ECX
	push	EDI
	push	ESI

	; determine if the value is positive or negative
	mov		EDX, [EBP+16]
	cmp		EDX, 0
	jl		_negative
	mov		AL, '+'
	jmp		_setup
_negative:
	mov		AL, '-'
	neg		EDX

	; setup registers for the first loop
_setup:
	push	EAX
	mov		ECX, 0
	mov		EDI, [EBP+8]

_nextDigit:
		; divide the number by 10
		mov		EAX, EDX
		mov		EBX, 10
		cdq
		idiv	EBX

		; store the remainder digit
		push	EAX
		mov		EAX, EDX
		add		AL, 48
		stosb
		pop		EAX
	
		; prepare for next iteration
		inc		ECX
		mov		EDX, EAX
		cmp		EAX, 0
	jne		_nextDigit

	; determine if we need to add the negative sign
	pop		EAX
	cmp		AL, '-'
	je		_addsign
	jmp		_skipSign
_addSign:
	stosb
	inc		ECX

_skipSign:
	; setup the registers for the next loop
	mov		ESI, [EBP+8]
	add		ESI, ECX
	dec		ESI
	mov		EDI, [EBP+12]

	; reverse the string
_reverse:
		STD
		LODSB
		CLD
		STOSB
	LOOP	_reverse

	; add the null terminator
	mov		AL, 0
	stosb
	
	; output to screen
	mDisplayString [EBP+12]

	; restore registers and return
	pop		ESI
	pop		EDI
	pop		ECX
	pop		EBX
	pop		EAX
	pop		EDX
	pop		EBP
	ret		16

WriteVal ENDP


END main
