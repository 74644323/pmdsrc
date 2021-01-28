;==============================================================================
;	ÇoÇbÇlâπåπÅ@ââëtÅ@ÉÅÉCÉì
;==============================================================================
pcmmain_ret:
	ret

pcmmain:
	mov	si,[di]		; si = PART DATA ADDRESS
	test	si,si
	jz	pcmmain_ret
	cmp	partmask[di],0
	jnz	pcmmain_nonplay

	; âπí∑ -1
	dec	leng[di]
	mov	al,leng[di]

	; KEYOFF CHECK
	test	keyoff_flag[di],3	; ä˘Ç…keyoffÇµÇΩÇ©ÅH
	jnz	mp0m
	cmp	al,qdat[di]		; Qíl => écÇËLengthíléû keyoff
	ja	mp0m
	mov	keyoff_flag[di],-1
	call	keyoffm			; ALÇÕâÛÇ≥Ç»Ç¢

mp0m:	; LENGTH CHECK
	test	al,al
	jnz	mpexitm
mp1m0:	and	lfoswi[di],0f7h		; Porta off

mp1m:	; DATA READ
	lodsb
	cmp	al,80h
	jc	mp2m
	jz	mp15m

	; ELSE COMMANDS
	call	commandsm
	jmp	mp1m

	; END OF MUSIC [ 'L' ∂ﬁ ±Ø¿ƒ∑  ø∫Õ ”ƒﬁŸ ]
mp15m:	dec	si
	mov	[di],si
	mov	loopcheck[di],3
	mov	onkai[di],-1
	mov	bx,partloop[di]
	test	bx,bx
	jz	mpexitm

	; 'L' ∂ﬁ ±Ø¿ƒ∑
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

porta_returnm:
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
	cmp	byte ptr [si],0fbh	; '&'Ç™íºå„Ç…Ç†Ç¡ÇΩÇÁkeyoffÇµÇ»Ç¢
	jnz	mnp_ret
	mov	keyoff_flag[di],2
	jmp	mnp_ret

mpexitm:	
	mov	cl,lfoswi[di]
	mov	al,cl
	and	al,8
	mov	[lfo_switch],al
	test	cl,cl
	jz	volsm
	test	cl,3
	jz	not_lfom
	call	lfo
	jnc	not_lfom
	mov	al,cl
	and	al,3
	or	[lfo_switch],al
not_lfom:
	test	cl,30h
	jz	not_lfom2
	pushf
	cli
	call	lfo_change
	call	lfo
	jnc	not_lfom1
	call	lfo_change
	popf
	mov	al,lfoswi[di]
	and	al,30h
	or	[lfo_switch],al
	jmp	not_lfom2
not_lfom1:
	call	lfo_change
	popf
not_lfom2:
	test	[lfo_switch],19h
	jz	volsm

	test	[lfo_switch],8
	jz	not_portam
	call	porta_calc
not_portam:
	call	otodasim
volsm:
	call	soft_env
	jc	volsm2
	test	[lfo_switch],22h
	jnz	volsm2
	cmp	[fadeout_speed],0
	jz	mnp_ret
volsm2:	call	volsetm
	jmp	mnp_ret

;==============================================================================
;	ÇoÇbÇlâπåπââëtÉÅÉCÉìÅFÉpÅ[ÉgÉ}ÉXÉNÇ≥ÇÍÇƒÇ¢ÇÈéû
;==============================================================================
pcmmain_nonplay:
	mov	keyoff_flag[di],-1
	dec	leng[di]
	jnz	mnp_ret

	test	partmask[di],2		;bit1(pcmå¯â âπíÜÅH)Çcheck
	jz	pcmmnp_1
	mov	dx,[fm2_port1]
	in	al,dx
	test	al,00000100b		;EOS check
	jz	pcmmnp_1		;Ç‹ÇæäÑÇËçûÇ›PCMÇ™ñ¬Ç¡ÇƒÇ¢ÇÈ
	mov	[pcmflag],0		;PCMå¯â âπèIóπ
	mov	[pcm_effec_num],255
	and	partmask[di],0fdh	;bit1Çclear
	jz	mp1m0			;partmaskÇ™0Ç»ÇÁïúäàÇ≥ÇπÇÈ

pcmmnp_1:
	lodsb
	cmp	al,80h
	jz	pcmmnp_2

	jc	fmmnp_3
	call	commandsm
	jmp	pcmmnp_1

pcmmnp_2:
	; END OF MUSIC [ "L"Ç™Ç†Ç¡ÇΩéûÇÕÇªÇ±Ç…ñﬂÇÈ ]
	dec	si
	mov	[di],si
	mov	loopcheck[di],3
	mov	onkai[di],-1
	mov	bx,partloop[di]
	test	bx,bx
	jz	fmmnp_4

	; "L"Ç™Ç†Ç¡ÇΩéû
	mov	si,bx
	mov	loopcheck[di],1
	jmp	pcmmnp_1

;==============================================================================
;	ÇoÇbÇlâπåπì¡éÍÉRÉ}ÉìÉhèàóù
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
	;ÇuÇQÅDÇRÅ@ÇdÇwÇsÇdÇmÇc
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
	dw	portam		;0DAH
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
if	ppz
	dw	ppz_extpartset	;0b4h	in ppzdrv.asm
else
	dw	jump16		;0b4h
endif
	dw	comq3		;0b3h
	dw	comshift_master	;0b2h
	dw	comq4		;0b1h

;==============================================================================
;	ââëtíÜÉpÅ[ÉgÇÃÉ}ÉXÉNon/off
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
	mov	dx,0102h	; PAN=0 / x8 bit mode
	call	opnset46
	mov	dx,0001h	; PCM RESET
	call	opnset46
pmpm_ret:
	pop	ax		;commandsm
	jmp	pcmmnp_1

pcm_part_maskoff_ret:
	and	partmask[di],0bfh
	jnz	pmpm_ret
	pop	ax		;commandsm
	jmp	mp1m		;ÉpÅ[Égïúäà

;==============================================================================
;	ÉäÉsÅ[Égê›íË
;==============================================================================
pcmrepeat_set:
	lodsw
	test	ax,ax
	js	prs1_minus
	add	ax,[pcmstart]
	jmp	prs1_set
prs1_minus:
	add	ax,[pcmstop]
prs1_set:
	mov	[pcmrepeat1],ax

	lodsw
	test	ax,ax
	jz	prs2_minus
	js	prs2_minus
	add	ax,[pcmstart]
	jmp	prs2_set
prs2_minus:
	add	ax,[pcmstop]
prs2_set:
	mov	[pcmrepeat2],ax

	lodsw
	cmp	ax,8000h
	jz	prs3_set
	jnc	prs3_minus
	add	ax,[pcmstart]
	jmp	prs3_set
prs3_minus:
	add	ax,[pcmstop]
prs3_set:
	mov	[pcmrelease],ax

	ret

;==============================================================================
;	É|ÉãÉ^ÉÅÉìÉg(PCM)
;==============================================================================
portam:
	cmp	partmask[di],0
	jnz	porta_notset

	pop	ax	;commandsp

	lodsb
	call	lfoinitp
	call	oshift
	call	fnumsetm

	mov	ax,fnum[di]
	push	ax
	mov	al,onkai[di]
	push	ax

	lodsb
	call	oshift
	call	fnumsetm
	mov	ax,fnum[di]	; ax = É|ÉãÉ^ÉÅÉìÉgêÊÇÃdelta_níl

	pop	bx
	mov	onkai[di],bl
	pop	bx		; bx = É|ÉãÉ^ÉÅÉìÉgå≥ÇÃdelta_níl
	mov	fnum[di],bx

	sub	ax,bx		; ax = delta_nç∑

	mov	bl,[si]
	inc	si
	mov	leng[di],bl
	call	calc_q

	xor	bh,bh
	cwd
	idiv	bx		; ax = delta_nç∑ / âπí∑

	mov	porta_num2[di],ax	;è§
	mov	porta_num3[di],dx	;ó]ÇË
	or	lfoswi[di],8		;Porta ON

	jmp	porta_returnm

;
;	COMMAND ']' [VOLUME UP]
;
comvolupm:
	mov	al,volume[di]	
	add	al,16
vupckm:
	jnc	vsetm
	mov	al,255
vsetm:	mov	volume[di],al
	ret

	;ÇuÇQÅDÇRÅ@ÇdÇwÇsÇdÇmÇc
comvolupm2:
	lodsb
	add	al,volume[di]
	jmp	vupckm
;
;	COMMAND '[' [VOLUME DOWN]
;
comvoldownm:
	mov	al,volume[di]
	sub	al,16
	jnc	vsetm
	xor	al,al
	jmp	vsetm
	;ÇuÇQÅDÇRÅ@ÇdÇwÇsÇdÇmÇc
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
;==============================================================================
pansetm:
	lodsb
pansetm_main:
	ror	al,1
	ror	al,1
	and	al,11000000b
	mov	fmpan[di],al
	ret

;==============================================================================
;	Pan setting Extend
;==============================================================================
pansetm_ex:
	lodsb
	inc	si	;ãtëñflagÇÕì«Ç›îÚÇŒÇ∑
	test	al,al
	jz	pmex_mid
	js	pmex_left
	mov	al,2
	jmp	pansetm_main
pmex_mid:
	mov	al,3
	jmp	pansetm_main
pmex_left:
	mov	al,1
	jmp	pansetm_main

;
;	COMMAND '@' [NEIRO Change]
;
com@m:
	lodsb
	mov	voicenum[di],al
	xor	ah,ah
	add	ax,ax
	add	ax,ax
	mov	bx,offset pcmadrs
	add	bx,ax
	mov	ax,[bx]
	inc	bx
	inc	bx
	mov	[pcmstart],ax
	mov	ax,[bx]
	mov	[pcmstop],ax
	mov	[pcmrepeat1],0
	mov	[pcmrepeat2],0
	mov	[pcmrelease],8000h
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
;	âπó downåvéZ
;------------------------------------------------------------------------------
	mov	al,[pcm_voldown]
	test	al,al
	jz	pcm_fade_calc
	neg	al
	mul	dl
	mov	dl,ah

;------------------------------------------------------------------------------
;	FadeoutåvéZ
;------------------------------------------------------------------------------
pcm_fade_calc:
	mov	al,[fadeout_volume]
	test	al,al
	jz	pcm_env_calc
	neg	al
	mul	al	;al=al^2
	mov	al,ah	;
	mul	dl
	mov	dl,ah

;------------------------------------------------------------------------------
;	ENVELOPE åvéZ
;------------------------------------------------------------------------------
pcm_env_calc:
	mov	al,dl
	test	al,al	;âπó 0?
	jz	mv_out

	cmp	envf[di],-1
	jnz	normal_mvset
;	ägí£î≈ âπó =al*(eenv_vol+1)/16
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
;	âπó LFOåvéZ
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
;	èoóÕ
;------------------------------------------------------------------------------
mv_out:	mov	dl,al
	mov	dh,0bh
	call	opnset46
	ret

;==============================================================================
;	PCM KEYON
;==============================================================================
keyonm:	
	cmp	onkai[di],-1
	jnz	keyonm_00
	ret			; ∑≠≥Ã … ƒ∑
keyonm_00:
	mov	dx,0102h	; PAN=0 / x8 bit mode
	call	opnset46
	mov	dx,0021h	; PCM RESET
	call	opnset46

	mov	bx,[pcmstart]
	mov	dh,2
	mov	dl,bl
	call	opnset46
	inc	dh
	mov	dl,bh
	call	opnset46

	mov	bx,[pcmstop]
	inc	dh
	mov	dl,bl
	call	opnset46
	inc	dh
	mov	dl,bh
	call	opnset46

	mov	ax,[pcmrepeat1]
	or	ax,[pcmrepeat2]
	jnz	pcm_repeat_keyon

	mov	dx,00a0h	;PCM PLAY(non_repeat)
	call	opnset46

	mov	dl,fmpan[di]	;PAN SET
	or	dl,2		;x8 bit mode
	mov	dh,1
	call	opnset46

	ret

pcm_repeat_keyon:
	mov	dx,00b0h	;PCM PLAY(repeat)
	call	opnset46

	mov	dl,fmpan[di]	;PAN SET
	or	dl,2		;x8 bit mode
	mov	dh,1
	call	opnset46

	mov	bx,[pcmrepeat1]	;REPEAT ADDRESS set 1
	mov	dh,2
	mov	dl,bl
	call	opnset46
	inc	dh
	mov	dl,bh
	call	opnset46

	mov	bx,[pcmrepeat2]	;REPEAT ADDRESS set 2
	inc	dh
	mov	dl,bl
	call	opnset46
	inc	dh
	mov	dl,bh
	call	opnset46

	ret

;
;	PCM KEYOFF
;
keyoffm:
	cmp	envf[di],-1
	jz	kofm1_ext
	cmp	envf[di],2
	jnz	keyoffm_main
kofm_ret:
	ret
kofm1_ext:
	cmp	eenv_count[di],4
	jz	kofm_ret

keyoffm_main:
	cmp	[pcmrelease],8000h
	jz	keyoffp

	mov	dx,0021h	; PCM RESET
	call	opnset46

	mov	bx,[pcmrelease]
	mov	dh,2
	mov	dl,bl
	call	opnset46
	inc	dh
	mov	dl,bh
	call	opnset46

	mov	bx,[pcmstop]	;Stop ADDRESS for Release
	inc	dh
	mov	dl,bl
	call	opnset46
	inc	dh
	mov	dl,bh
	call	opnset46

	mov	dx,00a0h	;PCM PLAY(non_repeat)
	call	opnset46

	jmp	keyoffp

;
;	PCM OTODASI
;
otodasim:
	mov	bx,fnum[di]
	test	bx,bx
	jnz	odm_00
	ret
odm_00:
	;
	; Portament/LFO/Detune SET
	;
	add	bx,porta_num[di]

	xor	dx,dx
	test	lfoswi[di],11h
	jz	odm_not_lfo
	test	lfoswi[di],1
	jz	odm_not_lfo1
	mov	dx,lfodat[di]
odm_not_lfo1:
	test	lfoswi[di],10h
	jz	odm_not_lfo2
	add	dx,_lfodat[di]
odm_not_lfo2:
	add	dx,dx	; PCM   LFO ∂ﬁ ∂∂ÿ∆∏≤ …√ﬁ depth ¶ 4 ﬁ≤ ΩŸ
	add	dx,dx
odm_not_lfo:
	add	dx,detune[di]
	test	dx,dx
	js	odm_minus
	add	bx,dx
	jnc	odm_main
	mov	bx,-1
	jmp	odm_main
odm_minus:
	add	bx,dx
	jc	odm_main
	xor	bx,bx
odm_main:
	;
	; TONE SET
	;
	mov	dh,9
	mov	dl,bl
	pushf
	cli
	call	opnset46
	inc	dh
	mov	dl,bh
	call	opnset46
	popf
	ret
;
;	PCM FNUM SET
;
fnumsetm:
	mov	ah,al
	and	ah,0fh
	cmp	ah,0fh
	jz	fnrest		; ãxïÑÇÃèÍçá
	mov	onkai[di],al

	xor	bh,bh
	mov	bl,ah		; bx=onkai
	ror	al,1
	ror	al,1
	ror	al,1
	ror	al,1
	and	al,0fh
	mov	cl,al		; cl=octarb
	mov	ch,al

	mov	al,5
	sub	al,cl
	jnc	fnm00
	xor	al,al
fnm00:	mov	cl,al		; cl=5-octarb

	add	bx,bx
	mov	ax,pcm_tune_data[bx]

	cmp	ch,6		;o7à»è„?
	jc	pts01m
	mov	ch,50h
	or	ax,ax
	js	pts00m
	add	ax,ax		;o7à»è„Ç≈2î{Ç≈Ç´ÇÈèÍçáÇÕ2î{
	mov	ch,60h
pts00m:	and	onkai[di],0fh
	or	onkai[di],ch	; onkaiílèCê≥
	jmp	fnm01

pts01m:	shr	ax,cl		; ax=ax/[2^OCTARB]

fnm01:	mov	fnum[di],ax

	ret

;==============================================================================
;	ÇoÇbÇlå¯â âπÉãÅ[É`Éì
;		input	dx	DeltaN
;			ch	Pan
;			cl	Volume
;			al	Number
;==============================================================================
pcm_effect:
	cmp	[pcm_gs_flag],1
	jz	not_play_pcmeff

	mov	bx,offset part10
	or	partmask[bx],2	;PCM Part Mask
	mov	[pcmflag],1
	mov	[pcm_effec_num],al

	mov	[_voice_delta_n],dx
	mov	[_pcm_volume],cl
	mov	[_pcmpan],ch

	call	neiro_set
	mov	al,[_pcm_volume]
	call	volume_set
	mov	bx,[_voice_delta_n]
	call	tone_set
	call	pcm_keyon
not_play_pcmeff:
	ret

;==============================================================================
;	ÇoÇbÇlÇÃâπêFê›íË
;==============================================================================
neiro_set:
	xor	ah,ah
	add	ax,ax
	add	ax,ax
	add	ax,offset pcmadrs
	mov	si,ax
	lodsw
	mov	[_pcmstart],ax
	lodsw
	mov	[_pcmstop],ax
	ret	

;==============================================================================
;	ÇoÇbÇlÇÃâπó Çê›íËÇ∑ÇÈ
;		INPUT.Acc
;==============================================================================
volume_set:
	mov	dl,al
	mov	dh,0bh
	call	opnset46
	ret

;==============================================================================
;	ÇoÇbÇlÇÃâπíˆÇê›íËÇ∑ÇÈ
;		INPUT.bx
;==============================================================================
tone_set:
	mov	dh,9
	mov	dl,bl
	call	opnset46
	inc	dh
	mov	dl,bh
	call	opnset46
	ret

;==============================================================================
;	ÇoÇbÇlÇÃÉLÅ[ÉIÉì
;==============================================================================
pcm_keyon:
	mov	dx,0102h	;x8 bit mode
	call	opnset46
	mov	dx,0021h	;PCM RESET
	call	opnset46

	mov	bx,[_pcmstart]
	mov	dh,2
	mov	dl,bl
	call	opnset46
	inc	dh
	mov	dl,bh
	call	opnset46

	mov	bx,[_pcmstop]
	inc	dh
	mov	dl,bl
	call	opnset46
	inc	dh
	mov	dl,bh
	call	opnset46

	mov	dx,00a0h	;PCM PLAY
	call	opnset46

	mov	dl,[_pcmpan]	;PAN SET
	and	dl,3
	ror	dl,1
	ror	dl,1
	or	dl,2		;x8 bit mode
	mov	dh,1
	call	opnset46

	mov	dx,1080h	; EOS Çclear
	call	opnset46
	mov	dx,1018h	; EOS/TA/TBÇÃÇ›bitïœâªÇ†ÇË
	call	opnset46

	ret

;==============================================================================
;	Datas
;==============================================================================
pcm_tune_data	label	word
	dw	3132h*2	;C
	dw	3420h*2	;C+
	dw	373ah*2	;D
	dw	3a83h*2	;D+
	dw	3dfeh*2	;E
	dw	41afh*2	;F
	dw	4597h*2	;F+
	dw	49bbh*2	;G
	dw	4e1eh*2	;G+
	dw	52c4h*2	;A
	dw	57b1h*2	;A+
	dw	5ce8h*2	;B

