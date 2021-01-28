;
;	Virus Check—proutine (“ª—p)
;
	mov	ax,cs
	mov	ds,ax

	mov	si,offset 80h
	lodsb
	test	al,al
	jz	vchk
vchk_com_loop:
	lodsb
	cmp	al," "
	jz	vchk_com_loop
	cmp	al,"#"
	jnz	vchk
	mov	byte ptr -1[si]," "
	jmp	vchk_exit

vchk:	call	viruschk
	jnc	vchk_exit
	include	virusend.inc
vchk_exit:
