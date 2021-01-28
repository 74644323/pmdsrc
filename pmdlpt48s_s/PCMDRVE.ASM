;==============================================================================
;	ÇoÇbÇlâπåπÅ@ââëtÅ@ÉÅÉCÉì [ PPZ8 adpcm Emulate ]
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
	cmp	[adpcm_emulate],1
	jnz	pmpm_ret
	mov	ax,0207h
	call	ppz8_call	; PPZ8 ch7 î≠âπí‚é~
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
	push	es
	or	voicenum[di],80h
	call	ppz_voicetable_calc
	and	voicenum[di],7fh
	mov	dx,es:6[bx]
	mov	bx,es:4[bx]	;dx:bx = ÉfÅ[É^ó 
	pop	es
	rept	6
	shr	dx,1
	rcr	bx,1
	endm			;/64 ... bx = adpcmÉfÅ[É^ó 

	lodsw
	test	ax,ax
	jns	prs1_set
	add	ax,bx
prs1_set:
	mov	cx,ax		;cx = loop start offset

	lodsw
	test	ax,ax
	jz	prs2_minus
	jns	prs2_set
prs2_minus:
	add	ax,bx
prs2_set:
	mov	dx,ax		;dx = loop end offset

	lodsw			;release ê›íËïsâ¬(ì«Ç›îÚÇŒÇµ)

	push	si
	push	di
	mov	si,dx
	xor	dx,dx
	mov	di,dx
	rept	5
	add	cx,cx
	adc	dx,dx		;dx:cx = start offset (PPZE)
	endm
	rept	5
	add	si,si
	adc	di,di		;di:si = end offset (PPZE)
	endm
	mov	ax,0e07h
	call	ppz8_call
	pop	di
	pop	si

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
	xor	dh,dh
	and	al,3
	mov	dl,al
	ror	al,1
	ror	al,1
	mov	fmpan[di],al

	cmp	[adpcm_emulate],1
	jz	pansetm_next
	mov	bx,dx
	mov	dl,pansetm_data[bx]
pansetm_next:

	mov	ax,1307h
	call	ppz8_call
	ret
pansetm_data	db	0,9,1,5

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

;==============================================================================
;	COMMAND '@' [NEIRO Change]
;==============================================================================
com@m:
	lodsb
	mov	voicenum[di],al

	cmp	[adpcm_emulate],1
	jz	com@m_exit
	mov	ax,1801h
	mov	[adpcm_emulate],al
	call	ppz8_call	;ADPCMEmulate ON
if	ppz
	or	voicenum[di],80h
	mov	[partb],7
	call	ppz_neiro_reset		; in ppzdrv.asm
	and	voicenum[di],7fh

	mov	bx,offset part10h	;PPZ8ch
	or	partmask[bx],10h	;Mask
	and	partmask[di],0efh	;Mask off
	jnz	com@m_exit

	pop	ax		;commandsm
	jmp	mp1m		;ÉpÅ[Égïúäà
endif
com@m_exit:
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
	xor	dh,dh
	mov	ax,0707h
	call	ppz8_call
	ret

;==============================================================================
;	PCM KEYON
;==============================================================================
keyonm:	
	cmp	onkai[di],-1
	jz	keyonm_ret	; ∑≠≥Ã … ƒ∑
;;	mov	dl,fmpan[di]
;;	rol	dl,1
;;	rol	dl,1
;;	and	dx,3
;;	mov	ax,1307h
;;	call	ppz8_call

	mov	dx,8080h
	or	dl,voicenum[di]
	mov	ax,0107h
	call	ppz8_call
keyonm_ret:
	ret

;==============================================================================
;	PCM KEYOFF
;==============================================================================
keyoffm:
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
;	PCM OTODASI
;==============================================================================
otodasim:
	mov	bx,fnum[di]
	test	bx,bx
	jz	odm_ret
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
	mov	cx,bx
	mov	ax,0b07h
	call	ppz8_call
odm_ret:
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
;	ÇoÇbÇlå¯â âπÉãÅ[É`Éì	ç°ÇÒÇ∆Ç±cut
;		input	dx	DeltaN
;			ch	Pan
;			cl	Volume
;			al	Number
;==============================================================================
pcm_effect:
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