;==============================================================================
;	ウイルス感染CHECK Includeルーチン
;==============================================================================
;
;		注/必ず .COMファイル末尾に来るようにすること。
;
;		例/	:
;			org	100h
;		start:	[[ 初期設定等 ]]
;
;			call	viruschk
;			jnc	main
;
;			[[ ウイルスに侵されていた場合、リネームされて
;			   いた場合の処理 ]]
;
;		main:	[[ メインプログラム ]]
;
;			[[ データ(初期値あり) ]]<- db "message$" 等
;
;			include viruschk.inc
;
;			[[ データ(初期値なし) ]]<- db ? 等
;
;		end	start
;
;		LINK後にDump等で確認して、末尾に"M.Kajihara(KAJA)"という
;		文字列があればOKです。
;
;		入力 /	ラベル "myname" に自分のfile名(8+3文字、空きはspace)
;			をdb定義しておく
;
;		実行 /	call	viruschk (前方参照になるので注意)
;
;		出力 /	cy=0	ax=0	大丈夫だった場合
;			cy=1	ax=1	侵されていると思われる場合
;			cy=1	ax=2	リネームされていると思われる場合
;
;		破壊 /	ds,es,ax,bx,cx,dx,si,di,flags
;
;==============================================================================
;myname		db	"PMD     COM"	<-自分のFile名をこのように定義しておく

viruschk:
	mov	ax,1600h
	int	2fh
	test	al,7fh		;Windows下の場合
	jz	vc_not_windows	;VirusCheckをしない
	xor	ax,ax
	ret

vc_not_windows:
	cld
	mov	ax,cs
	mov	ds,ax

	mov	ah,30h
	int	21h		;ax = dos version

	mov	bx,28h		;dos 2.x   inFCB.size
	mov	cx,4		;dos 2.x   inFCB.filename
	mov	dx,13h		;dos 2.x   inFCB.filesize
	cmp	al,2
	jz	set_FCBsize

	mov	bx,35h		;dos 3.x   inFCB.size
	mov	cx,20h		;dos 3.x～ inFCB.filename
	mov	dx,11h		;dos 3.x～ inFCB.filesize
	cmp	al,3
	jz	set_FCBsize

	mov	bx,3bh		;dos 4.x～ inFCB.size
set_FCBsize:
	mov	[inFCB_size],bx
	mov	[inFCB_filename],cx
	mov	[inFCB_filesize],dx

	mov	ah,52h
	int	21h
	les	bx,es:4[bx]	;es:bx = inFCB block

FCB_search_loop:
	mov	ax,es:0[bx]
	mov	[next_offset],ax
	mov	ax,es:2[bx]
	mov	[next_segment],ax
	mov	cx,es:4[bx]		;cx= number of FCBs

	add	bx,6
	call	inner_FCB_check
	jnc	found_size

	les	bx,dword ptr [next_offset]
	cmp	bx,-1
	jnz	FCB_search_loop

;==============================================================================
;	Filename未発見終了
;==============================================================================
	mov	ax,0002h	;Renameされている場合
	stc
	ret

;==============================================================================
;	Filename発見
;==============================================================================
found_size:
	mov	si,[inFCB_filesize]
	mov	ax,es:[si+bx]		;size low
	mov	dx,es:2[si+bx]		;size high

	add	ax,100h-16
	adc	dx,0
	jnz	virus_found		;サイズが65535をoverしている

	mov	dx,cs
	mov	es,dx
	mov	si,offset chk_message
	mov	di,ax
	mov	cx,16
rep	cmpsb
	jnz	virus_found

	xor	ax,ax		;大丈夫だった
	ret

;==============================================================================
;	ウイルスの疑いがある時
;==============================================================================
virus_found:
	mov	ax,0001h	;侵されている
	stc
	ret

;==============================================================================
;	FCBから自分のファイル名をサーチ
;		in.	es:bx	= inner FCB address
;			cx	= FCBの個数
;==============================================================================
inner_FCB_check:
	push	cx
	mov	di,[inFCB_filename]
	add	di,bx
	mov	si,offset myname
	mov	cx,11
rep	cmpsb
	pop	cx
	jz	ifc_found_ret

	add	bx,[inFCB_size]
	loop	inner_FCB_check
	stc
	ret

ifc_found_ret:
	clc
	ret

chk_message	db	"M.Kajihara(KAJA)"	;16 bytes

inFCB_size	dw	?
inFCB_filename	dw	?
inFCB_filesize	dw	?
next_offset	dw	?
next_segment	dw	?
