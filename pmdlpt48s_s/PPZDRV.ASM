;==============================================================================
;	ＰＣＭ音源　演奏　メイン [PPZ8]
;==============================================================================
ppz8_call:
	cmp	[ppz_call_seg],0
	jz	not_ppz_call
	int	ppz_vec
not_ppz_call:
	ret

ppzmain_ret:
	ret

ppzmain:
	mov	si,[di]		; si = PART DATA ADDRESS
	test	si,si
	jz	ppzmain_ret
	cmp	partmask[di],0
	jnz	ppzmain_nonplay

	; 音長 -1
	dec	leng[di]
	mov	al,leng[di]

	; KEYOFF CHECK
	test	keyoff_flag[di],3	; 既にkeyoffしたか？
	jnz	mp0z
	cmp	al,qdat[di]		; Q値 => 残りLength値時 keyoff
	ja	mp0z
	mov	keyoff_flag[di],-1
	call	keyoffz			; ALは壊さない

mp0z:	; LENGTH CHECK
	test	al,al
	jnz	mpexitz
mp1z0:	and	lfoswi[di],0f7h		; Porta off

mp1z:	; DATA READ
	lodsb
	cmp	al,80h
	jc	mp2z
	jz	mp15z

	; ELSE COMMANDS
	call	commandsz
	jmp	mp1z

	; END OF MUSIC [ 'L' ｶﾞ ｱｯﾀﾄｷﾊ ｿｺﾍ ﾓﾄﾞﾙ ]
mp15z:	dec	si
	mov	[di],si
	mov	loopcheck[di],3
	mov	onkai[di],-1
	mov	bx,partloop[di]
	test	bx,bx
	jz	mpexitz

	; 'L' ｶﾞ ｱｯﾀﾄｷ
	mov	si,bx
	mov	loopcheck[di],1
	jmp	mp1z

mp2z:	; F-NUMBER SET
	call	lfoinitp
	call	oshift
	call	fnumsetz

	lodsb
	mov	leng[di],al
	call	calc_q

porta_returnz:
	cmp	volpush[di],0
	jz	mp_newz
	cmp	onkai[di],-1
	jz	mp_newz
	dec	[volpush_flag]
	jz	mp_newz
	mov	[volpush_flag],0
	mov	volpush[di],0
mp_newz:call	volsetz
	call	otodasiz
	test	keyoff_flag[di],1
	jz	mp3z
	call	keyonz
mp3z:	inc	keyon_flag[di]
	mov	[di],si
	xor	al,al
	mov	[tieflag],al
	mov	[volpush_flag],al
	mov	keyoff_flag[di],al
	cmp	byte ptr [si],0fbh	; '&'が直後にあったらkeyoffしない
	jnz	mnp_ret
	mov	keyoff_flag[di],2
	jmp	mnp_ret

mpexitz:	
	mov	cl,lfoswi[di]
	mov	al,cl
	and	al,8
	mov	[lfo_switch],al
	test	cl,cl
	jz	volsz
	test	cl,3
	jz	not_lfoz
	call	lfo
	jnc	not_lfoz
	mov	al,cl
	and	al,3
	or	[lfo_switch],al
not_lfoz:
	test	cl,30h
	jz	not_lfoz2
	pushf
	cli
	call	lfo_change
	call	lfo
	jnc	not_lfoz1
	call	lfo_change
	popf
	mov	al,lfoswi[di]
	and	al,30h
	or	[lfo_switch],al
	jmp	not_lfoz2
not_lfoz1:
	call	lfo_change
	popf
not_lfoz2:
	test	[lfo_switch],19h
	jz	volsz

	test	[lfo_switch],8
	jz	not_portaz
	call	porta_calc
not_portaz:
	call	otodasiz
volsz:
	call	soft_env
	jc	volsz2
	test	[lfo_switch],22h
	jnz	volsz2
	cmp	[fadeout_speed],0
	jz	mnp_ret
volsz2:	call	volsetz
	jmp	mnp_ret

;==============================================================================
;	ＰＣＭ音源演奏メイン：パートマスクされている時
;==============================================================================
ppzmain_nonplay:
	mov	keyoff_flag[di],-1
	dec	leng[di]
	jnz	mnp_ret

ppzmnp_1:
	lodsb
	cmp	al,80h
	jz	ppzmnp_2

	jc	ppzmnp_3
	call	commandsz
	jmp	ppzmnp_1

ppzmnp_2:
	; END OF MUSIC [ "L"があった時はそこに戻る ]
	dec	si
	mov	[di],si
	mov	loopcheck[di],3
	mov	onkai[di],-1
	mov	bx,partloop[di]
	test	bx,bx
	jz	fmmnp_4

	; "L"があった時
	mov	si,bx
	mov	loopcheck[di],1
	jmp	ppzmnp_1

ppzmnp_3:
	mov	fnum2[di],0
	jmp	fmmnp_3

;==============================================================================
;	ＰＣＭ音源特殊コマンド処理
;==============================================================================
commandsz:
	mov	bx,offset cmdtblz
	jmp	command00
cmdtblz:
	dw	com@z
	dw	comq
	dw	comv
	dw	comt
	dw	comtie
	dw	comd
	dw	comstloop
	dw	comedloop
	dw	comexloop
	dw	comlopset
	dw	comshift
	dw	comvolupm
	dw	comvoldownm
	dw	lfoset
	dw	lfoswitch
	dw	psgenvset
	dw	comy
	dw	jump1
	dw	jump1
	;
	dw	pansetz
	dw	rhykey
	dw	rhyvs
	dw	rpnset
	dw	rmsvs
	;
	dw	comshift2
	dw	rmsvs_sft
	dw	rhyvs_sft
	;
	dw	jump1
	;
	dw	comvolupm2
	dw	comvoldownm2
	;
	dw	jump1
	dw	jump1
	;
	dw	syousetu_lng_set	;0DFH
	;
	dw	vol_one_up_pcm	;0deH
	dw	vol_one_down	;0DDH
	;
	dw	status_write	;0DCH
	dw	status_add	;0DBH
	;
	dw	portaz		;0DAH
	;
	dw	jump1		;0D9H
	dw	jump1		;0D8H
	dw	jump1		;0D7H
	;
	dw	mdepth_set	;0D6H
	;
	dw	comdd		;0d5h
	;
	dw	ssg_efct_set	;0d4h
	dw	fm_efct_set	;0d3h
	dw	fade_set	;0d2h
	;
	dw	jump1
	dw	jump1		;0d0h
	;
	dw	jump1		;0cfh
	dw	ppzrepeat_set	;0ceh
	dw	extend_psgenvset;0cdh
	dw	jump1		;0cch
	dw	lfowave_set	;0cbh
	dw	lfo_extend	;0cah
	dw	envelope_extend	;0c9h
	dw	jump3		;0c8h
	dw	jump3		;0c7h
	dw	jump6		;0c6h
	dw	jump1		;0c5h
	dw	comq2		;0c4h
	dw	pansetz_ex	;0c3h
	dw	lfoset_delay	;0c2h
	dw	jump0		;0c1h,sular
	dw	ppz_mml_part_mask	;0c0h
	dw	_lfoset		;0bfh
	dw	_lfoswitch	;0beh
	dw	_mdepth_set	;0bdh
	dw	_lfowave_set	;0bch
	dw	_lfo_extend	;0bbh
	dw	_volmask_set	;0bah
	dw	_lfoset_delay	;0b9h
	dw	jump2
	dw	mdepth_count	;0b7h
	dw	jump1
	dw	jump2
	dw	jump16		;0b4h
	dw	comq3		;0b3h
	dw	comshift_master	;0b2h
	dw	comq4		;0b1h

;==============================================================================
;	ppz 拡張パートセット
;==============================================================================
ppz_extpartset:
	push	di

	mov	di,offset part10a
	mov	cx,8
ppz_ex_loop:
	lodsw
	test	ax,ax
	jz	no_init_ppz
	add	ax,[mmlbuf]

	mov	address[di],ax
	mov	leng[di],1		; ｱﾄ 1ｶｳﾝﾄ ﾃﾞ ｴﾝｿｳ ｶｲｼ
	mov	al,-1
	mov	keyoff_flag[di],al	; 現在keyoff中
	mov	mdc[di],al		; MDepth Counter (無限)
	mov	mdc2[di],al		; //
	mov	_mdc[di],al		; //
	mov	_mdc2[di],al		; //
	mov	onkai[di],al		; rest
	mov	volume[di],128		; PCM VOLUME DEFAULT= 128
	mov	fmpan[di],5		; PAN=Middle

no_init_ppz:
	add	di,type qq
	loop	ppz_ex_loop
ppzext_exit:
	pop	di
	ret

;==============================================================================
;	演奏中パートのマスクon/off
;==============================================================================
ppz_mml_part_mask:
	lodsb
	cmp	al,2
	jnc	special_0c0h
	test	al,al
	jz	ppz_part_maskoff_ret
	or	partmask[di],40h
	cmp	partmask[di],40h
	jnz	pmpz_ret
	mov	al,[partb]
if	ademu
	cmp	al,7
	jnz	pmpz_exec
	cmp	[adpcm_emulate],1
	jz	pmpz_ret
pmpz_exec:
endif
	mov	ah,2
	call	ppz8_call		;発音停止
pmpz_ret:
	pop	ax		;commandsz
	jmp	ppzmnp_1

ppz_part_maskoff_ret:
	and	partmask[di],0bfh
	jnz	pmpz_ret
	pop	ax		;commandsm
	jmp	mp1z		;パート復活

;==============================================================================
;	リピート設定
;==============================================================================
ppzrepeat_set:
	push	es
	call	ppz_voicetable_calc
	mov	dx,es:6[bx]
	mov	cx,es:4[bx]	;dx:cx = データ量
	pop	es

	push	si
	push	di

	call	get_loop_ppz8
	push	ax
	push	bx
	call	get_loop_ppz8
	mov	di,bx
	mov	si,ax
	pop	dx
	pop	cx

	mov	ah,0eh
	mov	al,[partb]
	call	ppz8_call

	pop	di
	pop	si
	add	si,6

	ret

get_loop_ppz8:
	xor	bx,bx
	lodsw
	test	ax,ax
	jns	glp_ret
	dec	bx
	add	ax,cx
	adc	bx,dx
glp_ret:
	ret

ppz_voicetable_calc:
	xor	dx,dx
	mov	dl,voicenum[di]
	mov	ax,040dh
	test	dl,dl
	jns	pvc_a
	and	dl,07fh
	inc	al
pvc_a:	call	ppz8_call	;in. ES:BX
	add	bx,20h		;PZI Header Skip

	add	dx,dx
	mov	cx,dx
	add	dx,dx
	add	dx,dx
	add	dx,dx
	add	dx,cx	;x 12h
	add	bx,dx
	ret

;==============================================================================
;	ポルタメント(PCM)
;==============================================================================
portaz:
	cmp	partmask[di],0
	jnz	porta_notset

	pop	ax	;commandsp

	lodsb
	call	lfoinitp
	call	oshift
	call	fnumsetz

	mov	ax,fnum[di]
	push	ax
	mov	ax,fnum2[di]
	push	ax
	mov	al,onkai[di]
	push	ax

	lodsb
	call	oshift
	call	fnumsetz
	mov	dx,fnum2[di]
	mov	ax,fnum[di]	; dx:ax = ポルタメント先のdelta_n値

	pop	bx
	mov	onkai[di],bl
	pop	cx
	mov	fnum2[di],cx
	pop	bx		; cx:bx = ポルタメント元のdelta_n値
	mov	fnum[di],bx

	sub	ax,bx
	sbb	dx,cx		; dx:ax = delta_n差
	rept	4
	shr	dx,1
	rcr	ax,1		; /16
	endm

	mov	bl,[si]
	inc	si
	mov	leng[di],bl
	call	calc_q

	xor	bh,bh
	cwd
	idiv	bx		; ax = delta_n差 / 音長

	mov	porta_num2[di],ax	;商
	mov	porta_num3[di],dx	;余り
	or	lfoswi[di],8		;Porta ON

	jmp	porta_returnz

;==============================================================================
;	COMMAND 'p' [Panning Set]
;		0=0	無音
;		1=9	右
;		2=1	左
;		3=5	中央
;==============================================================================
pansetz:
	lodsb
	xor	bh,bh
	mov	bl,al
	add	bx,offset ppzpandata
	mov	al,[bx]
pansetz_main:
	mov	fmpan[di],al
	xor	dx,dx
	mov	dl,al
	mov	ah,13h
	mov	al,[partb]
	call	ppz8_call
	ret

;==============================================================================
;	Pan setting Extend
;		px -4～+4
;==============================================================================
pansetz_ex:
	lodsb
	inc	si	;逆相flagは読み飛ばす
	test	al,al
	js	pzex_minus
	cmp	al,5
	jc	pzex_set
	mov	al,4
	jmp	pzex_set
pzex_minus:
	cmp	al,-4
	jnc	pzex_set
	mov	al,-4
pzex_set:
	add	al,5
	jmp	pansetz_main

;==============================================================================
;	COMMAND '@' [NEIRO Change]
;==============================================================================
com@z:
	lodsb
if	ademu
	cmp	[adpcm_emulate],1
	jnz	c@z_adchk_exit
	test	al,al
	jns	c@z_partchk
	mov	al,127		;ADPCMEmulate中は @128～なら @127に強制変更
c@z_partchk:
	cmp	[partb],7
	jnz	c@z_adchk_exit
	mov	bx,offset part10	;PPZADEmuPart
	or	partmask[bx],10h	;Mask
	and	partmask[di],0efh	;Mask off
	jnz	c@z_emuoff
	pop	bx			;
	mov	bx,offset mp1z		; Part復活準備
	push	bx			;
c@z_emuoff:
	push	ax
	mov	ax,1800h
	mov	[adpcm_emulate],al
	call	ppz8_call		;ADPCMEmulate OFF
	pop	ax
c@z_adchk_exit:
endif
	mov	voicenum[di],al

ppz_neiro_reset:
	push	es
	push	si
	push	di
	call	ppz_voicetable_calc
	mov	dx,es:0ah[bx]
	mov	cx,es:08h[bx]	;dx:cx = Loop Start
	mov	di,es:0eh[bx]
	mov	si,es:0ch[bx]	;di:si = Loop End
	mov	ah,0eh
	mov	al,[partb]
	push	es
	push	bx
	call	ppz8_call
	pop	bx
	pop	es
	mov	dx,es:10h[bx]	;dx = Frequency
	mov	ah,15h
	mov	al,[partb]
	call	ppz8_call
	pop	di
	pop	si
	pop	es
c@z_exit:
	ret	

;==============================================================================
;	PPZ VOLUME SET
;==============================================================================
volsetz:
	mov	al,volpush[di]
	test	al,al
	jnz	vsz_01
	mov	al,volume[di]
vsz_01:	mov	dl,al

;------------------------------------------------------------------------------
;	音量down計算
;------------------------------------------------------------------------------
	mov	al,[ppz_voldown]
	test	al,al
	jz	ppz_fade_calc
	neg	al
	mul	dl
	mov	dl,ah

;------------------------------------------------------------------------------
;	Fadeout計算
;------------------------------------------------------------------------------
ppz_fade_calc:
	mov	al,[fadeout_volume]
	test	al,al
	jz	ppz_env_calc
	neg	al
	mul	dl
	mov	dl,ah

;------------------------------------------------------------------------------
;	ENVELOPE 計算
;------------------------------------------------------------------------------
ppz_env_calc:
	mov	al,dl
	test	al,al	;音量0?
	jz	zv_out

	cmp	envf[di],-1
	jnz	normal_zvset
;	拡張版 音量=al*(eenv_vol+1)/16
	mov	dl,eenv_volume[di]
	test	dl,dl
	jz	zv_min
	inc	dl
	mul	dl
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	jnc	zvset
	inc	ax
	jmp	zvset

normal_zvset:
	mov	ah,penv[di]
	test	ah,ah
	jns	zvplus
	; -
	neg	ah
	add	ah,ah
	add	ah,ah
	add	ah,ah
	add	ah,ah
	sub	al,ah
	jnc	zvset
zv_min:	xor	al,al
	jmp	zv_out
	; +
zvplus:	add	ah,ah
	add	ah,ah
	add	ah,ah
	add	ah,ah
	add	al,ah
	jnc	zvset
	mov	al,255

;------------------------------------------------------------------------------
;	音量LFO計算
;------------------------------------------------------------------------------
zvset:
	test	lfoswi[di],22h
	jz	zv_out

	xor	dx,dx
	mov	ah,dl
	test	lfoswi[di],2
	jz	zv_nolfo1
	mov	dx,lfodat[di]
zv_nolfo1:
	test	lfoswi[di],20h
	jz	zv_nolfo2
	add	dx,_lfodat[di]
zv_nolfo2:
	test	dx,dx
	js	zvlfo_minus
	add	ax,dx
	test	ah,ah
	jz	zv_out
	mov	al,255
	jmp	zv_out
zvlfo_minus:
	add	ax,dx
	jc	zv_out
	xor	al,al

;------------------------------------------------------------------------------
;	出力
;------------------------------------------------------------------------------
zv_out:	test	al,al
	jz	zv_cut
	xor	dh,dh
	mov	dl,al
	shr	dx,1
	shr	dx,1
	shr	dx,1
	shr	dx,1		;dx=volume (0～15)
	mov	ah,07h
	mov	al,[partb]
	call	ppz8_call
	ret

zv_cut:	mov	ah,02h
	mov	al,[partb]
	call	ppz8_call		;volume=0 ... keyoff
	ret

;==============================================================================
;	PPZ KEYON
;==============================================================================
keyonz:
	cmp	onkai[di],-1
	jz	keyonz_ret
;;	xor	dx,dx
;;	mov	dl,fmpan[di]
;;	mov	ah,13h
;;	mov	al,[partb]
;;	call	ppz8_call

	mov	ah,01h
	mov	al,[partb]
	mov	dl,voicenum[di]
	mov	dh,dl
	and	dx,807fh	; dx=voicenum
	call	ppz8_call	; ppz keyon
keyonz_ret:
	ret

;==============================================================================
;	ppz KEYOFF
;==============================================================================
keyoffz:
	cmp	envf[di],-1
	jz	kofz1_ext
	cmp	envf[di],2
	jnz	keyoffp
kofz_ret:
	ret
kofz1_ext:
	cmp	eenv_count[di],4
	jz	kofz_ret
	jmp	keyoffp

;==============================================================================
;	PPZ OTODASI
;==============================================================================
otodasiz:
	mov	cx,fnum[di]
	mov	bx,fnum2[di]	;bx:cx = fnum
	mov	ax,cx
	or	ax,bx
	jnz	odz_00
	ret
odz_00:
	;
	; Portament/LFO/Detune SET
	;
	mov	ax,porta_num[di]
	test	ax,ax
	jz	odz_not_porta
	cwd
	rept	4
	add	ax,ax
	adc	dx,dx		;x16
	endm
	add	cx,ax
	adc	bx,dx

odz_not_porta:
	xor	ax,ax
	test	lfoswi[di],11h
	jz	odz_not_lfo
	test	lfoswi[di],1
	jz	odz_not_lfo1
	add	ax,lfodat[di]
odz_not_lfo1:
	test	lfoswi[di],10h
	jz	odz_not_lfo
	add	ax,_lfodat[di]
odz_not_lfo:
	add	ax,detune[di]

	mov	dl,ch
	mov	dh,bl
	imul	dx
	js	odz_minus

	add	cx,ax
	adc	bx,dx
	jnc	odz_main
	mov	cx,-1
	mov	bx,cx
	jmp	odz_main
odz_minus:
	add	cx,ax
	adc	bx,dx
	jc	odz_main
	xor	cx,cx
	mov	bx,cx
	;
	; TONE SET
	;
odz_main:
	mov	ah,0bh
	mov	al,[partb]
	mov	dx,bx
	call	ppz8_call
	ret

;==============================================================================
;	PPZ FNUM SET
;==============================================================================
fnumsetz:
	mov	ah,al
	and	ah,0fh
	cmp	ah,0fh
	jz	fnrestz		; 休符の場合
	mov	onkai[di],al

	xor	bh,bh
	mov	bl,ah		; bx=onkai
	ror	al,1
	ror	al,1
	ror	al,1
	ror	al,1
	and	al,0fh
	mov	cl,al		; cl=octarb

	add	bx,bx
	mov	ax,ppz_tune_data[bx]	;o5標準
	xor	dx,dx

	sub	cl,4
	jns	ppz_over_o5
	neg	cl
	shr	ax,cl
	jmp	ppz_fnumset

ppz_over_o5:
	jz	ppz_fnumset
	xor	ch,ch
ppz_over_o5_loop:
	add	ax,ax
	adc	dx,dx
	loop	ppz_over_o5_loop

ppz_fnumset:
	mov	fnum[di],ax
	mov	fnum2[di],dx
	ret
fnrestz:
	mov	onkai[di],-1
	test	lfoswi[di],11h
	jnz	fnrz_ret
	mov	fnum[di],0
	mov	fnum2[di],0
fnrz_ret:
	ret

;==============================================================================
;	Datas
;==============================================================================
ppzpandata	db	0,9,1,5

ppz_tune_data	label	word
	dw	08000h	;00 c
	dw	087a6h	;01 d-
	dw	08fb3h	;02 d
	dw	09838h	;03 e-
	dw	0a146h	;04 e
	dw	0aadeh	;05 f
	dw	0b4ffh	;06 g-
	dw	0bfcch	;07 g
	dw	0cb34h	;08 a-
	dw	0d747h	;09 a
	dw	0e418h	;10 b-
	dw	0f1a5h	;11 b
