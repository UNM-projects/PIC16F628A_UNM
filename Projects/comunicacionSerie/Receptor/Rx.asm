;********************************************************************
;Author:	Clos, Ana María     
;Date:		
;Version:	v1.0
;
;This program is free software: you can redistribute it and/or modify
;it under the terms of the GNU General Public License as published by
;the Free Software Foundation, either version 3 of the License, or
;(at your option) any later version.
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;*********************************************************************   


    list p=16F628A
    #include P16F628A.inc
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON &_INTOSC_OSC_NOCLKOUT & _MCLRE_ON & _LVP_OFF


    palabra     equ 0x20
    cont_p  	equ	0x21
    veces       equ 0x22
    w_aux       equ 0x23
    cont        equ 0x24
    flag        equ 0x25
    rcsta_aux   equ 0x26
    pos         equ 0x27

    org     0x00
    goto    inicio
    org     0x04
    goto    interrupcion
    org     0x05

ASCII7SEG:	            ; retlw b'gfedcba'  para display catodo comun
            		    
	addwf	PCL,1		; Se incrementa el contador del programa.-
	retlw	b'00111111'	; 0
	retlw	b'00000110'	; 1
	retlw	b'01011011'	; 2
	retlw	b'01001111'	; 3
	retlw	b'01100110'	; 4
	retlw	b'01101101'	; 5
	retlw	b'01111101'	; 6
	retlw	b'00000111'	; 7
	retlw	b'01111111'	; 8
	retlw	b'01101111'	; 9
    retlw   b'01110111' ; A
    retlw   b'01111100' ; B
    retlw   b'00111001' ; C
    retlw   b'01011110' ; D
    retlw   b'01111001' ; E
    retlw   b'01110001' ; F
    return

inicio

    movlw 0x30
    movwf pos           ; Posicion en la memoria para guardar
    clrf cont
    clrf flag
    movlw b'00100000'
    movwf PORTA
    movlw b'00000110'
    movwf PORTB
    movlw	b'00110001'	; Se selecciona TMR1, preescaler de 1/8, modo temporizador.-
	movwf	T1CON       ; Banco 0   
    bsf STATUS, RP0     ; Banco 1
    movlw b'00100000'
    movwf TRISA
    movlw b'00000110'
    movwf TRISB
;******************************************
; Configuracion de baudios
;******************************************
    movlw 0x25          ; 9600 baudios 4Mz
    movwf SPBRG         ; Banco 1
    bsf TXSTA, BRGH     ; Banco 1
;******************************************
; Habilitar puerto serie en modo sincronico
;******************************************
    bcf TXSTA, SYNC     ; Banco 1
    bcf STATUS, RP0;
    bsf RCSTA, SPEN     ; Banco 0
;******************************************
; Habilitar interrupciones
;******************************************
    bsf INTCON, GIE
    bsf	INTCON,PEIE
    bsf STATUS, RP0 ; Cambia banco 1
    bsf PIE1, TXIE  ; Banco 1
    bsf PIE1, RCIE  ; Banco 1
;******************************************
; Habilitar 9no bit
;******************************************
    ;bsf TXSTA, TX9 ; Banco 1
    bcf STATUS, RP0 ; Cambia Banco 0
    bsf RCSTA, RX9
;******************************************
; Habilitar recepcion
;******************************************
    bsf RCSTA, CREN

espera

    nop
    goto espera

calc_paridad

    bcf STATUS, RP0; Banco 0
    movlw 0x08
    movwf veces
    clrf cont_p
    bcf STATUS, C

ciclo

    rrf palabra,1
    btfsc STATUS, C
    incf cont_p
    decfsz veces
    goto ciclo
    rrf palabra,1
    return

interrupcion

    bcf STATUS, RP0 ; Banco 0
    btfsc PIR1,TMR1IF	
	goto timer_1
    btfsc PIR1, RCIF
    bsf STATUS, RP0 ; Banco 1
    btfsc PIE1,RCIE
    goto recibir
    bcf STATUS, RP0 ; Banco 0
    btfsc PIR1, TXIF
    bsf STATUS, RP0 ; Banco 1
    btfsc PIE1, TXIE
    goto enviar
    retfie
;******************************************
; Recibir 
;******************************************
    bcf STATUS, RP0 ; Banco 0
    movfw RCREG
    movwf palabra
    movfw RCSTA     ; Banco 0 carga 9no bit en w
    movwf rcsta_aux
    call ver_oerr
    call calc_paridad
    call guardar
    bcf STATUS, RP0 ; Banco 0    
    rrf rcsta_aux,1 ; El resultado queda en el registro, el 9no bit en c
    btfsc STATUS, C
    incf cont_p,1   ; Calcula el sindrome de error
    movlw 0x01;
    rrf cont_p,1    ; El bit de paridad queda en c
    btfsc STATUS, C
    movwf flag
    movfw palabra
    sublw 0x17      ; Si recibe 0x17 y no hubo error termina transmision
    btfsc STATUS,Z
    goto ver_flag
    retfie

ver_oerr

    btfss rcsta_aux,1
    retfie
    bcf RCSTA, CREN
    bsf RCSTA, CREN
    retfie

guardar

    bcf STATUS, RP0 ; Banco 0
    movfw cont
    sublw 0x40
    btfsc STATUS,Z
    clrf cont
    movfw pos
    addwf cont,0    ; Guarda en w
    movwf FSR
    movfw palabra
    movwf INDF
    incf cont
    return

ver_flag

    bcf STATUS, RP0 ; Banco 0
    btfss flag,0
    goto sin_error
    clrf cont
    clrf flag
    retfie

sin_error

    bcf STATUS, RP0 ; Banco 0
    bcf RCSTA, CREN ; Banco 0
    clrf cont
    movlw	0x0B
	movwf	TMR1H	; Banco 0
	movlw	0xDC
	movwf	TMR1L   ; Banco 0
    movlw 0x02
    movwf cont_p
    movfw w_aux
    bsf	STATUS,RP0
	bsf	 PIE1,TMR1IE ; BANCO 1
    retfie

timer_1

    bcf STATUS, RP0 ; Banco 0
    decfsz	cont_p,1
    goto actualizar_t1

mostrar

    bcf STATUS, RP0 ; Banco 0
    movlw	0x02			
	movwf	cont_p
    movfw pos
    addwf cont,0
    movwf FSR
    movfw INDF
    movwf w_aux
    sublw 0x17
    btfsc STATUS, Z
    goto fin_mostrar
    movfw w_aux
    sublw 0x0F
    btfss STATUS,C
    goto mostrar_error
    movfw w_aux

mostrar_ascii

    call ASCII7SEG
    movwf PORTA
    movwf PORTB
    incf cont

actualizar_t1

    bcf	STATUS,RP0	; Banco 0
    movlw	0x0B
	movwf	TMR1H		
	movlw	0xDC
	movwf	TMR1L
    bcf	PIR1,TMR1IF ; Banco 0
    retfie

fin_mostrar

    bsf STATUS, RP0;
    bcf	 PIE1,TMR1IE; Banco 1
    bsf TXSTA, TXEN ; Banco 1
    bcf STATUS, RP0
    movlw 0x03
    movwf veces

enviar

    bcf STATUS, RP0
    movlw 0x13
    movwf TXREG     ; Banco 0
    decfsz veces    ; Esto es nuevo
    retfie

fin_tx

    bsf STATUS, RP0 ;
    bcf TXSTA, TXEN ; Banco 1
    retfie
mostrar_error

    movlw 0x0E
    goto mostrar_ascii
    end
