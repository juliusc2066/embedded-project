; *********************************************************** ;
;                           BLINKY                            ;
;       make a LED blink at a given frequency using Timer1    ;
;                                                             ;
;       INFO0064 - Embedded Systems - Lab 1                   ;
;                                                             ;
; *********************************************************** ;
    
    
    processor 16f1789
    #include 	"config.inc"
    #define	minute_reference    0xF0    ; F0 = 240 -> 1 minute at 4Hz
    #define	store_reference	    0x1E    ; 30 minutes
    #define	measure_reference   0x05    ; 5 minutes

    PSECT text, abs, class=CODE, delta=2
    
; That is where the MCU will start executing the program (0x00)
    org	    00h
    goto    start		    ; jump to the beginning of the code

    org	    04h
    nop
    goto    interrupt_routine

;BEGINNING OF THE PROGRAM
start:
    call    initialisation      ; initialisation routine configuring the MCU
    goto    main_loop           ; main loop

;INTERRUPT ROUTINE
interrupt_routine:
    
    movlb   0x07
    btfsc   IOCCF, 0    ;rising edge detected on RC0
	goto interrupt_anemometer
    btfsc   IOCCF, 1    ;rising edge detected on RC1
	goto interrupt_pluviometer
    movlb   0x00
    btfsc   PIR1, 0     ;timer1 overflow
	goto interrupt_timer1
    btfsc   PIR1, 6     ;adc conversion completed
	goto interrupt_adc
    retfie    
    
;INTERRUPT ANEMOMETER
interrupt_anemometer:   
    
    bcf     IOCCF, 0
    movlb   0x02
    btfsc   LATD,  2
	goto red_light_off
    goto red_light_on
    
;INTERRUPT PLUVIOMETER
interrupt_pluviometer:
    
    bcf     IOCCF, 1
    movlb   0x02
    btfsc   LATD,  3
	goto green_light_off
    goto green_light_on
    
;INTERRUPT TIMER
interrupt_timer1:
    
    movlb   0x00
    movlw   11101101B
    movwf   TMR1L
    movlw   10000101B
    movwf   TMR1H
    bcf     PIR1, 0     ;clear timer1 flag
    decf    minute_counter, 1
    btfsc   STATUS, 2
	    goto	minute_elapsed
    retfie
    
minute_elapsed:
    
    ;movlb   0x01	;4 lines to launch adc conversion
    ;movlw   00001001B
    ;movwf   ADCON0  
    ;bsf     ADCON0, 1
    movlb   0x00
    movlw   minute_reference
    movwf   minute_counter
    ;movlb   0x02        ;4 lines to test minute timer functionality
    ;btfsc   LATD,  2
	;goto red_light_off
    ;goto red_light_on
    
    ;decf    measure_counter, 1
    retfie

interrupt_adc:
    
    movlb   0x00
    bcf     PIR1, 6
    ;movlb   0x01
    ;btfsc   ADRESH, 7
	;goto light_on
	
interrupt_end:
    retfie
 
red_light_on:
    movlb   0x02
    bsf	    LATD, 2
    goto    interrupt_end
    
red_light_off:
    movlb   0x02
    bcf	    LATD, 2
    goto    interrupt_end
    
green_light_on:
    movlb   0x02
    bsf	    LATD, 3
    goto    interrupt_end
    
green_light_off:
    movlb   0x02
    bcf	    LATD, 3
    goto    interrupt_end
    
	
;INITIALISATION
initialisation:
    ; configure clock
    ;configuration of the GPIO
    movlb   01h
    clrf    TRISD               ; All pins of PORTD are output
    movlw   00000011B
    movwf   TRISC
    movlw   00000100B
    movwf   TRISA
    movlb   02h
    clrf    LATD                ; RD0 = 0 while RD1..7 = 0;
    
    movlb   03h
    clrf    ANSELD		; All pins of PORTD are in digital mode
    clrf    ANSELC		; All pins of PORTC are in digital mode
    BSF     ANSELA, 2		; Pin 2 of PORTA is in analog mode
    
    movlb   03h
    bcf     WPUA, 2             ; Disable weak pull-up for pin 2 of PORTA

    ;configuration of clock - ? frequency - ? source
    movlb   0x01
    movlw   01101110B
    movwf   OSCCON		    ; configure oscillator (cf datasheet SFR OSCCON)
    movlw   00000000B	    
    movwf   OSCTUNE		    ; configure oscillator (cf datasheet SFR OSCTUNE)
    
    ;configuration of ADC
    movlw   01000000B
    movwf   ADCON1
    
    ; Timer1
    movlb   0x00
    movlw   00110000B
    movwf   T1CON               ; configure Timer1 (125 kHz pulses)
    
    
    ; Clear Timer1 interrupt registers
    clrf    TMR1L		    ; clear TMR1F before interrupts enabling
    clrf    TMR1H		    ; clear TMR1H before interrupts enabling
    clrf    PIR1		    ; clear PIR1 before interrupts enabling
    ; Enable interrupts
    movlb   0x01
    movlw   01000001B
    movwf   PIE1
    movlb   0x00
    bsf	    INTCON,	7			; enable global interrupts
    bsf	    INTCON,	6			; enable peripheral interrupts
    bsf     INTCON,     3			; enable on-change interrupts
    ; Set on-change interrupts for RC0 and RC1
    movlb   0x07
    movlw   00000011B
    movwf   IOCCP
    movlw   00000011B
    movwf   INLVLC
    ; Start Timer 1 for 200ms period -> 5Hz
    movlb   0x00
    movlw   11101101B
    movwf   TMR1L
    movlw   10000101B
    movwf   TMR1H
    bsf	    T1CON, 0
    
    ; declare counter variables
    minute_counter  EQU 20h
    store_counter   EQU 21h
    measure_counter EQU 22h
 
    ; store initial counter values
    movlw   minute_reference
    movwf   minute_counter
    movlw   store_reference
    movwf   store_counter
    movlw   measure_reference
    movwf   measure_counter
    
    return

;MAIN LOOP
main_loop:
    nop
    goto    main_loop