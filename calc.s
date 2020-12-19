section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string
    calc: db "calc: ", 0
    not_enough: db "Error: Insufficient Number of Arguments on Stack", 10, 0
    full: db "Error: Operand Stack Overflow", 10, 0
    countMSG: db "number of operations is: ", 10 ,0
    print_digit: db "%d", 10, 0	; format num
    print_hex: db "%X", 0	; format hexdicimal
    hexEndPrint: db "%X", 10 ,0
    newLine: db "",10,0
    debugRead: db "Reading digit: " , 0
    debugPush: db "pushing to the stack: " ,0 
    debugPop: db "poping from the stack: " ,0

section .bss			; we define (global) uninitialized variables in .bss section
   
    count: resb 4       ; define counter for operetion number
    input: resb 81
    stackPointer: resb 4
    stackSize: resb 4
    link: resb 4
    maxStack: resb 4
    tmpPointer: resb 4
    debug: resb 1
    leadingZero: resb 1
    zero: resb 1
    forDup: resb 1
    NumDup: resb 4
section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern fflush
  extern malloc 
  extern calloc 
  extern free  
  extern fgets 
  extern stdin
  extern stderr

    %macro startFunc 0
        push ebp
        mov ebp, esp
        pushad
    %endmacro

    %macro endFunc 0
        popad		
	    mov esp, ebp	
	    pop ebp
        ret
    %endmacro

	%macro cFunc 2
        push %1
        call %2
        add esp, 4
    %endmacro
    
    %macro cFunc2 3
        push %1
        push %2
        call %3
        add esp,8
    %endmacro
    
    %macro free2numbers 0
        push dword[ebp+8]
        call freeNumber
        add esp,4
        push dword[ebp+12]
        call freeNumber
        add esp,4
    %endmacro
    
main: 
    call calculate
    push dword[count]
    ;push print_digit
    push hexEndPrint
    call printf
    add esp,8
    mov ebx ,eax
    mov eax, 1
    int 0x80
    nop

calculate:
    startFunc
    ; check if we need to active debug mode and get the size of the stack
    mov dword[maxStack], 5
    mov dword[debug], 0
    mov dword[forDup],0
    mov ebx, [ebp+12] ;ebp+8 - argc
    mov ecx, [ebp+16] ;ebp+12 - pointer to argv
    cmp ebx,3
    jz .DebugAndsize
    cmp ebx,2
    jz .checkWitch
    jmp .start
    .DebugAndsize:
        mov dword[debug],1
        mov edx, dword[ecx+4]
        mov eax,0
        mov al, byte[edx]
        push eax
        call convertToHex
        add esp, 4
        mov [maxStack],eax
        jmp .start
    .checkWitch:
        mov edx, [ecx+4]
        mov eax,0
        mov al, byte[edx]
        cmp eax, '-'
        jnz .notDebug
        mov dword[debug],1
        jmp .start
    .notDebug:
        mov edx, [ecx+4]
        mov eax,0
        mov al, byte[edx]
        push eax
        call convertToHex
        add esp, 4
        mov [maxStack],eax
    .start:
    mov dword[count], 0
    mov dword[stackSize], 0
    mov ebx,0
    mov edx,0
    mov ecx,0

    ; allocate memory for stack
    call cFunc2 4, dword[maxStack], calloc
    mov [stackPointer], eax ;pointer to the "stack" we made
    add esp,4
input_loop:
    cFunc calc, printf

    push dword[stdin]
    push dword 80
    push dword input
    call fgets
    add esp,12
    inc dword[count]; maybe need to be byte
    ; maybe need to push here 0 for null terminator
    ; now we check the input
    cmp byte[input], 'q'
    jz .quit
    cmp byte[input], '+'
    jnz .not_add
    call addition
    jmp input_loop
.not_add:
    cmp byte[input], 'p'
    jnz .not_p
    call popAndPrint
    jmp input_loop
.not_p:
    cmp byte[input], 'd'
    jnz .not_d
    call duplicate
    jmp input_loop
.not_d:
    cmp byte[input], '&'
    jnz .not_and
    call bitwise_AND
    jmp input_loop
.not_and:
    cmp byte[input], '|'
    jnz .not_or
    call bitwise_OR
    jmp input_loop
.not_or:
    cmp byte[input], 'n'
    jnz .ItsNumber
    call numOfHexDigit
    jmp input_loop
.ItsNumber:
    dec dword[count]; maybe need to be byte
    call new_num
    jmp input_loop
.quit:
    dec dword[count]    ;not need to count the "q" as operation
    .freeStack:
        cmp dword[stackSize], 0
        jg .gotEnough
        push dword[stackPointer]
        call free
        add esp,4
        endFunc
    .gotEnough:
        call popStack
        push eax
        call freeNumber
        add esp,4
        jmp .freeStack
    

addition:
    startFunc
    cmp dword[stackSize], 2
    jge .gotEnough
    cFunc not_enough, printf
    endFunc
.gotEnough:
    call popStack
    mov ebx,eax
    call popStack
    push eax
    push ebx
    call addNumbers
    add esp, 8
    push eax
    call pushStack
    add esp, 4
    endFunc

popStack:
    startFunc
    mov ebx, dword[stackPointer]
    mov ecx, dword[stackSize]
    mov eax, dword[ebx + 4*ecx -4]
    dec dword[stackSize] 
    mov dword[link], eax
    cmp byte[debug], 0 
    jz .end
    push debugPop
    push eax
    call debugPrinting
    add esp,8
    push newLine
    call printf
    add esp,4
 .end:
    popad
    mov eax, dword[link]
    mov esp,ebp
    pop ebp
    ret

pushStack:
    startFunc
    mov ebx, dword[stackPointer]
    mov ecx, dword[stackSize]
    mov edx, dword[ebp+8]   ;ebp+8 is the link we want to add
    mov dword[ebx + 4*ecx], edx
    inc dword[stackSize]
    cmp byte[debug], 0 
    jz .end
    push debugPush
    push edx
    call debugPrinting
    add esp,8
    push newLine
    call printf
    add esp,4
 .end: 
    endFunc

addNumbers:
    startFunc
    sub esp, 20
    ;20 because:
    ;ebp-4: new link pointer
    ;ebp-8: the first num
    ;ebp-12: the second num
    ;ebp-16: new number we get in the end
    ;ebp-20: carry
    ;
    ;note that first number is in [ebp+8]
    ;          second number is in [ebp+12]
    mov dword[ebp-4], 0    ;reset pointer
    mov dword[ebp-20], 0    ;reset carry
    mov dword[ebp-16], 0    ;reset new number
    mov ebx, dword[ebp+8]
    mov dword[ebp-8], ebx   ;set first num
    mov ebx, dword[ebp+12]
    mov dword[ebp-12], ebx  ;set second num
.sum:
    mov ebx,0
    ;starting with the first num
    cmp dword[ebp-8], 0
    jz .secondNum
    mov edx, dword[ebp-8]
    add ebx, dword[edx] ;add most insegnificent bit from num1
.secondNum:
    cmp dword[ebp-12], 0
    jz .carryNum
    mov edx, dword[ebp-12]
    add ebx, dword[edx] ;add most insegnificent bit from num2
.carryNum:
    movzx edx, byte[ebp-20]
    add ebx, edx ;add  the carry
    mov dword [ebp-20], ebx
    shr dword [ebp-20], 4
    cmp byte [ebp-20], 0
    jle .continueAdd
    ;means we have carry
    and ebx, 15 ;15 means 1111 in binary, so we get only the 4 last digit
.continueAdd:
    push 0
    push ebx
    call linkCreat
    add esp,8
    cmp dword [ebp-4], 0
    jz .first   ;means we just start to make the new link
    mov ecx, dword [ebp-4]
    mov dword[ecx+1], eax   ;eax contain the new link we created
    jmp .notFirst
.first:
    ;mov ecx, dword [ebp-16]
   ; mov dword[ecx+1], eax   ;eax contain the new link we created
    mov dword[ebp-16], eax
.notFirst:
    mov dword[ebp-4],eax
.getNextFirstNum:
    cmp dword [ebp-8], 0    ;check if first number is empty
    jz .getNextSecondNum
    mov ecx, dword[ebp-8]
    mov ebx, [ecx+1]    ;that the new number
    mov dword[ebp-8], ebx   ;insert the new num to [ebp-8]
.getNextSecondNum:
    cmp dword[ebp-12],0
    jz .checkIfEnd
    mov ecx, dword[ebp-12]
    mov ebx, [ecx+1]    ;that the new number
    mov dword[ebp-12], ebx   ;insert the new num to [ebp-12]
.checkIfEnd:
    cmp dword[ebp-8], 0    ;check if first number is empty
    jnz .sum
    cmp dword[ebp-12], 0   ;check if second number is empty
    jnz .sum
    cmp dword[ebp-20], 0   ;check if carry is empty
    jnz .sum
;means we done the adding
    
    free2numbers
    mov ecx, dword[ebp-16]
    add esp,20
    ;popad- will destroy eax so we need to bypass it
    mov dword[link], ecx
    popad
    mov eax, dword[link]
    mov esp,ebp
    pop ebp
    ret


linkCreat:
    startFunc
    cFunc2 4,5,calloc
    ;note:
    ;eax: pointer to the memory we alocate
    ;ebp+8: number to creat
    ;ebp+12: next address
    mov edx, dword[ebp+12]
    mov dword[eax+1],edx
    mov cl, byte[ebp+8]
    mov byte[eax], cl
    ;popad- will destroy eax so we need to bypass it
    mov dword[link], eax
    popad
    mov eax, dword[link]
    mov esp,ebp
    pop ebp
    ret

popAndPrint:
    startFunc
    cmp dword[stackSize], 1
    jge .gotEnough
    cFunc not_enough, printf
    endFunc
.gotEnough:
    call popStack
    ;eax-pointer to first digit of number
    push eax
    call print
    call freeNumber
    add esp,4
    push newLine
    call printf
    add esp,4
    endFunc

print:  ;recursivly print the number
    ;ebp+8 - pointer to the digit
    startFunc
    mov ecx, dword[ebp+8]
    cmp ecx,0
    jz .end
    push dword[ecx+1]
    call print
    add esp,4
    movzx eax, byte[ecx]
    push eax
    push print_hex
    call printf
    add esp ,8
.end:
    endFunc

duplicate:
    startFunc
    cmp dword[stackSize], 1
    jge .gotEnough
    cFunc not_enough, printf
    endFunc
.gotEnough:
    mov ebx, dword[maxStack]
    cmp dword[stackSize], ebx
    jl .all_OK
    cFunc full, printf
    endFunc
.all_OK:
    mov ebx, dword[stackPointer]
    mov ecx, dword[stackSize]
    mov eax, dword[ebx + 4*ecx -4] 
    push eax
    push 0
    call .dup
    add esp,8
    push eax
    call pushStack
    add esp, 4
    endFunc
.dup:
    startFunc
    sub esp, 20
    ;20 because:
    ;ebp-4: new link pointer
    ;ebp-8: the first num
    ;ebp-12: the second num
    ;ebp-16: new number we get in the end
    ;ebp-20: carry
    ;
    ;note that first number is in [ebp+8]
    ;          second number is in [ebp+12]
    mov dword[ebp-4], 0    ;reset pointer
    mov dword[ebp-20], 0    ;reset carry
    mov dword[ebp-16], 0    ;reset new number
    mov ebx, dword[ebp+8]
    mov dword[ebp-8], ebx   ;set first num
    mov ebx, dword[ebp+12]
    mov dword[ebp-12], ebx  ;set second num
.sum:
    mov ebx,0
    ;starting with the first num
    cmp dword[ebp-8], 0
    jz .secondNum
    mov edx, dword[ebp-8]
    add ebx, dword[edx] ;add most insegnificent bit from num1
.secondNum:
    cmp dword[ebp-12], 0
    jz .carryNum
    mov edx, dword[ebp-12]
    add ebx, dword[edx] ;add most insegnificent bit from num2
.carryNum:
    movzx edx, byte[ebp-20]
    add ebx, edx ;add  the carry
    mov dword [ebp-20], ebx
    shr dword [ebp-20], 4
    cmp byte [ebp-20], 0
    jle .continueAdd
    ;means we have carry
    and ebx, 15 ;15 means 1111 in binary, so we get only the 4 last digit
.continueAdd:
    push 0
    push ebx
    call linkCreat
    add esp,8
    cmp dword [ebp-4], 0
    jz .first   ;means we just start to make the new link
    mov ecx, dword [ebp-4]
    mov dword[ecx+1], eax   ;eax contain the new link we created
    jmp .notFirst
.first:
    ;mov ecx, dword [ebp-16]
   ; mov dword[ecx+1], eax   ;eax contain the new link we created
    mov dword[ebp-16], eax
.notFirst:
    mov dword[ebp-4],eax
.getNextFirstNum:
    cmp dword [ebp-8], 0    ;check if first number is empty
    jz .getNextSecondNum
    mov ecx, dword[ebp-8]
    mov ebx, [ecx+1]    ;that the new number
    mov dword[ebp-8], ebx   ;insert the new num to [ebp-8]
.getNextSecondNum:
    cmp dword[ebp-12],0
    jz .checkIfEnd
    mov ecx, dword[ebp-12]
    mov ebx, [ecx+1]    ;that the new number
    mov dword[ebp-12], ebx   ;insert the new num to [ebp-12]
.checkIfEnd:
    cmp dword[ebp-8], 0    ;check if first number is empty
    jnz .sum
    cmp dword[ebp-12], 0   ;check if second number is empty
    jnz .sum
    cmp dword[ebp-20], 0   ;check if carry is empty
    jnz .sum
;means we done the adding
    
    mov ecx, dword[ebp-16]
    add esp,20
    ;popad- will destroy eax so we need to bypass it
    mov dword[link], ecx
    popad
    mov eax, dword[link]
    mov esp,ebp
    pop ebp
    ret



bitwise_AND:
    startFunc
    cmp dword[stackSize], 2
    jge .gotEnough
    cFunc not_enough, printf
    endFunc
.gotEnough:
    call popStack
    mov ebx, eax    
    call popStack
    push eax        ;eax- second number
    push ebx        ;ebx-first number
    call andNum
    add esp, 8
    push eax        ; the new number we got after &
    call pushStack
    add esp, 4
    endFunc

andNum:
    startFunc
    ;note-
    ;ebp+8 - first num we pushed
    ;ebp+12- second num we pushed
    ;ebp-4: new link pointer
    ;ebp-8: the first num
    ;ebp-12: the second num
    ;ebp-16: new number we get in the end
    sub esp, 16
    ;initialize parameters
    mov dword[ebp-4], 0
    mov ecx, dword[ebp+8]
    mov dword[ebp-8], ecx
    mov ecx, dword[ebp+12]
    mov dword[ebp-12], ecx 
    mov dword[ebp-16], 0
    mov dword[zero],0   ;still didnt got zero
    mov dword[leadingZero],0   ;1 till we got another number
    mov esi,0
.loop:
    mov eax,0
    ;starting with the first num
    cmp dword[ebp-8], 0
    jz .isNumZero
    mov edx, dword[ebp-8]
    movzx ebx, byte[edx] 
.secondNum:
    cmp dword[ebp-12], 0
    jz .isNumZero
    mov edx, dword[ebp-12]
    movzx eax,byte[edx]
.doAND:
    and ebx,eax
    cmp ebx, 0
    jz .leadZero
    mov dword[zero], 0
.notZero:
    mov dword[leadingZero],1
    cmp esi, 0
    jg .zeroAdd
.original:
    push 0
    push ebx
    call linkCreat
    add esp,8
    cmp dword[ebp-16],0
    jz .firstLink
    ;eax - the new link we just created
    mov edx, dword[ebp-4]
    mov dword[edx+1], eax
    jmp .notFirstLink
.firstLink:
    mov dword[ebp-16],eax
.notFirstLink:
    mov dword[ebp-4],eax    ;we set the pointer

.getNextFirstNum:
    cmp dword [ebp-8], 0    ;check if first number is empty
    jz .isNumZero
    mov ecx, dword[ebp-8]
    mov ebx, [ecx+1]    ;that the new number
    mov dword[ebp-8], ebx   ;insert the new num to [ebp-8]
.getNextSecondNum:
    cmp dword[ebp-12],0
    jz .isNumZero
    mov ecx, dword[ebp-12]
    mov ebx, [ecx+1]    ;that the new number
    mov dword[ebp-12], ebx   ;insert the new num to [ebp-12]
    jmp .loop           ;not need to check if ends because we do it in the begining of loop
.leadZero:
    inc esi
    mov dword[zero], 1  ;if we got the num 0 we will creat it and not ignore
    ;cmp byte[leadingZero], 0
    ;jz .notZero
    jmp .getNextFirstNum
.zeroAdd:
    push 0
    push 0
    call linkCreat
    add esp,8
    cmp dword[ebp-16],0
    jz .FirstLink
    ;eax - the new link we just created
    mov edx, dword[ebp-4]
    mov dword[edx+1], eax
    jmp .NotFirstLink
.FirstLink:
    mov dword[ebp-16],eax
.NotFirstLink:
    mov dword[ebp-4],eax    ;we set the pointer

    dec esi
    cmp esi,0
    jg .zeroAdd
    jmp .original

.isNumZero:
    cmp byte[zero], 1
    jnz .end
    cmp byte[leadingZero], 0
    jnz .end 
   ; got only zeros. create a zero
    push 0
    push 0
    call linkCreat 
    add esp, 8
    mov dword[ebp-16],eax
.end:
    free2numbers
    mov ecx, dword[ebp-16]
    add esp,16
    ;popad- will destroy eax so we need to bypass it
    mov dword[link], ecx
    popad
    mov eax, dword[link]
    mov esp,ebp
    pop ebp
    ret

bitwise_OR:
    startFunc
    cmp dword[stackSize], 2
    jge .gotEnough
    cFunc not_enough, printf
    endFunc
.gotEnough:
    call popStack
    mov ebx, eax    
    call popStack
    push eax        ;eax- second number
    push ebx        ;ebx-first number
    call orNum
    add esp, 8
    push eax        ; the new number we got after &
    call pushStack
    add esp, 4
    endFunc

orNum:
    startFunc
    ;note-
    ;ebp+8 - first num
    ;ebp+12- second num
    ;ebp-4: new link pointer
    ;ebp-8: the first num
    ;ebp-12: the second num
    ;ebp-16: new number we get in the end
    sub esp, 16
    ;initialize parameters
    mov dword[ebp-4], 0
    mov ecx, dword[ebp+8]
    mov dword[ebp-8], ecx
    mov ecx, dword[ebp+12]
    mov dword[ebp-12], ecx 
    mov dword[ebp-16], 0
.loop:
    mov ebx,0
    mov eax, 0
    ;starting with the first num
    cmp dword[ebp-8], 0
    jz .addJustSecond
    mov edx, dword[ebp-8]
    mov ebx, dword[edx] 
.secondNum:
    cmp dword[ebp-12], 0
    jz .addJustFirst
    mov edx, dword[ebp-12]
    mov eax,dword[edx]
.doOR:
    or ebx, eax
    push 0
    push ebx
    call linkCreat
    add esp,8
    cmp dword[ebp-16],0
    jz .firstLink
    ;eax - the new link we just created
    mov edx, dword[ebp-4]
    mov dword[edx+1], eax
    jmp .notFirstLink
.firstLink:
    mov dword[ebp-16],eax
.notFirstLink:
    mov dword[ebp-4],eax    ;we set the pointer

.getNextFirstNum:
    cmp dword[ebp-8], 0    ;check if first number is empty
    ;jz .addJustSecond
    jz .getNextSecondNum
    mov ecx, dword[ebp-8]
    mov ebx, [ecx+1]    ;that the new digit
    mov dword[ebp-8], ebx   ;insert the new digit to [ebp-8]
.getNextSecondNum:
    cmp dword[ebp-12],0
    jz .addJustFirst
    mov ecx, dword[ebp-12]
    mov ebx, [ecx+1]    ;that the new digit
    mov dword[ebp-12], ebx   ;insert the new digit to [ebp-12]
    cmp dword[ebp-8], 0    ;check if first number is empty
    jz .addJustSecond
    jmp .loop           ;not need to check if ends because we do it in the begining of loop
.addJustFirst:
    cmp dword [ebp-8], 0
    jz .end
    mov edx, dword[ebp-8]
    mov ebx, dword[edx]
    push 0
    push ebx
    call linkCreat
    add esp,8
    cmp dword[ebp-16],0
    jz .firstLink
    ;eax - the new link we just created
    mov edx, dword[ebp-4]
    mov dword[edx+1], eax
    jmp .notFirstLink
.addJustSecond:
    cmp dword [ebp-12], 0
    jz .end
    mov edx, dword[ebp-12]
    mov ebx, dword[edx]
    push 0
    push ebx
    call linkCreat
    add esp,8
    ;mov ebx, [ecx+1]    ;that the new digit
    ;mov dword[ebp-12], ebx   ;insert the new digit to [ebp-12]
    cmp dword[ebp-16],0
    jz .firstLink
    ;eax - the new link we just created
    mov edx, dword[ebp-4]
    mov dword[edx+1], eax
   
    jmp .notFirstLink
.end:
    free2numbers
    mov ecx, dword[ebp-16]
    add esp,16
    ;popad- will destroy eax so we need to bypass it
    mov dword[link], ecx
    popad
    mov eax, dword[link]
    mov esp,ebp
    pop ebp
    ret

numOfHexDigit:
    startFunc
    cmp dword[stackSize], 1
    jge .gotEnough
    cFunc not_enough, printf
    endFunc
.gotEnough:
    call popStack
    ;eax-pointer to first digit of number
    push eax
    call counting
    add esp, 4
    push eax
    call pushStack
    add esp, 4
    endFunc 

counting:
    ;ebp+8 - pointer to the digit
    startFunc
    sub esp, 4
    ;ebp-4 the number
    mov ebx, 0  ; ebx -counter
    mov edx, dword[ebp+8]
    mov dword[ebp-4], edx
.loop:
    ;movzx ecx, ed
    cmp dword[ebp-4],0
    jz .end
    inc ebx
    mov ecx, [ebp-4]
    mov edx, [ecx+1]
    mov dword[ebp-4], edx
    jmp .loop
.end:
    push dword[ebp+8]
    call freeNumber
    add esp,4
    push 0
    push ebx
    call linkCreat
   ; push ebx
    ;push hexEndPrint
    ;call printf
    add esp,12
    mov dword[link], eax
    popad
    mov eax, dword[link]
    mov esp,ebp
    pop ebp
    ret

new_num:
    startFunc
    mov ebx, dword[maxStack]
    cmp dword[stackSize], ebx
    jl .all_OK
    cFunc full, printf
    jmp .end
.all_OK:
    mov edx, 0  ;point to the head of linked list
    mov ecx, input
    ;mov eax, 0
    mov dword[zero],0   ;still didnt got zero
    mov dword[leadingZero],1   ;1 til we got another number
.oneDigit:
    movzx eax, byte[ecx]
.check:
    cmp eax,0x0A  ;check if its \n
    jz .isNumZero
    push eax
    call convertToHex
    add esp,4
    cmp eax ,0
    jz .leadZero
    ;eax is a hex num now
    ;edx is the pointer to te list
.notZero:
    mov dword[leadingZero],0
    push edx
    push eax
    call linkCreat
    add esp, 8
    mov edx, eax    ;now edx point to the link we created
    jmp .skip
.leadZero:
    mov dword[zero], 1  ;if we got the num 0 we will creat it and not ignore
    cmp byte[leadingZero], 0
    jz .notZero
.skip:
    inc ecx
    jmp .oneDigit
.isNumZero:
    cmp byte[zero], 1
    jnz .pushNum
    cmp byte[leadingZero], 1
    jnz .pushNum 
   ; got only zeros. create a zero
    push edx
    push 0
    call linkCreat 
    add esp, 8
    mov edx, eax
.pushNum:
    cmp edx, 0  ;check if we got an empty string
    jz .end
    ;if not empty we need to check if we have enough room in stack
    
    push edx
    call pushStack
    add esp,4
.end:
    endFunc

convertToHex:
    push ebp
    mov ebp, esp
    ;note-
    ;ebp+8- char to convert
    mov ebx, [ebp+8]
    cmp eax,'9'	
	jng .continue_hex
	sub eax,7
.continue_hex:
	sub eax,'0'
    mov esp, ebp
    pop ebp
    ret

freeNumber:
    startFunc
    ;ebp+8 - number we want to free
    mov ebx, dword[ebp+8]
    cmp ebx,0
    jz .finish
    
    push dword[ebx+1]
    call freeNumber ;recursively free the number
    add esp,4
    push ebx
    call free
    add esp,4
.finish:
    endFunc

debugPrinting:
    startFunc
    mov eax,dword [ebp+12]; format
    mov ebx,dword [ebp+8]; num
    push eax
    call printf ;printing the msg
    add esp,4
    push ebx
    call print  ;print the full number
    add esp,4
    endFunc

