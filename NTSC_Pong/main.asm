;-------------------------------------------------------------------------------m
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430g2553.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
            .global RESET                   ; that have references to current
                                            ; section
;-------------------------------------------------------------------------------

RESET       mov.w   #0x0400,SP                  ; Initialize stackpointer

StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL      ; Stop WDT

SetupDCO      clr.b  &DCOCTL                                 ; set DCO to operate at 16MHz
                     mov.b &CALBC1_16MHZ,&BCSCTL1            ; Set range
                     mov.b &CALDCO_16MHZ,&DCOCTL             ; Set DCO step + modulation

SetupTA1      mov.w  #CCIE, &TA1CCTL0                          ; enable timer interrupt
                     mov.w  #1016,&TA1CCR0                    ; inilize compare value to 1 line period
                     mov.w  #TASSEL_2+MC_0, &TA1CTL            ; setup to use SMCLK; up mode

SetupTA0      mov.w  #CCIE, &TA0CCTL0                          ; enable timer interrupt
                     mov.w  #1016,&TA0CCR0                    ; inilize compare value to 1 line period
                     mov.w  #TASSEL_2+MC_0, &TA0CTL            ; setup to use SMCLK; up mode

                                                              ; setup USCI for SPI mode
SetupUSCI     bis.b  #UCSWRST,&UCB0CTL1                       ; Disable USCI
                     bis.b  #BIT7,&P1SEL                      ; configure P1.7 As USCIB0_SIMO (Master Output)
                     bis.b  #BIT7,&P1SEL2                     ;

                     bis.b  #UCSYNC+UCMST,&UCB0CTL0           ; Master Mode, 3 pin SPI, 8 bit, LSB 1st, Syncronous
                     bis.b  #UCSSEL_2,&UCB0CTL1               ; SMCLK as input to Bit Clock
                     mov.b  #4,&UCB0BR0                              ; Low Byte Bit Clock Divisor
                     mov.b  #0,&UCB0BR1                              ; Hi Byte Bit Clock Divisor: Bit Clock = SMCLK/(UCB0BR0 + UCB0BR1*256) = 4MHz
                     bic.b  #UCSWRST,&UCB0CTL1                ; Enable USCI
                     bis.b	#UCMSB,&UCB0CTL0				  ; MSB transmit mode


SetupPort1    bic.b  #BIT4+BIT1+BIT2+BIT3, &P2DIR             ; 2.1 - 2.4 Input
			  bis.b  #BIT7+BIT6, &P1DIR 					  ; 1.7 and 6 for Output
                     bic.b  #BIT6, &P1OUT                ; Turn LED OFF

SetupPort2    bis.b  #BIT7+BIT6+BIT5+BIT0, &P2DIR ; Set P2.7, .6, .5,& .0 as Output. P2.1, .2, .3, & .4 as Input. P2.0 only output used.
                     bis.b  #BIT0, &P2OUT                     ; Turn P2.0 ON
                     bic.b  #BIT5, &P2OUT                     ; Turn P2.5 Off

SetupPortREN  bis.b  #BIT4+BIT1+BIT2+BIT3, &P2REN            ; 2.1 - 2.4 Input (resistor enable because of the blasted noise)



; 2.0 on = 0.4
; 2.5 + 2.0 on 1.4



;-------------------------------------------------------------------------------
                                            ; Main loop here
;-------------------------------------------------------------------------------

; Code Goes Here

; Paddle Height is 28



CurrentLine .EQU R4
PaddleLeft_Y .EQU R5
PaddleRight_Y .EQU R6
Ball_X .EQU R7
Ball_Y .EQU R8
BallVelocity_X .EQU R9
BallVelocity_Y .EQU R10
JumpTimer .EQU R11
BKTimer .EQU R12
LineBufferAddr .EQU R13
Unused4 .EQU R15
GameReg	.EQU R14
BallSpeed .EQU 2

; Set up scoreboard
					mov.w	#ScoreBoard, GameReg
					mov.b	#0x00, 0(GameReg)
					mov.b	#0x01, 1(GameReg)
					mov.b	#0x00, 2(GameReg)
					mov.b	#0x80, 3(GameReg)
					mov.b	#0x00, 4(GameReg)
					mov.b	#0x00, 5(GameReg)
					mov.b	#0x00, 6(GameReg)
					mov.b	#0x00, 7(GameReg)
					mov.b	#0x00, 8(GameReg)
					mov.b	#0x00, 9(GameReg)
					mov.b	#0x00, 10(GameReg)
					mov.b	#0x00, 11(GameReg)
					mov.b	#0x00, 12(GameReg)
					mov.b	#0x00, 13(GameReg)
					mov.b	#0x00, 14(GameReg)
					mov.b	#0x00, 15(GameReg)
					mov.b	#0x00, 16(GameReg)
					mov.b	#0x01, 17(GameReg)
					mov.b	#0x00, 18(GameReg)
					mov.b	#0x80, 19(GameReg)


					 mov.w #83, JumpTimer
TimerInit
                     mov.w  #TASSEL_2+MC_1,&TA1CTL ;Start Timer A (5, 5)
TimerInitJmp		 dec.w JumpTimer
					 jnz TimerInitJmp	; (58*3)+5 = 179
					 nop ;180
					 nop ;181
					 mov.w  #TASSEL_2+MC_1,&TA0CTL ;Start Timer B
					 bic.w  #BIT4,&TA0CCTL0                          ; disable timer interrupt





			;Initalize all the posistions of the paddles and stuff

			mov.w	#120, PaddleLeft_Y					;
			mov.w	#120, PaddleRight_Y					; They're about halfway down the playfield
			mov.w	#86, Ball_X							; The ball is halfway (+/- a pixel or two somewhere like that) in the screen
			mov.w	#42+5, Ball_Y						; The ball is on the 5th line from the top
			mov.w	#-1, BallVelocity_X					; The ball starts moving left
			mov.w	#1,  BallVelocity_Y					; and down
			mov.w	#LineBuffer, LineBufferAddr
			mov.w	#LineBuffer+20, R15
IntLoop:	mov.w	#0, 0(LineBufferAddr)
			add.w	#2, LineBufferAddr
			cmp.w	R15, LineBufferAddr
			jl		IntLoop

			mov.w 	#0, CurrentLine
			bis.b	#GIE+CPUOFF,SR
CPU_OFF:
			jmp CPU_OFF
			nop



TIMERRESET:									; Come in with (6) cycles from interrupt
		    bic.b  	#BIT0,&P2OUT            ; Turn P2.0 OFF (4, 4)
			cmp.w	#1,CurrentLine			; (1, 5)
			jl		BlankGameCalc			; (2, 7)
			cmp.w	#3,CurrentLine			; (2, 9)
			jl		Blank					; (2, 11)
			cmp.w 	#6,CurrentLine			; (2, 13)
			jl 		VSyncStart				; (2, 15)
			cmp.w   #40,CurrentLine			; (2, 17)
			jl		Blank2					; (2, 19)
			cmp.w	#230, CurrentLine		; (2, 21)
			jl		VisibleArea				; (2, 23)
			cmp.w	#262, CurrentLine		; (2, 25)
			jl		Blank3					; (2, 27)

			; --

			mov.w 	#15,JumpTimer		; (2, 29)
ISRJump:	dec.w	JumpTimer			;
			jnz		ISRJump				; 3*15 + 29 = 74
			nop
			nop
		    bis.b  	#BIT0,&P2OUT        ; Turn P2.0 ON
			mov.w	#0, CurrentLine
			reti

			; --

BlankGameCalc:				        	; LINE 1 of the VSYNC will have the Game Calcluations
										; (Come in with 7 cycles)
			mov.w 	#22,JumpTimer		; (2, 9)
GameJMP:	dec.w	JumpTimer			;
			jnz		GameJMP				; 3*22 + 9 = 75
			nop							; 76 cycles
		    bis.b  	#BIT0,&P2OUT        ; Turn P2.0 ON

			; 1.0 is up   p1
			; 1.1 is down p1
			; 1.2 is up   p2
			; 1.3 is down p2
			;PaddleLeft_Y
			;PaddleRight_Y
			;Ball_X				This is what you will be manipulating
			;Ball_Y
			;BallVelocity_X
			;BallVelocity_Y

			; LINE BOUNDARIES QUICK REF GUIDE---  Line 232 is the bottom / Line 42 is the the top
			;										YOU HAVE 190 LINES TO DO STUFF WITH
			;										NOW GET TO WORK AND FINISH THIS BEFORE
			;										THE DEADLINE YOU SLACKER

			;		Oh yeah, forgot horiziontal boundaries
			;		These are values for the top left pixel of the ball
			;		Ball_X = 8 Ball Is half in the left goal, half out (Basically a point, but this won't be shown)
			;		'    ' = 9 Confirmed to be resting on the left goal
			;		'	 ' = 164 is resting on right goal line (165 will be a point but not shown)
			;		LASTLY THE BALL_Y IS THE SAME VALUES AS BEFORE,
			;									42 IS TOP 232 IS BOTTOM (but to rest on the bt. it's 232-4 (ball height)


			; AND IN CASE YOU FORGOT, THE PADDLE HEIGHT IS 28
			; Ball height is 4 width is 2


			; 		GET CRACKIN!

			bic.w   #BIT4,&TA0CCTL0                          ; disable timer interrupt

P1Up:		bit.w	#BIT1, &P2IN
			jnz		P1Down
			decd.w	PaddleLeft_Y

P1Down:		bit.w	#BIT2, &P2IN
			jnz		P2Up
			incd.w	PaddleLeft_Y

P2Up:		bit.w	#BIT3, &P2IN
			jnz		P2Down
			decd.w	PaddleRight_Y

P2Down:		bit.w	#BIT4, &P2IN
			jnz		PaddleLeftTop
			incd.w	PaddleRight_Y

PaddleLeftTop:		cmp.w	#42, PaddleLeft_Y
					jge 	PaddleLeftBottom
					mov.w	#42, PaddleLeft_Y

PaddleLeftBottom: 	cmp.w	#233-28, PaddleLeft_Y
					jl 	PaddleRightTop
					mov.w	#232-28, PaddleLeft_Y

PaddleRightTop:		cmp.w	#42, PaddleRight_Y
					jge 	PaddleRightBottom
					mov.w	#42, PaddleRight_Y

PaddleRightBottom: 	cmp.w	#233-28, PaddleRight_Y
					jl 		BallMovement
					mov.w	#232-28, PaddleRight_Y

BallMovement:		add.w	BallVelocity_X, Ball_X
					add.w	BallVelocity_Y, Ball_Y

BallBounce:			cmp.w	#42, Ball_Y
					jge		BallBounce2
					mov.w	#BallSpeed, BallVelocity_Y
					mov.w	#42, Ball_Y
BallBounce2:		cmp.w	#233-4, Ball_Y
					jl		BallPoint
					mov.w	#-BallSpeed, BallVelocity_Y
					mov.w	#233-4, Ball_Y

BallPoint:			cmp.w	#9, Ball_X
					jge		BallPoint2
					mov.w	#86, Ball_X
					sub.w	#53, Ball_Y
					mov.w	#-1, BallVelocity_X
					mov.w	#1, BallVelocity_Y
					;Player Two Score Increase Start-----------------------------------------------------
					mov.w	#ScoreBoard, JumpTimer
					mov.b	18(JumpTimer), GameReg
					inv.b	GameReg
					rla.b	GameReg
					inv.b	GameReg
					mov.b	GameReg, 18(JumpTimer)
					cmp.b	#0xFF, GameReg
					jnz		BallPoint2
					mov.w	#0, BallVelocity_X
					mov.w	#0, BallVelocity_Y
					;Player Two Score Increase End-------------------------------------------------------
BallPoint2:			cmp.w	#164, Ball_X
					jl		PaddleLeftHit
					mov.w	#86, Ball_X
					sub.w	#53, Ball_Y
					mov.w	#1, BallVelocity_X
					mov.w	#1, BallVelocity_Y

					;P1 Score INcrease start ------------------------------------------------------------

					mov.w	#ScoreBoard, JumpTimer
					mov.b	2(JumpTimer), GameReg
					inv.b	GameReg
					rla.b	GameReg
					inv.b	GameReg
					mov.b	GameReg, 2(JumpTimer)
					cmp.b	#0xFF, GameReg
					jnz		BallPoint2
					mov.w	#0, BallVelocity_X
					mov.w	#0, BallVelocity_Y
					; P1 Score increase end --------------------------------------------------------

PaddleLeftHit:		cmp.w	#13, Ball_X
					jge		PaddleRightHit
					mov.w	PaddleLeft_Y, GameReg
					add.w	#28, GameReg
					cmp.w	GameReg, Ball_Y
					jge		PaddleRightHit
					mov.w	Ball_Y, GameReg
					add.w	#4, GameReg
					cmp.w	PaddleLeft_Y, GameReg
					jl		PaddleRightHit
					mov.w	#BallSpeed, BallVelocity_X

PaddleRightHit:		cmp.w	#160, Ball_X
					jl		OuttaHere
					mov.w	PaddleRight_Y, GameReg
					add.w	#28, GameReg
					cmp.w	GameReg, Ball_Y
					jge		OuttaHere
					mov.w	Ball_Y, GameReg
					add.w	#4, GameReg
					cmp.w	PaddleRight_Y, GameReg
					jl		OuttaHere
					mov.w	#-BallSpeed, BallVelocity_X

OuttaHere:


			inc.w	CurrentLine
			reti

Blank:						        	; LINE 1 of the VSYNC will have the Game Calcluations
										; (Come in with 11 cycles)
			mov.w 	#21,JumpTimer		; (2, 13)
BJump:		dec.w	JumpTimer			;
			jnz		BJump				; 3*21 + 13 = 76
		    bis.b  	#BIT0,&P2OUT        ; Turn P2.0 ON
			inc.w	CurrentLine
			reti

VSyncStart:								; LINE 1 of the VSYNC will have the Game Calcluations
										; (Come in with 15 cycles)
			mov.w 	#307,JumpTimer		; (2, 17)
VJump:		dec.w	JumpTimer			;
			jnz		VJump				; 3*307 + 17 = 938
			nop
			nop 						;(940)
		    bis.b  	#BIT0,&P2OUT        ; Turn P2.0 ON
			inc.w	CurrentLine

			reti;


Blank2:						        	; LINE 1 of the VSYNC will have the Game Calcluations
										; (Come in with 19 cycles)
			mov.w 	#18,JumpTimer		; (2, 21)
BJump2:		dec.w	JumpTimer			;
			jnz		BJump2				; 3*18 + 21 = 75
			nop  						; (1, 76)


			bis.b  	#BIT0,&P2OUT      			  	; (4, 4) turn on p2.0
			mov.w	#BlankLine, LineBufferAddr		; (2, 6)
			mov.w	#BlankLine+20, R15				; (2, 8)
			mov.w	#51, JumpTimer					; (2, 10)
BLNKJMP:	dec.w	JumpTimer
			jnz		BLNKJMP							; 10+(51*3) = 163

			inc.w	CurrentLine			;(164)

			mov.b	@LineBufferAddr+, &UCB0TXBUF
			nop
			nop
			nop
			nop
TXOut2:		mov.b	@LineBufferAddr+, &UCB0TXBUF		; (5,5)
			mov.w	#7, JumpTimer			; (2,7)
OutputJMP2:	dec.w	JumpTimer
			jnz	OutputJMP2
			cmp.w	R15,LineBufferAddr					; (1, )
			nop
			jl		TXOut2					; (2, )
			reti

Blank3:						        	; LINE 1 of the VSYNC will have the Game Calcluations
										; (Come in with 27 cycles)
			mov.w 	#15,JumpTimer		; (2, 29)
BJump3:		dec.w	JumpTimer			;
			jnz		BJump3				; 3*15 + 29 = 74
			nop  						; (1, 75)
			nop  						; (1, 76)

			bis.b  	#BIT0,&P2OUT      			  	; (4, 4) turn on p2.0
			mov.w	#ScoreBoard, LineBufferAddr		; (2, 6)
			mov.w	#ScoreBoard+20, R15				; (2, 8)
			mov.w	#51, JumpTimer					; (2, 10)
BLNKJMP3:	dec.w	JumpTimer
			jnz		BLNKJMP3						; 10+(51*3) = 163

			inc.w	CurrentLine			;(164)

			mov.b	@LineBufferAddr+, &UCB0TXBUF
			nop
			nop
			nop
			nop
TXOut3:		mov.b	@LineBufferAddr+, &UCB0TXBUF		; (5,5)
			mov.w	#7, JumpTimer			; (2,7)
OutputJMP3:	dec.w	JumpTimer
			jnz	OutputJMP3
			cmp.w	R15,LineBufferAddr					; (1, )
			nop
			jl		TXOut3					; (2, )
			bic.w   #BIT4,&TA0CCTL0                          ; disable timer interrupt
			reti



; 2.0 on = 0.4
; 2.5 + 2.0 on 1.4



VisibleArea:							; Lines 20-262 will be the visible area
										;------------------------------------------
										;
										; First of all you need to be at 0v for the Horiziontal Sync Pulse
										; That will last for 75 cycles
										;
										; Then the Prescan area will be at 0.4v for 94 cycles
										;
										; Then the Visible area is next. It lasts for 824 cycles. (When you activate the 1.4v pin)
										;
										; Then the front porch is 0.4v at 22 cycles
										;
										; Lather Rinse and repeat 242 times!

; ------------- HORIZIONTAL SYNC (76 CYCLES)


										; COME IN with 23 CYCLES

			mov.w	#17,JumpTimer		; (2, 25)
HSyncJump:	dec.w	JumpTimer			;
			jnz		HSyncJump			; 17*3 + 25 = 76
; ------------- BACK PORCH (181 CYCLES)
			bis.b  	#BIT0,&P2OUT        ; (4, 4) turn on p2.0
			bis.w   #BIT4,&TA0CCTL0                          ; enable timer interrupt
			mov.w	#LineBuffer, LineBufferAddr	; (2, 6)
			mov.w	#LineBuffer+20, R15	; (2, 8)
			inc.w	CurrentLine			; (1, 9)
			mov.w	&TA1R, BKTimer		; (3, 12)
			add.w	#169, BKTimer

CheckLeftP:	cmp.w	PaddleLeft_Y, CurrentLine	;(1, 10)
			jl		CheckRightP1				;(2, 12)
			mov.w	PaddleLeft_Y, GameReg		;(1, 13)
			add.w	#28, GameReg				;(2, 15)
			cmp.w	GameReg, CurrentLine		;(1, 16)
			jge		CheckRightP2				;(2, 18)
			bis.b	#BIT4+BIT3+BIT7, 0(LineBufferAddr)		;(5, 23)
			jmp		CheckRightP3				;(2, 25)
CheckRightP1: ;12 cycles
			nop

CheckRightP2: ;18 cycles
			bis.b	#BIT7, 0(LineBufferAddr)	;(5, 23)
			nop
CheckRightP3:	; COME IN WITH 25 CYCLES
			cmp.w	PaddleRight_Y, CurrentLine   	;(1, 26)   cmp = dest - src
			jl		CheckBallX1					    ;(2, 28)   cmp src, dest
			mov.w	PaddleRight_Y, GameReg		    ;(1, 29)
			add.w	#28, GameReg				    ;(2, 31)
			cmp.w	GameReg, CurrentLine		    ;(1, 32)
			jge		CheckBallX2					    ;(2, 34)
			bis.b	#BIT6+BIT5+BIT1, 19(LineBufferAddr) 		;(5, 39)
			jmp		CheckBallX3					    ;(2, 41)
CheckBallX1: ;28 cycles
			nop
CheckBallX2: ;34 cycles
			bis.b	#BIT1, 19(LineBufferAddr)
			nop
CheckBallX3: ; COME IN WITH 42 CYCLES
			cmp.w	Ball_Y, CurrentLine
			jl		DottedLineX
			mov.w	Ball_Y, GameReg
			add.w	#4, GameReg
			cmp.w	GameReg, CurrentLine
			jge		DottedLineX
			mov.w	#-1, GameReg
StartBallX:	sub.w 	#1, LineBufferAddr
			mov.w	Ball_X, GameReg
			bic.w	#7, GameReg
			rra.w	GameReg
			rra.w	GameReg
			rra.w	GameReg
			add.w	GameReg, LineBufferAddr
BallBit:	mov.b	#192, GameReg
			mov.b	Ball_X, JumpTimer
			bic.b	#248, JumpTimer
			cmp.b	#0, JumpTimer
			jz		WriteBall
BitDec:		rra.w	GameReg
			dec.b	JumpTimer
			jnz 	BitDec
WriteBall:	bis.b	GameReg, 0(LineBufferAddr)
			cmp.b	#1, GameReg
			jnz		DottedLineX
			bis.b	#128, 1(LineBufferAddr)

DottedLineX:

			mov.w	#LineBuffer, LineBufferAddr

			reti


			; VISIBLE TRANSMITTER

TimerBTX:   mov.b	@LineBufferAddr+, &UCB0TXBUF		; (5,5)
			mov.b	#0, -1(LineBufferAddr)				; (4, 9)
TXOut:		mov.b	@LineBufferAddr+, &UCB0TXBUF		; (5,5)
			mov.b	#0, -1(LineBufferAddr)				; (4, 9)
			mov.w	#6, JumpTimer			; (2,11)
OutputJMP:	dec.w	JumpTimer				;
			jnz	OutputJMP					;
			cmp.w	R15,LineBufferAddr					; (1, 30)
			jl		TXOut					; (2, 32)
			reti

; ------------- VISIBLE AREA (777 CYCLES)


; Line Variables

 .bss LineBuffer, 20
 .bss PlayerScores, 2 ; The First Byte is the Left Paddle, Second is the right
 .bss ScoreBoard, 20
DottedLine .int 0xAAAA, 0xAAAA, 0xAAAA, 0xAAAA, 0xAAAA, 0xAAAA, 0xAAAA, 0xAAAA, 0xAAAA, 0xAAAA
BlankLine .int 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000


;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack



;-------------------------------------------------------------------------------------------
ERRANT_ISR
              bis.b  #001h, &P1OUT              ; P1.0 = ON
              jmp    ERRANT_ISR
;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect    ".int00"                          ;Not Used
            .short   ERRANT_ISR
            .sect    ".int01"                          ;Not Used
            .short   ERRANT_ISR
             .sect   ".int02"                          ;PORT1
            .short   ERRANT_ISR
             .sect   ".int03"                          ;PORT2
            .short   ERRANT_ISR
             .sect   ".int04"                          ;Not Used
            .short   ERRANT_ISR
             .sect   ".int05"                          ;ADC10
            .short   ERRANT_ISR
             .sect   ".int06"                          ;USCIAB0TX
            .short   ERRANT_ISR
             .sect   ".int07"                          ;USCIAB0RX
            .short   TimerBTX
             .sect   ".int08"                          ;Timer0_A1
            .short   TimerBTX
             .sect   ".int09"                          ;Timer0_A0
            .short   TimerBTX                        ; TA0_ISR
             .sect   ".int10"                          ;WDT
            .short   ERRANT_ISR
             .sect   ".int11"                          ;COMPA
            .short   TimerBTX
             .sect   ".int12"                          ;Timer1_A1
            .short   TimerBTX
             .sect   ".int13"                          ;Timer1_A0
            .short   TIMERRESET                        ;TA1_ISR
             .sect   ".int14"                          ;NMI
            .short   ERRANT_ISR
             .sect   ".reset"                          ;RESET
            .short   RESET
