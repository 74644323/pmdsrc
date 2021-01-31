;==============================================================================
;	�E�C���X����CHECK Include���[�`��
;==============================================================================
;
;		��/�K�� .COM�t�@�C�������ɗ���悤�ɂ��邱�ƁB
;
;		��/	:
;			org	100h
;		start:	[[ �����ݒ蓙 ]]
;
;			call	viruschk
;			jnc	main
;
;			[[ �E�C���X�ɐN����Ă����ꍇ�A���l�[�������
;			   �����ꍇ�̏��� ]]
;
;		main:	[[ ���C���v���O���� ]]
;
;			[[ �f�[�^(�����l����) ]]<- db "message$" ��
;
;			include viruschk.inc
;
;			[[ �f�[�^(�����l�Ȃ�) ]]<- db ? ��
;
;		end	start
;
;		LINK���Dump���Ŋm�F���āA������"M.Kajihara(KAJA)"�Ƃ���
;		�����񂪂����OK�ł��B
;
;		���� /	���x�� "myname" �Ɏ�����file��(8+3�����A�󂫂�space)
;			��db��`���Ă���
;
;		���s /	call	viruschk (�O���Q�ƂɂȂ�̂Œ���)
;
;		�o�� /	cy=0	ax=0	���v�������ꍇ
;			cy=1	ax=1	�N����Ă���Ǝv����ꍇ
;			cy=1	ax=2	���l�[������Ă���Ǝv����ꍇ
;
;		�j�� /	ds,es,ax,bx,cx,dx,si,di,flags
;
;==============================================================================
;myname		db	"PMD     COM"	<-������File�������̂悤�ɒ�`���Ă���

viruschk:
	mov	ax,1600h
	int	2fh
	test	al,7fh		;Windows���̏ꍇ
	jz	vc_not_windows	;VirusCheck�����Ȃ�
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
	mov	cx,20h		;dos 3.x�` inFCB.filename
	mov	dx,11h		;dos 3.x�` inFCB.filesize
	cmp	al,3
	jz	set_FCBsize

	mov	bx,3bh		;dos 4.x�` inFCB.size
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
;	Filename�������I��
;==============================================================================
	mov	ax,0002h	;Rename����Ă���ꍇ
	stc
	ret

;==============================================================================
;	Filename����
;==============================================================================
found_size:
	mov	si,[inFCB_filesize]
	mov	ax,es:[si+bx]		;size low
	mov	dx,es:2[si+bx]		;size high

	add	ax,100h-16
	adc	dx,0
	jnz	virus_found		;�T�C�Y��65535��over���Ă���

	mov	dx,cs
	mov	es,dx
	mov	si,offset chk_message
	mov	di,ax
	mov	cx,16
rep	cmpsb
	jnz	virus_found

	xor	ax,ax		;���v������
	ret

;==============================================================================
;	�E�C���X�̋^�������鎞
;==============================================================================
virus_found:
	mov	ax,0001h	;�N����Ă���
	stc
	ret

;==============================================================================
;	FCB���玩���̃t�@�C�������T�[�`
;		in.	es:bx	= inner FCB address
;			cx	= FCB�̌�
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