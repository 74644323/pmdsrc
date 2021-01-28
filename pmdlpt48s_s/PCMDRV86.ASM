;==============================================================================
;	ＰＣＭ音源　演奏　メイン (86B PCM)
;==============================================================================
pcmmain_ret:
	ret

pcmmain:
	mov	si,[di]		; si = PART DATA ADDRESS
	test	si,si
	jz	pcmmain_ret
	cmp	partmask[di],0
	jnz	pcmmain_nonplay

	; 音長 -1
	dec	leng[di]
	mov	al,leng[di]

	; KEYOFF CHECK
	test	keyoff_flag[di],3	; 既にkeyoffしたか？
	jnz	mp0m
	cmp	al,qdat[di]		; Q値 => 残りLength値時 keyoff
	ja	mp0m
mp00m:	call	keyoffm			;ALは壊さない
	mov	keyoff_flag[di],-1

mp0m:	; LENGTH CHECK
	test	al,al
	jnz	mpexitm
mp1m0:

mp1m:	; DATA READ
	lodsb
	cmp	al,80h
	jc	mp2m
	jz	mp15m

	; ELSE COMMANDS
	call	commandsm
	jmp	mp1m

	; END OF MUSIC [ 'L' ｶﾞ ｱｯﾀﾄｷﾊ ｿｺﾍ ﾓﾄﾞﾙ ]
mp15m:	dec	si
	mov	[di],si
	mov	loopcheck[di],3
	mov	onkai[di],-1
	mov	bx,partloop[di]
	test	bx,bx
	jz	mpexitm

	; 'L' ｶﾞ ｱｯﾀﾄｷ
	mov	si,bx
	mov	loopcheck[di],1
	jmp	mp1m

mp2m:	; F-NUMBER SET
	call	lfoinitp
	call	oshift
	call	fnumsetm

	lodsb
	mov	leng[di],al
	call	calc_q

	cmp	volpush[di],0
	jz	mp_newm
	cmp	onkai[di],-1
	jz	mp_newm
	dec	[volpush_flag]
	jz	mp_newm
	mov	[volpush_flag],0
	mov	volpush[di],0
mp_newm:call	volsetm
	call	otodasim
	test	keyoff_flag[di],1
	jz	mp3m
	call	keyonm
mp3m:	inc	keyon_flag[di]
	mov	[di],si
	xor	al,al
	mov	[tieflag],al
	mov	[volpush_flag],al
	mov	keyoff_flag[di],al
	cmp	byte ptr [si],0fbh	; '&'が直後にあったらkeyoffしない
	jnz	mnp_ret
	mov	keyoff_flag[di],2
	jmp	mnp_ret

mpexitm:	
	mov	cl,lfoswi[di]
	test	cl,22h
	jz	not_lfo3m

	mov	[lfo_switch],0
	test	cl,2
	jz	not_lfom
	call	lfo
	mov	al,cl
	and	al,2
	mov	[lfo_switch],al
not_lfom:
	test	cl,20h
	jz	not_lfo2m
	pushf
	cli
	call	lfo_change
	call	lfo
	jnc	not_lfo1m
	call	lfo_change
	popf
	mov	al,lfoswi[di]
	and	al,20h
	or	[lfo_switch],al
	jmp	not_lfo2m
not_lfo1m:
	call	lfo_change
	popf
not_lfo2m:
	call	soft_env
	jc	volsm2
	test	[lfo_switch],22h
	jnz	volsm2
volsm1:	cmp	[fadeout_speed],0
	jz	mnp_ret
volsm2:	call	volsetm
	jmp	mnp_ret
not_lfo3m:
	call	soft_env
	jc	volsm2
	jmp	volsm1

;==============================================================================
;	ＰＣＭ音源演奏メイン：パートマスクされている時
;==============================================================================
pcmmain_nonplay:
	dec	leng[di]
	jnz	mnp_ret

	test	partmask[di],2		;bit1(pcm効果音中？)をcheck
	jz	pcmmnp_1
	cmp	[play86_flag],1
	jz	pcmmnp_1		;まだ割り込みPCMが鳴っている
	mov	[pcmflag],0		;PCM効果音終了
	mov	[pcm_effec_num],255
	and	partmask[di],0fdh	;bit1をclear
	jnz	pcmmnp_1
	mov	al,voicenum[di]
	call	neiro_set
	mov	al,fmpan[di]
	mov	ah,[revpan]
	call	set_pcm_pan
	jmp	mp1m0			;partmaskが0なら復活させる

pcmmnp_1:
	lodsb
	cmp	al,80h
	jnz	pcmmnp_2

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
	jmp	pcmmnp_1

pcmmnp_2:
	jc	fmmnp_3
	call	commandsm
	jmp	pcmmnp_1

;==============================================================================
;	ＰＣＭ音源特殊コマンド処理
;==============================================================================
commandsm:
	mov	bx,offset cmdtblm
	jmp	command00
cmdtblm:
	dw	com@m
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
	dw	pansetm
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
	;Ｖ２．３　ＥＸＴＥＮＤ
	dw	comvolupm2
	dw	comvoldownm2
	;
	dw	jump1
	dw	jump1
	;
	dw	syousetu_lng_set	;0DFH
	;
	dw	vol_one_up_pcm	;0DEH
	dw	vol_one_down	;0DDH
	;
	dw	status_write	;0DCH
	dw	status_add	;0DBH
	;
	dw	jump1		;0DAH
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
	dw	pcmrepeat_set	;0ceh
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
	dw	pansetm_ex	;0c3h
	dw	lfoset_delay	;0c2h
	dw	jump0		;0c1h,sular
	dw	pcm_mml_part_mask	;0c0h
	dw	jump4		;0bfh
	dw	jump1		;0beh
	dw	jump2		;0bdh
	dw	jump1		;0bch
	dw	jump1		;0bbh
	dw	jump1		;0bah
	dw	jump1		;0b9h
	dw	jump2
	dw	mdepth_count	;0b7h
	dw	jump1
	dw	jump2
	dw	jump16		;0b4h
	dw	comq3		;0b3h
	dw	comshift_master	;0b2h

;==============================================================================
;	演奏中パートのマスクon/off
;==============================================================================
pcm_mml_part_mask:
	lodsb
	cmp	al,2
	jnc	special_0c0h
	test	al,al
	jz	pcm_part_maskoff_ret
	or	partmask[di],40h
	cmp	partmask[di],40h
	jnz	pmpm_ret
	call	stop_86pcm
pmpm_ret:
	pop	ax		;commandsm
	jmp	pcmmnp_1

pcm_part_maskoff_ret:
	and	partmask[di],0bfh
	jnz	pmpm_ret
	pop	ax		;commandsm
	jmp	mp1m	;パート復活

;==============================================================================
;	リピート設定
;==============================================================================
pcmrepeat_set:

	mov	ax,[_start_ofs]
	mov	[repeat_ofs],ax
	mov	ax,[_start_ofs2]
	mov	[repeat_ofs2],ax	;repeat開始位置 = start位置に設定
	mov	dx,[_size1]
	mov	[repeat_size1],dx
	mov	cx,[_size2]		;cx:dx=全体size
	mov	[repeat_size2],cx	;repeat_size = 今のsizeに設定
	mov	[repeat_flag],1
	mov	[release_flag1],0

	push	dx			;サイズを保存
	push	cx			;

;	一個目 = リピート開始位置
	lodsw
	test	ax,ax
	js	prs1_minus

	;正の場合
	call	pcm86vol_chk
	sub	[repeat_size1],ax	;リピートサイズ＝全体のサイズ-指定値
	sbb	[repeat_size2],0
	add	[repeat_ofs],ax		;リピート開始位置から指定値を加算
	adc	[repeat_ofs2],0
	jmp	prs2_set

	;負の場合
prs1_minus:
	neg	ax
	call	pcm86vol_chk
	mov	[repeat_size1],ax	;リピートサイズ＝neg(指定値)
	mov	[repeat_size2],0

	sub	dx,ax
	sbb	cx,0
	add	[repeat_ofs],dx		;リピート開始位置に
	adc	[repeat_ofs2],cx	;(全体サイズ-指定値)を加算

;	２個目 = リピート終了位置
prs2_set:
	lodsw
	test	ax,ax
	jz	prs3_set	;0なら計算しない
	js	prs2_minus

	;正の場合
	call	pcm86vol_chk
	mov	[_size1],ax	;正ならpcmサイズ＝指定値
	mov	[_size2],0
	sub	dx,ax		;リピートサイズから(旧サイズ-新サイズ)を引く
	sbb	cx,0
	sub	[repeat_size1],dx
	sbb	[repeat_size2],cx
	jmp	prs3_set

	;負の場合
prs2_minus:
	neg	ax
	call	pcm86vol_chk
	sub	[repeat_size1],ax	;リピートサイズから
	sbb	[repeat_size2],0	;neg(指定値)を引く
	sub	[_size1],ax		;本来のサイズから指定値を引く
	sbb	[_size2],0

;	３個目 = リリース開始位置
prs3_set:
	pop	cx
	pop	dx			;cx:dx=全体サイズ復帰
	lodsw
	cmp	ax,8000h
	jz	prs_exit		;8000Hなら設定しない
	mov	bx,[_start_ofs]
	mov	[release_ofs],bx
	mov	bx,[_start_ofs2]
	mov	[release_ofs2],bx	;release開始位置 = start位置に設定
	mov	[release_size1],dx
	mov	[release_size2],cx	;release_size = 今のsizeに設定
	mov	[release_flag1],1	;リリースするに設定
	jnc	prs3_minus

	;正の場合
	call	pcm86vol_chk
	sub	[release_size1],ax	;リリースサイズ＝全体のサイズ-指定値
	sbb	[release_size2],0
	add	[release_ofs],ax	;リリース開始位置から指定値を加算
	adc	[release_ofs2],0
	jmp	prs_exit

	;負の場合
prs3_minus:
	neg	ax
	call	pcm86vol_chk
	mov	[release_size1],ax	;リリースサイズ＝neg(指定値)
	mov	[release_size2],0
	sub	dx,ax
	sbb	cx,0
	add	[release_ofs],dx	;リリース開始位置に
	adc	[release_ofs2],cx	;(全体サイズ-指定値)を加算

prs_exit:
	ret

;==============================================================================
;	/Sオプション指定時はAXを32倍する
;==============================================================================
pcm86vol_chk:
	cmp	[pcm86_vol],0
	jz	not_p86chk
	add	ax,ax
	add	ax,ax
	add	ax,ax
	add	ax,ax
	add	ax,ax
not_p86chk:
	ret

;==============================================================================
;	COMMAND ')' [VOLUME UP]
;==============================================================================
comvolupm:
	mov	al,volume[di]	
	add	al,16
vupckm:
	jnc	vsetm
	mov	al,255
vsetm:	mov	volume[di],al
	ret

	;Ｖ２．３　ＥＸＴＥＮＤ
comvolupm2:
	lodsb
	add	al,volume[di]
	jmp	vupckm

;==============================================================================
;	COMMAND '(' [VOLUME DOWN]
;==============================================================================
comvoldownm:
	mov	al,volume[di]
	sub	al,16
	jnc	vsetm
	xor	al,al
	jmp	vsetm
	;Ｖ２．３　ＥＸＴＥＮＤ
comvoldownm2:
	lodsb
	mov	ah,al
	mov	al,volume[di]
	sub	al,ah
	jnc	vsetm
	xor	al,al
	jmp	vsetm

;==============================================================================
;	COMMAND 'p' [Panning Set]
;	p0		逆相
;	p1		右
;	p2		左
;	p3		中
;==============================================================================
pansetm:
	xor	ah,ah
	lodsb
	dec	al
	jz	psm_right
	dec	al
	jz	psm_left
	dec	al
	jz	psm_mid
	inc	ah	;逆相
psm_mid:
	xor	al,al
	jmp	set_pcm_pan
psm_left:
	mov	al,-128
	jmp	set_pcm_pan
psm_right:
	mov	al,+127
	jmp	set_pcm_pan

;==============================================================================
;	COMMAND 'px' [Panning Set Extend]
;	px-127～+127,0or1
;==============================================================================
pansetm_ex:
	lodsb
	mov	ah,[si]
	inc	si
set_pcm_pan:
	mov	fmpan[di],al
	mov	[revpan],ah
set_pcm_pan2:
	test	al,al
	js	psmex_left
	jz	psmex_mid

;	右寄り
	mov	[pcm86_pan_flag],2	;Right
	not	al
	and	al,127
	jmp	psmex_gs_set

;	左寄り
psmex_left:
	mov	[pcm86_pan_flag],1	;Left
	add	al,128
	and	al,127
	jmp	psmex_gs_set

;	真ん中
psmex_mid:
	mov	[pcm86_pan_flag],3	;Middle
	xor	al,al
psmex_gs_set:
	mov	[pcm86_pan_dat],al
	test	ah,1
	jz	psmex_ret
	or	[pcm86_pan_flag],4	;逆相
psmex_ret:
	ret

;==============================================================================
;	COMMAND '@' [NEIRO Change]
;==============================================================================
com@m:
	lodsb
	mov	voicenum[di],al
neiro_set:
	xor	ah,ah
	add	ax,ax
	mov	bx,ax
	add	ax,ax
	add	bx,ax	;bx=al*6
	add	bx,offset pcmadrs
	mov	ax,[bx]		;ofs2(w)
	inc	bx
	inc	bx
	mov	[_start_ofs],ax
	xor	ax,ax
	adc	al,[bx]		;ofs1(b)
	inc	bx
	mov	[_start_ofs2],ax
	mov	ax,[bx]
	inc	bx
	inc	bx
	mov	[_size1],ax
	xor	ah,ah
	mov	al,[bx]
	mov	[_size2],ax

	mov	[repeat_flag],0
	mov	[release_flag1],0
	ret	

;==============================================================================
;	PCM VOLUME SET
;==============================================================================
volsetm:
	mov	al,volpush[di]
	test	al,al
	jnz	vsm_01
	mov	al,volume[di]
vsm_01:	mov	dl,al

;------------------------------------------------------------------------------
;	音量down計算
;------------------------------------------------------------------------------
	mov	al,[pcm_voldown]
	test	al,al
	jz	pcm_fade_calc
	neg	al
	mul	dl
	mov	dl,ah

;------------------------------------------------------------------------------
;	Fadeout計算
;------------------------------------------------------------------------------
pcm_fade_calc:
	mov	al,[fadeout_volume]
	test	al,al
	jz	pcm_env_calc
	neg	al
	mul	dl
	mov	dl,ah

;------------------------------------------------------------------------------
;	ENVELOPE 計算
;------------------------------------------------------------------------------
pcm_env_calc:
	mov	al,dl
	test	al,al	;音量0?
	jz	mv_out

	cmp	envf[di],-1
	jnz	normal_mvset
;	拡張版 音量=al*(eenv_vol+1)/16
	mov	dl,eenv_volume[di]
	test	dl,dl
	jz	mv_min
	inc	dl
	mul	dl
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	jnc	mvset
	inc	ax
	jmp	mvset

normal_mvset:
	mov	ah,penv[di]
	test	ah,ah
	jns	mvplus
	; -
	neg	ah
	add	ah,ah
	add	ah,ah
	add	ah,ah
	add	ah,ah
	sub	al,ah
	jnc	mvset
mv_min:	xor	al,al
	jmp	mv_out
	; +
mvplus:	add	ah,ah
	add	ah,ah
	add	ah,ah
	add	ah,ah
	add	al,ah
	jnc	mvset
	mov	al,255

;------------------------------------------------------------------------------
;	音量LFO計算
;------------------------------------------------------------------------------
mvset:
	test	lfoswi[di],22h
	jz	mv_out

	xor	dx,dx
	mov	ah,dl
	test	lfoswi[di],2
	jz	mv_nolfo1
	mov	dx,lfodat[di]
mv_nolfo1:
	test	lfoswi[di],20h
	jz	mv_nolfo2
	add	dx,_lfodat[di]
mv_nolfo2:
	test	dx,dx
	js	mvlfo_minus
	add	ax,dx
	test	ah,ah
	jz	mv_out
	mov	al,255
	jmp	mv_out
mvlfo_minus:
	add	ax,dx
	jc	mv_out
	xor	al,al

;------------------------------------------------------------------------------
;	出力
;------------------------------------------------------------------------------
mv_out:
;	音量設定
	cmp	[pcm86_vol],0
	jz	pcm_normal_set

;	SPBと同様の音量設定
;	al=sqr(al)
	mov	ah,al
	xor	al,al
	stc
sqr_loop:
	sbb	ah,al
	jc	pcm_vol_set
	sbb	ah,al
	jc	pcm_vol_set
	inc	al
	cmp	al,15
	jz	pcm_vol_set
	jmp	sqr_loop

pcm_normal_set:
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
pcm_vol_set:
	and	al,00001111b
	xor	al,00001111b
	or	al,0a0h		;PCM音量
	mov	dx,0a466h
	out	dx,al
	ret

;==============================================================================
;	PCM KEYON
;==============================================================================
keyonm:	
	cmp	onkai[di],-1
	jnz	keyonm_00
	ret			; ｷｭｳﾌ ﾉ ﾄｷ
keyonm_00:
	push	si
	push	di
	call	play_86pcm
	pop	di
	pop	si
	ret

;==============================================================================
;	PCM KEYOFF
;==============================================================================
keyoffm:
	cmp	[release_flag1],1	;リリースが設定されているか?
	jnz	kofm_not_release
	push	ax
	mov	ax,[release_ofs]
	mov	[start_ofs],ax
	mov	ax,[release_ofs2]
	mov	[start_ofs2],ax
	mov	ax,[release_size1]
	mov	[size1],ax
	mov	ax,[release_size2]
	mov	[size2],ax
	pop	ax
	mov	[release_flag2],1	;リリースした

kofm_not_release:
	cmp	envf[di],-1
	jz	kofm1_ext
	cmp	envf[di],2
	jnz	keyoffp
kofm_ret:
	ret
kofm1_ext:
	cmp	eenv_count[di],4
	jz	kofm_ret
	jmp	keyoffp

;==============================================================================
;	PCM 周波数設定
;==============================================================================
otodasim:
	mov	bx,fnum[di]
	test	bx,bx
	jnz	tone_set
	ret
tone_set:
	mov	ax,fnum2[di]
	cmp	[pcm86_vol],1	;ADPCMに合わせる場合
	jz	tone_set2	;DetuneはCut
	cmp	detune[di],0
	jz	tone_set2
	mov	cx,ax
	mov	dx,bx
	rept	5
	shr	dx,1
	rcr	cx,1
	endm			;cx=zzzzzxxx xxxxxxxx
	mov	dx,detune[di]
	test	dx,dx
	js	tsdt_minus
	add	cx,dx
	jnc	tone_set1
	mov	cx,-1
	jmp	tone_set1
tsdt_minus:
	add	cx,dx
	jz	tsdtm0
	jc	tone_set1
tsdtm0:	mov	cx,1		;0にすると加算値0になる危険があるので1にする
tone_set1:
	xor	dx,dx
	rept	5
	shl	cx,1
	rcl	dx,1
	endm			;dx:cx=00000000 000zzzzz xxxxxxxx xxx00000
	and	bx,1111111111100000b
	and	ax,0000000000011111b
	or	bx,dx
	or	ax,cx
tone_set2:
	mov	[addsize2],ax
	mov	[addsize1],bl
	and	[addsize1],1fh

	rol	bl,1
	rol	bl,1
	rol	bl,1
	and	bl,7
	xor	bl,7

;	周波数設定
	mov	dx,0a468h
	pushf
	cli
	in	al,dx
	out	5fh,al
	and	al,0f8h
	or	al,bl
	out	dx,al
	popf
	ret

;==============================================================================
;	PCM FNUM SET
;==============================================================================
fnumsetm:
	mov	ah,al
	and	ah,0fh
	cmp	ah,0fh
	jz	fnrest		; 休符の場合

	cmp	[pcm86_vol],1
	jnz	fsm_noad
	cmp	al,065h		; o7e?
	jc	fsm_noad
	mov	al,50h		;o6
	cmp	ah,5	;ah=onkai
	jnc	fsm_00
	mov	al,60h		;o7
fsm_00:	or	al,ah

fsm_noad:
	mov	onkai[di],al
	and	al,0f0h
	shr	al,1
	mov	bl,al		;bl=octave *8
	shr	al,1		;al=octave *4
	add	bl,al
	add	bl,ah		;bl=octave *12 + 音階
	xor	bh,bh
	mov	ax,bx
	add	bx,bx
	add	bx,ax
	add	bx,offset pcm_tune_data
	mov	al,[bx]
	or	ax,0ff00h
	mov	fnum[di],ax	;ax=0ff00h + addsize1
	inc	bx
	mov	ax,[bx]		;ax=addsize2
	mov	fnum2[di],ax
	ret

;==============================================================================
;	FIFO int Subroutine
;		*FIFOが来ている事を確認してから飛んで来ること。
;		 pushしてあるレジスタは ax/dx/ds のみ。
;==============================================================================
fifo_main:
;------------------------------------------------------------------------------
;	割り込み許可
;------------------------------------------------------------------------------
	cmp	[disint],1
	jz	fifo_not_sti
	sti			;早速割り込み許可
fifo_not_sti:

;------------------------------------------------------------------------------
;	PCM処理 main
;------------------------------------------------------------------------------
	cmp	[play86_flag],0	;PCM再生中か？
	jz	not_trans
	cmp	[trans_flag],0	;次を転送するか？
	jnz	i5_trans
	call	stop_86pcm	;PLAY中で且つ次にはもうデータはない= stop
	ret			;FIFOは許可しないで終了

i5_trans:
	push	bx
	push	cx
	push	si
	push	di
	push	bp
	call	pcm_trans
	pop	bp
	pop	di
	pop	si
	pop	cx
	pop	bx

;------------------------------------------------------------------------------
;	割り込み禁止
;------------------------------------------------------------------------------
not_trans:
	cli
;------------------------------------------------------------------------------
;	FIFO割り込みフラグreset
;------------------------------------------------------------------------------
	mov	dx,0a468h
	in	al,dx
	out	5fh,al
	and	al,0efh
	out	dx,al		;FIFO割り込みフラグ消去
	out	5fh,al
	or	al,010h
	out	dx,al		;FIFO割り込みフラグ消去解除
	ret

;==============================================================================
;	PCMdata 転送
;		use ax/bx/cx/dx/si/di/bp
;==============================================================================
pcm_trans2:
	mov	cx,trans_size		;転送するbytes
	jmp	pcm_trans_main
pcm_trans:
	mov	cx,trans_size/2		;転送するbytes
pcm_trans_main:
	push	es
	xor	ax,ax
	mov	es,ax
	les	bx,es:[65h*4]		;P86drv
	cmp	word ptr es:2[bx],"8P"
	jnz	p8c_nores
	cmp	byte ptr es:4[bx],"6"
p8c_nores:
	pop	es
	jnz	zero_trans		;常駐していない場合

	mov	ah,-1
	int	65h
	cmp	al,10h
	jc	zero_trans		;ver.1.0以前の場合

	xor	ah,ah
	mov	al,[pcm86_pan_flag]
	add	ax,ax
	add	ax,offset trans_table
	mov	bp,ax			;bp=転送処理sub offset

	mov	dx,0a46ch
	mov	ax,[size1]
	mov	di,ax		;di=残りsize(下位16bit)
	or	ax,[size2]
	jz	zero_trans

	push	ds

	mov	ah,-5
	int	65h		;p86drv pushems

	mov	ah,[addsize1]
	mov	bx,[addsize2]

	call	get_data_offset	;ds:si = data offset
	call	cs:[bp]

	mov	ah,-4
	int	65h		;p86drv popems

	pop	ds
	ret

;------------------------------------------------------------------------------
;	真ん中
;------------------------------------------------------------------------------
double_trans:
	xor	bp,bp
double_trans_loop:
	mov	al,[si]
	out	dx,al	;左
	out	dx,al	;右
	call	add_address
	jc	trans_fin
	loop	double_trans_loop

trans_exit:
	add	cs:[start_ofs],bp	;bp=転送したサイズ
	adc	cs:[start_ofs2],0
	mov	cs:[size1],di
	ret

;------------------------------------------------------------------------------
;	真ん中 (逆相)
;------------------------------------------------------------------------------
double_trans_g:
	xor	bp,bp
double_trans_g_loop:
	mov	al,[si]
	out	dx,al	;左
	neg	al	;逆相
	out	dx,al	;右
	call	add_address
	jc	trans_fin
	loop	double_trans_g_loop
	jmp	trans_exit

;------------------------------------------------------------------------------
;	左寄り
;------------------------------------------------------------------------------
left_trans:
	xor	bp,bp
left_trans_loop:
	mov	al,[si]

	out	dx,al	;左

	push	ax
	imul	cs:[pcm86_pan_dat]
	add	ax,ax
	mov	al,ah
	out	dx,al	;右
	pop	ax

	call	add_address
	jc	trans_fin

	loop	left_trans_loop
	jmp	trans_exit

;------------------------------------------------------------------------------
;	左寄り(逆相)
;------------------------------------------------------------------------------
left_trans_g:
	xor	bp,bp
left_trans_g_loop:
	mov	al,[si]

	out	dx,al	;左
	neg	al	;逆相
	push	ax
	imul	cs:[pcm86_pan_dat]
	add	ax,ax
	mov	al,ah
	out	dx,al	;右
	pop	ax

	call	add_address
	jc	trans_fin

	loop	left_trans_g_loop
	jmp	trans_exit

;------------------------------------------------------------------------------
;	右寄り
;------------------------------------------------------------------------------
right_trans:
	xor	bp,bp
right_trans_loop:
	mov	al,[si]

	push	ax
	imul	cs:[pcm86_pan_dat]
	add	ax,ax
	mov	al,ah
	out	dx,al	;左
	pop	ax

	out	dx,al	;右

	call	add_address
	jc	trans_fin

	loop	right_trans_loop
	jmp	trans_exit

;------------------------------------------------------------------------------
;	右寄り (逆相)
;------------------------------------------------------------------------------
right_trans_g:
	xor	bp,bp
right_trans_g_loop:
	mov	al,[si]

	push	ax
	imul	cs:[pcm86_pan_dat]
	add	ax,ax
	mov	al,ah
	out	dx,al	;左
	pop	ax
	neg	al	;逆相
	out	dx,al	;右

	call	add_address
	jc	trans_fin

	loop	right_trans_g_loop
	jmp	trans_exit

;------------------------------------------------------------------------------
;	Addressを進める
;		cy=1 ･･･ 転送終了
;------------------------------------------------------------------------------
add_address:
	add	cs:[addsizew],bx;bx=addsize2
	pushf
	mov	al,ah
	mov	ah,0		;ax=addsize1
	adc	bp,ax		;bpをaddsizeに従って加算
	popf
	pushf
	adc	si,ax		;addressをaddsizeに従って加算
	cmp	si,4000h	;16K Over Check (for EMS)
	jc	not_add_ofs2

;	[[[ segment over ]]]
	add	cs:[start_ofs],bp
	adc	cs:[start_ofs2],0
	xor	bp,bp		;転送サイズのreset
	call	get_data_offset

not_add_ofs2:
	popf
	sbb	di,ax		;sizeをaddsizeに従って減算
	mov	ah,al		;ah=addsize1 に戻す
	jc	addadd_sizeseg
	jz	addadd_justcheck
	ret

addadd_justcheck:
	cmp	cs:[size2],0	;ジャスト０
	jz	addadd_repchk
	ret

addadd_sizeseg:
	sub	cs:[size2],1
	jc	addadd_repchk
	ret

addadd_repchk:
	cmp	cs:[repeat_flag],0
	jz	addadd_stc_ret
	cmp	cs:[release_flag2],1
	jz	addadd_stc_ret

;	repeat設定
	push	ax
	push	dx
	mov	ax,cs:[repeat_size2]
	mov	cs:[size2],ax
	mov	di,cs:[repeat_size1]
	mov	ax,cs:[repeat_ofs2]
	mov	cs:[start_ofs2],ax
	mov	dx,cs:[repeat_ofs]
	mov	cs:[start_ofs],dx
	xor	bp,bp
	mov	ah,-3
	int	65h		;get data offset = ds:dx
	mov	si,dx		;DS:SI= DATA ADDRESS
	pop	dx
	pop	ax
	clc
	ret

addadd_stc_ret:
	stc
	ret

;------------------------------------------------------------------------------
;	新規にpcmdata offsetを得る
;------------------------------------------------------------------------------
get_data_offset:
	push	ax
	push	dx
	mov	dx,cs:[start_ofs]
	mov	ax,cs:[start_ofs2]
	mov	ah,-3
	int	65h		;get data offset = ds:dx
	mov	si,dx		;DS:SI= DATA ADDRESS
	pop	dx
	pop	ax
	ret

;------------------------------------------------------------------------------
;	転送終了･･･残りを０で埋める
;------------------------------------------------------------------------------
trans_fin:
	dec	cx
	jz	tfin_ret
	xor	al,al
tfin_loop:
	out	dx,al	;左
	out	dx,al	;右
	loop	tfin_loop
tfin_ret:
	mov	cs:[size1],cx	;cx=0
	mov	cs:[size2],cx
	ret

;------------------------------------------------------------------------------
;	0で埋める
;------------------------------------------------------------------------------
zero_trans:
	xor	al,al
ztr_loop:
	out	dx,al	;左
	out	dx,al	;右
	loop	ztr_loop
	mov	[trans_flag],0		;もう転送しないでいいよ
	ret

;==============================================================================
;	86B play PCM
;==============================================================================
play_86pcm:
	pushf
	cli

	mov	dx,0a468h
	in	al,dx
;	A468 bit7をreset	（FIFO停止）
	out	5fh,al
	and	al,07fh
	out	dx,al

;	A468 bit6をreset	（CPU->FIFO モード）
	out	5fh,al
	and	al,0bfh
	out	dx,al

;	A468 bit3をset		（FIFO リセット設定）
	out	5fh,al
	or	al,8
	out	dx,al

;	A468 bit3をreset	（FIFO リセット解除）
	out	5fh,al
	and	al,0f7h
	out	dx,al

;	A468 bit5をreset	（FIFO割り込み禁止/A46A設定準備）
	out	5fh,al
	and	al,0dfh
	out	dx,al

;	A468 bit4をreset	（割り込みフラグ消去）
	out	5fh,al
	and	al,0efh
	out	dx,al

;	A46A に PAN を OUT	（8bit L/Rch）
	mov	dx,0a46ah
	mov	al,0f2h
	out	dx,al

	popf

;	最初のdataを転送
	mov	si,offset _start_ofs
	mov	di,offset start_ofs
	mov	cx,4
rep	movsw
	mov	[addsizew],0
	mov	[release_flag2],0
	push	bp
	call	pcm_trans2
	pop	bp

	pushf
	cli
;------------------------------------------------------------------------------
;	割り込み設定
;------------------------------------------------------------------------------

	mov	dx,0a468h
	in	al,dx
;	A468 bit4をset		（割り込みフラグ消去解除）
	out	5fh,al
	or	al,10h
	out	dx,al

;	A468 bit5をset		（FIFO割り込み許可/A46A設定準備）
	out	5fh,al
	or	al,20h
	out	dx,al

;	A46AのFIFO割り込みサイズを設定
	mov	dx,0a46ah
	mov	al,+(trans_size/128)-1
	out	dx,al

;------------------------------------------------------------------------------
;	再生開始
;------------------------------------------------------------------------------
	mov	dx,0a468h
	in	al,dx
;	A468 bit7をset		（PCM 再生開始）
	out	5fh,al
	or	al,80h
	out	dx,al

	mov	[play86_flag],1
	mov	[trans_flag],1
	popf
	ret

;==============================================================================
;	86B PCM stop
;==============================================================================
stop_86pcm:
	push	ax
	push	dx
	pushf
	cli
	mov	dx,0a468h
	in	al,dx
	out	5fh,al
	and	al,07fh
	out	dx,al

;	FIFO reset
	out	5fh,al
	or	al,08h
	out	dx,al		;Reset処理
	out	5fh,al
	and	al,0f7h
	out	dx,al		;Reset処理おわり

;	FIFO 割り込み禁止
	out	5fh,al
	and	al,0dfh
	out	dx,al

;	FIFO 割り込みフラグreset
	out	5fh,al
	and	al,0efh
	out	dx,al
	out	5fh,al
	or	al,010h
	out	dx,al

	mov	cs:[play86_flag],0
	mov	cs:[trans_flag],0

	popf
	pop	dx
	pop	ax
	ret

;==============================================================================
;	ＰＣＭ効果音ルーチン
;		input	dx	fnum
;			ch	Pan
;			cl	Volume
;			al	Number
;==============================================================================
pcm_effect:
	mov	bx,offset part10
	or	partmask[bx],2	;PCM Part Mask
	mov	[pcmflag],1
	mov	[pcm_effec_num],al

	mov	[_voice_delta_n],dx
	mov	[_pcm_volume],cl
	mov	[_pcmpan],ch

	call	stop_86pcm

	cli
	mov	al,[pcm_effec_num]
	call	neiro_set
	mov	al,[_pcmpan]
	xor	ah,ah
	call	set_pcm_pan2

	mov	bx,[_voice_delta_n]
	mov	ax,bx
	mov	bl,bh
	and	bx,0111000000001111b
	shl	bh,1
	or	bl,bh
	mov	ah,al
	xor	al,al
	call	tone_set2
	mov	al,[_pcm_volume]
	call	mv_out
	sti

	call	play_86pcm

	ret

;==============================================================================
;	Datas
;==============================================================================
trans_size	equ	256	;1回の転送byte数
play86_flag	db	0	;発音中?flag
trans_flag	db	0	;転送するdataが残っているか?flag
start_ofs	dw	0	;発音中PCMデータ番地 (offset下位)
start_ofs2	dw	0	;発音中PCMデータ番地 (offset上位)
size1		dw	0	;残りサイズ (下位word)
size2		dw	0	;残りサイズ (上位word)
_start_ofs	dw	0	;発音開始PCMデータ番地 (offset下位)
_start_ofs2	dw	0	;発音開始PCMデータ番地 (offset上位)
_size1		dw	0	;PCMデータサイズ (下位word)
_size2		dw	0	;PCMデータサイズ (上位word)
addsize1	db	0	;PCMアドレス加算値 (整数部)
addsize2	dw	0	;PCMアドレス加算値 (小数点部)
addsizew	dw	0	;PCMアドレス加算値 (小数点部,転送中work)
repeat_ofs	dw	0	;リピート開始位置 (offset下位)
repeat_ofs2	dw	0	;リピート開始位置 (offset上位)
repeat_size1	dw	0	;リピート後のサイズ (下位word)
repeat_size2	dw	0	;リピート後のサイズ (上位word)
release_ofs	dw	0	;リリース開始位置 (offset下位)
release_ofs2	dw	0	;リリース開始位置 (offset上位)
release_size1	dw	0	;リリース後のサイズ (下位word)
release_size2	dw	0	;リリース後のサイズ (上位word)
repeat_flag	db	0	;リピートするかどうかのflag
release_flag1	db	0	;リリースするかどうかのflag
release_flag2	db	0	;リリースしたかどうかのflag
pcm86_pan_flag	db	0	;パンデータ１(bit0=左/bit1=右/bit2=逆)
pcm86_pan_dat	db	0	;パンデータ２(音量を下げるサイドの音量値)

;	pan_flagによる転送table
trans_table	dw	double_trans,left_trans
		dw	right_trans,double_trans
		dw	double_trans_g,left_trans_g
		dw	right_trans_g,double_trans_g

;	周波数table Include
	include	tunedata.inc
