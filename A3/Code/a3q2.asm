[org 0x0100]
jmp start

title db 'Assembly Viewport'
lenTitle dw 17

paragraph:
	db 'The PC text screen lives in video memory at segment 0xB800.', 0
	db 'Every character cell uses two bytes: the ASCII code first,', 0
	db 'then the attribute byte that controls its colour.', 0
	db ' ', 0
	db 'The screen has 80 columns and 25 rows, so the whole display', 0
	db 'needs 2000 words of memory, which is exactly 4000 bytes.', 0
	db ' ', 0
	db 'To find a cell, multiply the row by 80, add the column,', 0
	db 'and then double the result to get the byte offset.', 0
	db ' ', 0
	db 'String instructions make memory work fast and compact.', 0
	db 'LODSB reads one byte from memory into the AL register.', 0
	db 'STOSW writes a character and attribute pair to memory.', 0
	db 'MOVSW copies one word from memory to another address.', 0
	db ' ', 0
	db 'Scrolling a window moves each row up by one line.', 0
	db 'The border must stay untouched while the text inside moves.', 0
	db 'The vacated bottom line is filled with blanks afterwards.', 0
	db ' ', 0
	db 'A keyword search walks across video memory and compares', 0
	db 'each character with the pattern. When a match is found,', 0
	db 'only the attribute byte changes, so the text stays intact.', 0
	db ' ', 0
	db 'Good programs keep the stack balanced and save registers.', 0
	db 'Always clean up the memory you use before returning.', 0
	db 'End of document.', 0
	db 0       
	; end of whole document
keyword db 'memory', 0
label1  db 'Total Matches Found: ', 0
label2  db ' | Viewport Status: ACTIVE', 0
matches dw 0	
	
clrscr:
	push es
	push ax
	push cx
	push di
	
	mov ax, 0xb800
	mov es, ax
	xor di, di
	mov ax, 0x0720
	mov cx, 2000
	
	cld 
	rep stosw
	
	pop di
	pop cx
	pop ax
	pop es
	
	ret

draw_outer_viewport:
	
	push bp
	mov bp, sp
	
	; local variables if required.
	
	push es
	push ax
	push cx
	push di
	push si
	push bx
	
	mov ax, 0xb800
	mov es, ax
	
	; will calculate the top left corner first
	mov bl, [bp + 10] ; 
	mov al, 80
	mul bl
	
	; here we have 80 * x
	mov si, ax
	
	add ax, [bp + 6]
	; 80 * x + y done
	shl ax, 1
	
	; now bx has the offset for the top left corner.
	mov di, ax
	push di
	
	
	mov al, 0xc9
	mov ah, 0x1e
	
	mov [es:di], ax
	
	; the top left corner is done.
	
	; will be going left to right, then down, then left, then up
	
	
	add si, [bp + 4]
	; for top right corner.
	shl si, 1
	add di, 2
	
	mov al, 0xcd
	
draw_top_line:
	mov [es:di], ax
	add di, 2
	cmp di, si
	jnz draw_top_line
	
	mov al, 0x0bb
	mov [es:di], ax
	
	; the top line is done by here. 
	
	push ax
	
	mov bl, [bp + 8]
	mov al, 80
	mul bl              ; 80 * bottom
	add ax, [bp + 4]    ; + right
	shl ax, 1
	mov si, ax          ; offset of the bottom-right corner

	pop ax
	mov al, 0xba
	add di, 160         ; start one row below the top-right corner
	
	
	
draw_right_line:
	mov [es:di], ax
	add di, 160
	cmp di, si
	jnz draw_right_line
	
	; at the bottom right corner now. 
	
	mov al, 0x0bc
	mov [es:di], ax
	
	push ax
	mov bl, [bp + 8]
	mov al, 80
	mul bl
	add ax, [bp + 6]
	
	shl ax, 1
	mov si, ax
	
	sub di, 2
	pop ax
	mov al, 0x0cd
	
draw_bottom_line:
	mov [es:di], ax
	sub di, 2
	cmp di, si
	jnz draw_bottom_line
	
	pop si
	
	mov al, 0x0c8
	mov [es:di], ax
	
	mov al, 0x0ba
	sub di, 160
draw_left_line:
	mov [es:di], ax
	sub di, 160
	cmp si, di
	jnz draw_left_line
	
	
	pop bx
	pop si
	pop di
	pop cx
	pop ax
	pop es
	
	; mov sp, bp
	pop bp
	
	ret 8 ; 4 parameters.
	
draw_title_banner:
	
	push bp
	mov bp, sp
	
	; local variables if required.
	
	push es
	push ax
	push cx
	push di
	push si
	push bx
	push dx
	
	mov ax, 0xb800
	mov es, ax
	
	; the centre for the title will be 40 - len/2
	
	mov ax, 40
	mov bx, [bp + 4]
	shr bx, 1
	sub ax, bx
	
	mov bx, ax
	
	mov al, [bp + 8]
	mov dl, 80
	mul dl
	
	add ax, bx
	shl ax, 1
	
	mov di, ax
	
	mov si, [bp + 6]
	mov cx, [bp + 4]
	mov ah, 0x1e
	cld
next_char:
	lodsb
	stosw
	loop next_char
	
	pop dx
	pop bx
	pop si
	pop di
	pop cx
	pop ax
	pop es
	
	; mov sp, bp
	pop bp
	ret 6
	
text_stream:
	push bp
	mov bp, sp
	
	sub sp, 4 ; a local varibale
	
	push es
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	
	mov ax, 0xB800
	mov es, ax
	
	cld
	mov si, [bp + 14]
	mov ax, [bp + 12]
	
	mov [bp - 2], ax
	
next_line:
	mov ax, [bp - 2]
	cmp ax, [bp + 6]
	ja done
	mov bx, 80
	mul bx
	add ax, [bp + 10]
	shl ax, 1
	mov di, ax
	mov ah, [bp + 4]
	
	mov dx, [bp + 8]
	sub dx, [bp + 10]
	inc dx
	mov [bp - 4], dx
	
char_loop:
	LODSB
	cmp al, 0
	je end_of_line
	cmp word [bp - 4], 0
	je skip_rest
	STOSW
	dec word [bp - 4]
	jmp char_loop
	
skip_rest:
	LODSB
	cmp al, 0
	jne skip_rest
	
end_of_line:
	inc word [bp - 2]
	cmp byte [si], 0
	jne next_line

done:	
	
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	
	mov sp, bp
	pop bp
	ret 12
	
scroll_window_up:
	push bp
	mov bp, sp
	sub sp, 4
	; [bp - 2] = width ,
	; [bp - 4] = window height in rows
	
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push ds
	push es
	
	mov ax, 0xB800
	mov ds, ax
	mov es, ax
	cld
	
	; di = destination, the top row
	mov bl, [bp + 12]
	mov al, 80
	mul bl
	add ax, [bp + 10]
	shl ax, 1
	mov di, ax
	
	; si = source, N rows below the top row
	mov bl, [bp + 12]
	add bl, [bp + 4]
	mov al, 80
	mul bl
	add ax, [bp + 10]
	shl ax, 1
	mov si, ax
	
	mov ax, [bp + 8]
	sub ax, [bp + 10]
	add ax, 1
	mov [bp - 2], ax        ; width
	
	mov ax, [bp + 6]
	sub ax, [bp + 12]
	add ax, 1
	mov [bp - 4], ax        ; height
	
	mov dx, [bp + 4]        ; dx is the total number of rows to scroll.
	cmp dx, ax
	jbe n_ok
	mov dx, ax              ; 
n_ok:
	mov bx, ax
	sub bx, dx              ; bx = number of rows to copy 
	cmp bx, 0
	je blank_part
	
copy_loop:
	push si
	push di
	mov cx, [bp - 2]
	rep movsw               ; one row only
	pop di
	pop si
	add si, 160             ; moving both si and di to the next rows.
	add di, 160
	dec bx
	jnz copy_loop
	
	; di now points at the first vacated row
blank_part:
	mov bx, dx              ; bx  is the number of rows that we want to blanl
	cmp bx, 0
	je done1
	mov ax, 0x0720          ; blank with the space
	
blank_loop:
	push di
	mov cx, [bp - 2]
	rep stosw
	pop di
	add di, 160
	dec bx
	jnz blank_loop
	
done1:
	pop es
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	
	ret 10

find_and_highlight:
	; [bp + 14] = keyword offset, [bp + 12] = highlight attribute
	; [bp + 10] = top, [bp + 8] = left, [bp + 6] = bottom, [bp + 4] = right
	; returns the match count in ax
	push bp
	mov bp, sp
	sub sp, 6 ; [bp - 2] = keyword length, [bp - 4] = match count, [bp - 6] = window width
	
	push bx
	push cx
	push dx
	push si
	push di
	push es
	
	mov word [bp - 4], 0
	
	; width = right - left + 1
	mov ax, [bp + 4]
	sub ax, [bp + 8]
	inc ax
	mov [bp - 6], ax
	
	; keyword length (ds already points to our data in a .com file)
	mov si, [bp + 14]
	xor cx, cx
len_loop:
	cmp byte [si], 0
	je len_done
	inc si
	inc cx
	jmp len_loop
len_done:
	mov [bp - 2], cx
	cmp cx, 0
	je finish
	cmp cx, [bp - 6] ; keyword longer than the window width can never match
	ja finish
	
	mov ax, 0xB800
	mov es, ax
	cld
	mov bx, [bp + 10] ; bx = current row, starting at top
	
row_loop:
	cmp bx, [bp + 6] ; comparing w the last row
	ja finish
	mov ax, bx
	mov dx, 80
	mul dx
	add ax, [bp + 8] ; + left
	shl ax, 1
	mov di, ax ; di = first cell of this row
	
	mov dx, [bp - 6]
	sub dx, [bp - 2]
	inc dx ; dx = how many start positions fit before the right boundary
	
pos_loop:
	push di ; keeping it to later come back here
	mov si, [bp + 14]
cmp_loop:
	lodsb ; next keyword character
	test al, al ; chcks if al is 0
	jz matched ; reached the null, so every character matched
	scasb ; compare with the screen character, di + 1
	jne no_match
	inc di ; skip the attribute byte
	jmp cmp_loop
	
no_match:
	pop di
	add di, 2 ; next cell
	dec dx
	jnz pos_loop
	jmp next_row
	
matched:
	pop di ; back to the first matching cell
	inc word [bp - 4]
	mov cx, [bp - 2]
	mov al, [bp + 12]
	inc di ; +1 to move to attribute byte of the first cell
hl_loop:
	stosb ; write attribute only
	inc di ; skip the character byte
	loop hl_loop
	dec di ; back to the first cell after the match
	sub dx, [bp - 2] ; those positions are used up
	ja pos_loop ; positions left in this row
	
next_row:
	inc bx
	jmp row_loop
	
finish:
	mov ax, [bp - 4] ; return value
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	mov sp, bp
	pop bp
	ret 12 ; 6 parameters

printNum:
	; [bp + 10] = number, [bp + 8] = row, [bp + 6] = column, [bp + 4] = attribute
	; returns the column after the last digit in ax
	push bp
	mov bp, sp
	sub sp, 4 ; [bp-2] = video cursor, [bp-4] = number of digits
	
	push bx
	push cx
	push dx
	push di
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	mov ax, [bp + 8]
	mov bx, 80
	mul bx
	add ax, [bp + 6]
	shl ax, 1
	mov [bp - 2], ax
	
	mov ax, [bp + 10]
	mov bx, 10
	xor cx, cx
divide_loop:
	xor dx, dx
	div bx ; ax = quotient, dx = remainder (last digit)
	push dx ; digits come out in reverse, so the stack reverses them back
	inc cx
	cmp ax, 0
	jne divide_loop
	
	mov [bp - 4], cx
	mov di, [bp - 2]
print_loop:
	pop dx
	add dl, '0'
	mov dh, [bp + 4]
	mov [es:di], dx
	add di, 2
	loop print_loop
	
	mov ax, [bp + 6]
	add ax, [bp - 4] ; next free column
	
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	mov sp, bp
	pop bp
	ret 8 ; 4 parameters


print_string:
	; [bp + 10] = string offset (null terminated), [bp + 8] = row
	; [bp + 6] = column, [bp + 4] = attribute
	push bp
	mov bp, sp
	sub sp, 2 ; [bp-2] = video offset
	
	push ax
	push bx
	push si
	push di
	push es
	
	mov ax, 0xB800
	mov es, ax
	mov ax, [bp + 8]
	mov bx, 80
	mul bx
	add ax, [bp + 6]
	shl ax, 1
	mov [bp - 2], ax
	
	mov di, [bp - 2]
	mov si, [bp + 10]
	mov ah, [bp + 4]
	cld
str_loop:
	lodsb
	cmp al, 0
	je str_done
	stosw
	jmp str_loop
	
str_done:
	pop es
	pop di
	pop si
	pop bx
	pop ax
	mov sp, bp
	pop bp
	ret 8 ; 4 parameters
	
start:

	call clrscr
	
	mov ax, 3
	push ax ; bp + 10
	mov ax, 21
	push ax ; bp + 8
	mov ax, 8
	push ax ; bp + 6
	mov ax, 72
	push ax  ; bp + 4
	call draw_outer_viewport
	
	;
	
	mov ax, 3 ; the top row
	push ax
	mov ax, title
	push ax ; bp + 6
	mov ax, [lenTitle]
	push ax ; bp + 4
	call draw_title_banner		
	
	;
	
	mov ax, paragraph
	push ax
	mov ax, 4
	push ax
	mov ax, 10
	push ax
	mov ax, 70
	push ax
	mov ax, 20
	push ax
	mov ax, 0x07
	push ax
	call text_stream
	
	mov ax, 4 ; starting row
	push ax ;+ 12
	mov ax, 10 ; starting column.
	push ax ; + 10
	mov ax, 70 ;ending column
	push ax ; + 8
	mov ax, 20 ; ending row
	push ax ; bp + 6
	mov ax, 0 ; the number of lines to scroll_up
	push ax ; bp + 4
	call scroll_window_up
	
	mov ax, keyword
	push ax ; bp + 14
	mov ax, 0xCE
	push ax ; bp + 12, highlight attribute
	mov ax, 4
	push ax ; bp + 10, top row
	mov ax, 10
	push ax ; bp + 8, left column
	mov ax, 20
	push ax ; bp + 6, bottom row
	mov ax, 70
	push ax ; bp + 4, right column
	call find_and_highlight
	
	mov [matches], ax
	mov ax, label1
	push ax ; bp + 10
	mov ax, 23
	push ax ; bp + 8, row
	mov ax, 10
	push ax ; bp + 6, column
	mov ax, 0x07
	push ax ; bp + 4, attribute
	call print_string
	
	; the count, starting right after the label at column 31
	mov ax, [matches]
	
	push ax
	mov ax, 23
	push ax
	mov ax, 31
	push ax
	mov ax, 0x07
	push ax
	call printNum ; returns the next column in ax
	
	mov bx, ax
	mov ax, label2
	push ax
	mov ax, 23
	push ax
	push bx
	mov ax, 0x07
	push ax
	call print_string
	;
	;
	mov ax, 0x4c00
	int 0x21
