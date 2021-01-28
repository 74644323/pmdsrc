;
;	ＰＳＧ　ドラムス＆効果音　ルーチン
;	Ｆｒｏｍ　ＷＴ２９８
;
;	AL に 効果音Ｎｏ．を入れて　ＣＡＬＬする
;	ppsdrvがあるならそっちを鳴らす
;

effgo:	cmp	[ppsdrv_flag],0
	jz	effgo2
	or	al,80h
	cmp	[last_shot_data],al
	mov	[last_shot_data],al
	jnz	effgo2
	push	ax
	xor	ah,ah
	int	ppsdrv		;直前が同じ音色ならダンプ
	pop	ax
effgo2:
	mov	[hosei_flag],3	;音程/音量補正あり (K part)
	jmp	eff_main
eff_on2:
	mov	[hosei_flag],1	;音程のみ補正あり (n command)
	jmp	eff_main
eff_on:
	mov	[hosei_flag],0	;補正無し (INT60)
eff_main:
	mov	bx,cs
	mov	ds,bx

	cmp	[effflag],0
	jz	eg_00
	ret		;効果音を使用しないモード
eg_00:
	cmp	[ppsdrv_flag],0
	jz	eg_nonppsdrv
	or	al,al
	jns	eg_nonppsdrv

;	ppsdrv
	cmp	[effon],2
	jnc	effret		;通常効果音発音時は発声させない

	mov	bx,offset part9	;PSG 3ch
	or	partmask[bx],2	;Part Mask
	mov	[effon],1	;優先度１(ppsdrv)
	mov	[psgefcnum],al	;音色番号設定 (80H～)

	mov	bx,15
	mov	ah,[hosei_flag]
	ror	ah,1
	jnc	not_tone_hosei
	mov	bx,detune[di]
	mov	bh,bl		;BH = Detuneの下位 8bit
	mov	bl,15
not_tone_hosei:
	ror	ah,1
	jnc	not_volume_hosei
	mov	ah,volume[di]
	cmp	ah,15
	jnc	fade_hosei
	mov	bl,ah		;BL = volume値 (0～15)
fade_hosei:
	mov	ah,[fadeout_volume]
	test	ah,ah
	jz	not_volume_hosei
	push	ax
	mov	al,bl
	neg	ah
	mul	ah
	mov	bl,ah
	pop	ax
not_volume_hosei:
	test	bl,bl
	jz	ppsdrm_ret
	xor	bl,00001111b
	mov	ah,1
	and	al,7fh
	int	ppsdrv		;ppsdrv keyon
ppsdrm_ret:
	ret

;	TimerA
eg_nonppsdrv:
	mov	[psgefcnum],al
	xor	ah,ah
	mov	bx,ax
	add	bx,bx
	add	bx,ax
	add	bx,offset efftbl

	mov	al,[effon]
	cmp	al,[bx]		;優先順位
	ja	eg_ret

	cmp	[ppsdrv_flag],0
	jz	eok_nonppsdrv
	xor	ah,ah
	int	ppsdrv		;ppsdrv 強制keyoff
eok_nonppsdrv:
	mov	si,+1[bx]
	add	si,offset efftbl
	mov	al,[bx]		;AL=優先順位
	push	ax
	mov	bx,offset part9	;PSG 3ch
	or	partmask[bx],2	;Part Mask
	call	efffor		;１発目を発音
	pop	ax
	mov	[effon],al	;優先順位を設定(発音開始)
eg_ret:
	ret

;
;	こーかおん　えんそう　めいん	
; 	Ｆｒｏｍ　ＶＲＴＣ
;

effplay:
	mov	dl,[effcnt]

	dec	[effcnt]
	jne	effsweep	;新しくセットされない

	mov	si,[effadr]
efffor:
	lodsb
	cmp	al,-1
	je	effend
	mov	[effcnt],al	;カウント数

	mov	dh,4		;周波数レジスタ
	pushf
	cli
	call	efsnd		;周波数セット
	mov	cl,dl
	call	efsnd		;周波数セット
	popf
	mov	ch,dl
	mov	[eswthz],cx

	mov	dl,[si]
	mov	[eswnhz],dl
	mov	dh,6
	call	efsnd		; ノイズ
	mov	[psnoi_last],dl

	lodsb			; データ
	mov	dl,al
	rol	dl,1
	rol	dl,1
	and	dl,00100100b
	pushf
	cli
	call	get07
	and	al,11011011b
	or	dl,al
	call	opnset44		;MIX CONTROLL...
	popf

	mov	dh,10
	call	efsnd		;ボリューム
	call	efsnd		;エンベロープ周波数
	call	efsnd
	call	efsnd		;エンベロープPATTARN

	lodsb
	cbw
	mov	[eswtst],ax	;スイープ増分 (TONE)
	lodsb
	mov	[eswnst],al	;スイープ増分 (NOISE)

	and	al,15
	mov	[eswnct],al	;スイープカウント (NOISE)

	mov	[effadr],si
effret:	ret

efsnd:	lodsb
	mov	dl,al
	call	opnset44
	inc	dh
	ret

effoff:
	mov	dx,cs
	mov	ds,dx
effend:
	cmp	[ppsdrv_flag],0
	jz	ee_nonppsdrv
	xor	ah,ah
	int	ppsdrv		;ppsdrv keyoff
ee_nonppsdrv:
	mov	dx,0a00h
	call	opnset44	;volume min
	mov	dh,7
	pushf
	cli
	call	get07
	mov	dl,al		;NOISE CUT
	and	dl,11011011b
	or	dl,00100100b
	call	opnset44
	popf
	mov	[effon],0
	mov	[psgefcnum],-1
	ret

;普段の処理

effsweep:
	mov	ax,[eswthz]	;スイープ周波
	add	ax,[eswtst]
	mov	[eswthz],ax	;スイープ周波
	mov	dh,4		;REG
	mov	dl,al		;DATA
	pushf
	cli
	call	opnset44
	inc	dh
	mov	dl,ah
	call	opnset44

	call	get07
	mov	dl,al
	mov	dh,7
	call	opnset44
	popf

	mov	dl,[eswnst]
	or	dl,dl
	je	effret		;ノイズスイープ無し

	dec	[eswnct]
	jnz	effret

	mov	al,dl
	and	al,15
	mov	[eswnct],al

	sar	dl,1
	sar	dl,1
	sar	dl,1
	sar	dl,1
	add	[eswnhz],dl
	mov	dl,[eswnhz]
	mov	dh,6
	call	opnset44
	mov	[psnoi_last],dl
	ret

effadr		dw	?	;effect address
eswthz		dw	?	;トーンスゥイープ周波数
eswtst		dw	?	;トーンスゥイープ増分
effcnt		db	?	;effect count
eswnhz		db	?	;ノイズスゥイープ周波数
eswnst		db	?	;ノイズスゥイープ増分
eswnct		db	?	;ノイズスゥイープカウント
effon		db	?	;効果音　発音中
psgefcnum	db	?	;効果音番号
hosei_flag	db	?	;ppsdrv 音量/音程補正をするかどうか
last_shot_data	db	?	;最後に発音させたPPSDRV音色
