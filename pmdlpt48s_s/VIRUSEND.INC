;
;	Viruschk後にその旨表示する
;
	mov	dx,cs
	mov	ds,dx

	mov	dx,offset virus_mes
	dec	ax
	jz	vprint_end
	mov	dx,offset rename_mes
	jmp	vprint_end

rename_mes	db	"!注意! 実行File名がrenameされています。",13,10,"$"
virus_mes	db	"!警告! プログラムがウイルスに侵されている可能性があります。",13,10,"$"

vprint_end:
	mov	ah,9
	int	21h
