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

    list		p=16f628A	
	#include	<p16f628A.inc>	
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _INTOSC_OSC_NOCLKOUT & _LVP_OFF & _MCLRE_ON



    palabra     equ 0x20
    cont_p  	equ	0x21
    veces       equ 0x22
    cont        equ 0x23


    org         0x00
    goto        inicio
    org         0x04
    goto        interrupcion
    org         0x05


FRASE:

	addwf	PCL,1	; Se incrementa el contador del programa.-
	retlw	0x01
	retlw	0x06
	retlw	0x0F
	retlw	0x06
	retlw	0x02
	retlw	0x08
	retlw	0x0A
    retlw   0x17    ; etb end of transmision block
    clrf	cont	; se resetea contador
	retlw	0x01
	return

inicio

    clrf cont
    movlw b'00100000'
    movwf PORTA
    movlw b'00000110'
    movwf PORTB
    bsf STATUS, RP0 ; Banco 1
    movlw b'00100000'
    movwf TRISA
    movlw b'00000110'
    movwf TRISB
;*******************************************
; Configuracion de baudios
;*******************************************
    movlw 0x25      ;9600 baudios 4Mz
    movwf SPBRG
    bsf TXSTA, BRGH
;*******************************************
; Habilitar puerto serie en modo sincronico
;*******************************************
    bcf TXSTA, SYNC
    bcf STATUS, RP0 ; Banco 0
    bsf RCSTA, SPEN
    bsf STATUS, RP0 ; Banco 1
;*******************************************
; Habilitar interrupciones
;*******************************************
    bsf INTCON, GIE
    bsf	INTCON,PEIE
    bsf PIE1, TXIE
    bsf PIE1, RCIE
;*******************************************
; Habilitar 9no bit
;*******************************************
    bsf TXSTA, TX9
    bcf STATUS, RP0; Banco 0
    bsf RCSTA, RX9
;*******************************************
; Habilitar recepcion y transmision
;*******************************************
    bcf STATUS, RP0; Banco 0
    bsf RCSTA, CREN
    bsf STATUS, RP0; Banco 1
    bsf TXSTA, TXEN

espera

    nop
    goto espera

calc_paridad

    bcf STATUS, RP0; Banco 0
    movwf palabra
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
    rrf palabra,1   ; Queda como al principio
    movfw palabra
    return

interrupcion

    bcf STATUS, RP0 ; Banco 0
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

enviar

    bcf STATUS, RP0 ; BANCO 0
    movfw cont
    call FRASE
    call calc_paridad
    incf cont,1     ; Deja el contenido en cont
    rrf cont_p,1
    bsf STATUS, RP0 ; Banco 1
    bcf TXSTA,TX9D
    btfsc STATUS,C
    bsf TXSTA,TX9D
    bcf STATUS, RP0 ; Banco 0
    movwf TXREG
    retfie

recibir

    bcf STATUS, RP0 ; Banco 0
    movfw RCREG
    sublw 0x13
    btfsc STATUS, Z
    goto fin_tx
    retfie

fin_tx

    bsf STATUS, RP0 ; Banco 1
    bcf TXSTA, TXEN
    bcf STATUS, RP0 ; Banco 0
    movlw 0x02
    movwf PORTA
    retfie
    end
