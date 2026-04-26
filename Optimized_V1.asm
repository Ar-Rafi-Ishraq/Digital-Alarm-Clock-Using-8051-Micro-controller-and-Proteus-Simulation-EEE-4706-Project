;===========================================================
; Digital Alarm Clock v6.0 - OPTIMIZED
; AT89S52, 12MHz crystal, ASEM-51
; Active-LOW buzzer (CLR=ON, SETB=OFF)
;===========================================================

;--- BIT DEFINITIONS ---
LCD_RS  BIT P2.0
LCD_RW  BIT P2.1
LCD_EN  BIT P2.2
BUZZER  BIT P2.3        ; active LOW: CLR=ON, SETB=OFF
LED1    BIT P2.4
LED2    BIT P2.5
KR1     BIT P3.0
KR2     BIT P3.1
KR3     BIT P3.2
KR4     BIT P3.3

;--- RAM VARIABLES ---
SEC     DATA 30H
MINR    DATA 31H
HOUR    DATA 32H
A1HR    DATA 33H
A1MN    DATA 34H
A1EN    DATA 35H
A2HR    DATA 36H
A2MN    DATA 37H
A2EN    DATA 38H
A3HR    DATA 39H
A3MN    DATA 3AH
A3EN    DATA 3BH
TICK    DATA 3CH
SNZMIN  DATA 3DH
SNZACT  DATA 3EH
SNZHR   DATA 3FH
SNZMN   DATA 40H
SEQIDX  DATA 41H
DC1     DATA 42H        ; DLY_1MS counter
DC2     DATA 43H        ; DLY_5/10/20MS counter
DC3     DATA 44H        ; DLY_100/300/500MS counter
V1      DATA 50H        ; key / GET_2DIG result
V2      DATA 51H        ; tens digit temp
V3      DATA 52H        ; sequence flag
VN      DATA 53H        ; alarm number

;--- VECTORS ---
        ORG 0000H
        LJMP MAIN
        ORG 000BH
        LJMP T0_ISR

;--- TIMER0 ISR: 10ms tick, 12MHz reload=0xD8F0 ---
        ORG 0100H
T0_ISR: PUSH ACC
        PUSH PSW
        MOV  TH0, #0D8H
        MOV  TL0, #0F0H
        INC  TICK
        MOV  A, TICK
        CJNE A, #100, TXIT
        MOV  TICK, #00H
        INC  SEC
        MOV  A, SEC
        CJNE A, #60, TXIT
        MOV  SEC,  #00H
        INC  MINR
        MOV  A, MINR
        CJNE A, #60, TXIT
        MOV  MINR, #00H
        INC  HOUR
        MOV  A, HOUR
        CJNE A, #24, TXIT
        MOV  HOUR, #00H
TXIT:   POP  PSW
        POP  ACC
        RETI

;===========================================================
; MAIN
;===========================================================
        ORG 0200H
MAIN:
        MOV  SP,     #6FH
        MOV  SEC,    #00H
        MOV  MINR,   #00H
        MOV  HOUR,   #00H
        MOV  A1EN,   #00H
        MOV  A2EN,   #00H
        MOV  A3EN,   #00H
        MOV  SNZMIN, #05H
        MOV  SNZACT, #00H
        MOV  SEQIDX, #00H
        MOV  TICK,   #00H
        SETB BUZZER             ; active LOW: high=OFF
        CLR  LED1
        SETB LED2
        MOV  TMOD, #01H
        MOV  TH0,  #0D8H
        MOV  TL0,  #0F0H
        SETB ET0
        SETB EA
        SETB TR0
        LCALL LCD_INIT
        LCALL SHOW_MENU

;--- MAIN LOOP ---
MLOOP:  LCALL DISP_TIME
        LCALL CHK_ALARMS
        LCALL CHK_KEY_NB
        MOV  A, V1
        JZ   MDLY
        CJNE A, #'1', ML2
        LCALL MENU_SET_TIME
        SJMP MSHOW
ML2:    CJNE A, #'2', ML3
        MOV  VN, #01H
        SJMP MDALM
ML3:    CJNE A, #'3', ML4
        MOV  VN, #02H
        SJMP MDALM
ML4:    CJNE A, #'4', MDLY
        MOV  VN, #03H
MDALM:  LCALL MENU_SET_ALM
MSHOW:  LCALL SHOW_MENU
MDLY:   LCALL DLY_100MS
        LJMP MLOOP

;--- CHK_ALARMS ---
CHK_ALARMS:
        MOV  A, SNZACT
        JZ   CA1
        MOV  A, HOUR
        CJNE A, SNZHR, CA1
        MOV  A, MINR
        CJNE A, SNZMN, CA1
        MOV  A, SEC
        CJNE A, #00H, CA1
        MOV  SNZACT, #00H
        MOV  VN, #00H
        LCALL ALM_ROUTINE
CA1:    MOV  A, A1EN
        JZ   CA2
        MOV  A, HOUR
        CJNE A, A1HR, CA2
        MOV  A, MINR
        CJNE A, A1MN, CA2
        MOV  A, SEC
        CJNE A, #00H, CA2
        MOV  A1EN, #00H
        MOV  VN, #01H
        LCALL ALM_ROUTINE
CA2:    MOV  A, A2EN
        JZ   CA3
        MOV  A, HOUR
        CJNE A, A2HR, CA3
        MOV  A, MINR
        CJNE A, A2MN, CA3
        MOV  A, SEC
        CJNE A, #00H, CA3
        MOV  A2EN, #00H
        MOV  VN, #02H
        LCALL ALM_ROUTINE
CA3:    MOV  A, A3EN
        JZ   CADONE
        MOV  A, HOUR
        CJNE A, A3HR, CADONE
        MOV  A, MINR
        CJNE A, A3MN, CADONE
        MOV  A, SEC
        CJNE A, #00H, CADONE
        MOV  A3EN, #00H
        MOV  VN, #03H
        LCALL ALM_ROUTINE
CADONE: RET

;===========================================================
; ALM_ROUTINE
; Extra Feature 1: LED1 flashes with buzzer
; Extra Feature 2: Sequence 1->2->1 to stop
;===========================================================
ALM_ROUTINE:
        MOV  SEQIDX, #00H
ALML:   LCALL LCD_CH          ; clear + home
        MOV  DPTR, #MSG_ALM
        LCALL LCD_PSTR
        MOV  A, VN
        ADD  A, #30H
        LCALL LCD_WDAT
        LCALL LCD_LINE2
        MOV  DPTR, #MSG_HINT
        LCALL LCD_PSTR
        CLR  BUZZER             ; active LOW: ON
        SETB LED1
        LCALL ALM_POLL
        MOV  A, V1
        JNZ  AGOT
        SETB BUZZER             ; OFF
        CLR  LED1
        LCALL ALM_POLL
        MOV  A, V1
        JZ   ALML
AGOT:   SETB BUZZER             ; OFF
        CLR  LED1
        CJNE A, #'A', ALD
        LCALL DO_SNOOZE
        RET
ALD:    CJNE A, #'D', ALSEQ
        LCALL LCD_CH
        MOV  DPTR, #MSG_STOP
        LCALL LCD_PSTR
        LCALL DLY_1S
        RET
ALSEQ:  LCALL CHK_SEQ
        MOV  A, V3
        JZ   ALML
        LCALL LCD_CH
        MOV  DPTR, #MSG_STOP    ; reuse same string
        LCALL LCD_PSTR
        LCALL LCD_LINE2
        MOV  DPTR, #MSG_SOK
        LCALL LCD_PSTR
        LCALL DLY_1S
        MOV  SEQIDX, #00H
        RET

;--- ALM_POLL: scan keypad for 300ms ---
ALM_POLL:
        MOV  DC3, #30
        MOV  V1,  #00H
APLP:   LCALL DLY_10MS
        LCALL CHK_KEY_NB
        MOV  A, V1
        JNZ  APDN
        DJNZ DC3, APLP
APDN:   RET

;--- CHK_SEQ: validate 1->2->1 sequence ---
CHK_SEQ:
        MOV  V1, A
        MOV  V3, #00H
        MOV  A,  SEQIDX
        CJNE A, #00H, CS1
        MOV  A, V1
        CJNE A, #'1', CSWR
        INC  SEQIDX
        RET
CS1:    CJNE A, #01H, CS2
        MOV  A, V1
        CJNE A, #'2', CSWR
        INC  SEQIDX
        RET
CS2:    MOV  A, V1
        CJNE A, #'1', CSWR
        MOV  V3,     #01H
        MOV  SEQIDX, #00H
        RET
CSWR:   MOV  SEQIDX, #00H
        MOV  A, V1
        CJNE A, #'1', CSDN
        MOV  SEQIDX, #01H
CSDN:   RET

;--- DO_SNOOZE ---
DO_SNOOZE:
        LCALL KEY_RELEASE
        SETB BUZZER
        CLR  LED1
        LCALL LCD_CH
        MOV  DPTR, #MSG_SN1
        LCALL LCD_PSTR
        LCALL LCD_LINE2
        MOV  DPTR, #MSG_SN2
        LCALL LCD_PSTR
        LCALL GET_2DIG
        MOV  SNZMIN, V1
        MOV  A, MINR
        ADD  A, SNZMIN
        MOV  SNZMN, A
        MOV  A,     HOUR
        MOV  SNZHR, A
SNOV:   MOV  A, SNZMN
        CLR  C
        SUBB A, #60
        JC   SNNOV
        MOV  SNZMN, A
        INC  SNZHR
        MOV  A, SNZHR
        CJNE A, #24, SNOV
        MOV  SNZHR, #00H
        LJMP SNOV
SNNOV:  MOV  SNZACT, #01H
        LCALL LCD_CH
        MOV  DPTR, #MSG_SND
        LCALL LCD_PSTR
        LCALL DLY_1S
        RET

;--- MENU_SET_TIME ---
MENU_SET_TIME:
        LCALL KEY_RELEASE
        LCALL LCD_CH
        MOV  DPTR, #MSG_STIM
        LCALL LCD_PSTR
        LCALL LCD_LINE2
        MOV  DPTR, #MSG_EHR
        LCALL LCD_PSTR
        LCALL GET_2DIG
        MOV  HOUR, V1
        LCALL LCD_LINE2
        MOV  DPTR, #MSG_EMN
        LCALL LCD_PSTR
        LCALL GET_2DIG
        MOV  MINR, V1
        MOV  SEC,  #00H
        LCALL LCD_CH
        MOV  DPTR, #MSG_TST
        LCALL LCD_PSTR
        LCALL DLY_1S
        RET

;--- MENU_SET_ALM (VN=1,2,3) ---
MENU_SET_ALM:
        LCALL KEY_RELEASE
        LCALL LCD_CH
        MOV  DPTR, #MSG_SALM
        LCALL LCD_PSTR
        MOV  A, VN
        ADD  A, #30H
        LCALL LCD_WDAT
        LCALL LCD_LINE2
        MOV  DPTR, #MSG_EHR
        LCALL LCD_PSTR
        LCALL GET_2DIG
        MOV  A, VN
        CJNE A, #01H, SAH2
        MOV  A1HR, V1
        LJMP SAMN
SAH2:   CJNE A, #02H, SAH3
        MOV  A2HR, V1
        LJMP SAMN
SAH3:   MOV  A3HR, V1
SAMN:   LCALL LCD_LINE2
        MOV  DPTR, #MSG_EMN
        LCALL LCD_PSTR
        LCALL GET_2DIG
        MOV  A, VN
        CJNE A, #01H, SAM2
        MOV  A1MN, V1
        MOV  A1EN, #01H
        LJMP SADN
SAM2:   CJNE A, #02H, SAM3
        MOV  A2MN, V1
        MOV  A2EN, #01H
        LJMP SADN
SAM3:   MOV  A3MN, V1
        MOV  A3EN, #01H
SADN:   LCALL LCD_CH
        MOV  DPTR, #MSG_ASET
        LCALL LCD_PSTR
        MOV  A, VN
        ADD  A, #30H
        LCALL LCD_WDAT
        MOV  DPTR, #MSG_SETOK
        LCALL LCD_PSTR
        LCALL DLY_1S
        RET

;--- DISP_TIME ---
DISP_TIME:
        LCALL LCD_HOME
        MOV  DPTR, #MSG_TL
        LCALL LCD_PSTR
        MOV  A, HOUR
        LCALL P2D
        MOV  A, #':'
        LCALL LCD_WDAT
        MOV  A, MINR
        LCALL P2D
        MOV  A, #':'
        LCALL LCD_WDAT
        MOV  A, SEC
        LCALL P2D
        LCALL LCD_LINE2
        MOV  A, #'A'
        LCALL LCD_WDAT
        MOV  A, #':'
        LCALL LCD_WDAT
        MOV  A, A1EN
        JZ   DA1N
        MOV  A, #'1'
        SJMP DA1P
DA1N:   MOV  A, #'-'
DA1P:   LCALL LCD_WDAT
        MOV  A, A2EN
        JZ   DA2N
        MOV  A, #'2'
        SJMP DA2P
DA2N:   MOV  A, #'-'
DA2P:   LCALL LCD_WDAT
        MOV  A, A3EN
        JZ   DA3N
        MOV  A, #'3'
        SJMP DA3P
DA3N:   MOV  A, #'-'
DA3P:   LCALL LCD_WDAT
        MOV  DPTR, #MSG_SP
        LCALL LCD_PSTR
        RET

;--- SHOW_MENU ---
SHOW_MENU:
        LCALL LCD_CH
        MOV  DPTR, #MSG_M1
        LCALL LCD_PSTR
        LCALL LCD_LINE2
        MOV  DPTR, #MSG_M2
        LCALL LCD_PSTR
        RET

;--- P2D: print A as 2 decimal digits ---
P2D:    MOV  B, #10
        DIV  AB
        ADD  A, #30H
        LCALL LCD_WDAT
        MOV  A, B
        ADD  A, #30H
        LCALL LCD_WDAT
        RET

;--- GET_2DIG: read 2 digits -> binary in V1 ---
GET_2DIG:
        LCALL GET_KEY
        LCALL LCD_WDAT_V1       ; echo and convert tens
        CLR  C
        SUBB A, #30H
        MOV  V2, A
        LCALL GET_KEY
        LCALL LCD_WDAT_V1       ; echo and convert units
        CLR  C
        SUBB A, #30H
        MOV  V1, A
        MOV  B,  #10
        MOV  A,  V2
        MUL  AB
        ADD  A,  V1
        MOV  V1, A
        RET

; Helper: move V1 to A, write to LCD, leave A=V1
LCD_WDAT_V1:
        MOV  A, V1
        LCALL LCD_WDAT
        MOV  A, V1
        RET

;--- KEY_RELEASE ---
KEY_RELEASE:
        CLR  KR1
        CLR  KR2
        CLR  KR3
        CLR  KR4
        NOP
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0F0H, KEY_RELEASE
        LCALL DLY_20MS
        RET

;===========================================================
; KEYPAD - GET_KEY (blocking) and CHK_KEY_NB (non-blocking)
;===========================================================
GET_KEY:
GKLP:   MOV  P3, #0F0H
        CLR  KR1
        SETB KR2
        SETB KR3
        SETB KR4
        NOP
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0F0H, GR1
        SETB KR1
        CLR  KR2
        NOP
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0F0H, GR2
        SETB KR2
        CLR  KR3
        NOP
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0F0H, GR3
        SETB KR3
        CLR  KR4
        NOP
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0F0H, GR4
        LJMP GKLP

; Each row: debounce 20ms, read col, store key, release, ret
GR1:    LCALL DLY_20MS
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0E0H, G1B
        MOV  V1, #'1'
        LJMP KRET
G1B:    CJNE A, #0D0H, G1C
        MOV  V1, #'2'
        LJMP KRET
G1C:    CJNE A, #0B0H, G1D
        MOV  V1, #'3'
        LJMP KRET
G1D:    MOV  V1, #'A'
        LJMP KRET

GR2:    LCALL DLY_20MS
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0E0H, G2B
        MOV  V1, #'4'
        LJMP KRET
G2B:    CJNE A, #0D0H, G2C
        MOV  V1, #'5'
        LJMP KRET
G2C:    CJNE A, #0B0H, G2D
        MOV  V1, #'6'
        LJMP KRET
G2D:    MOV  V1, #'B'
        LJMP KRET

GR3:    LCALL DLY_20MS
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0E0H, G3B
        MOV  V1, #'7'
        LJMP KRET
G3B:    CJNE A, #0D0H, G3C
        MOV  V1, #'8'
        LJMP KRET
G3C:    CJNE A, #0B0H, G3D
        MOV  V1, #'9'
        LJMP KRET
G3D:    MOV  V1, #'C'
        LJMP KRET

GR4:    LCALL DLY_20MS
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0E0H, G4B
        MOV  V1, #'*'
        LJMP KRET
G4B:    CJNE A, #0D0H, G4C
        MOV  V1, #'0'
        LJMP KRET
G4C:    CJNE A, #0B0H, G4D
        MOV  V1, #'#'
        LJMP KRET
G4D:    MOV  V1, #'D'
KRET:   LCALL KEY_RELEASE       ; single shared release point
        RET

; CHK_KEY_NB: non-blocking - if any key down, call GET_KEY
CHK_KEY_NB:
        MOV  V1, #00H
        CLR  KR1
        SETB KR2
        SETB KR3
        SETB KR4
        NOP
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0F0H, CKNP
        SETB KR1
        CLR  KR2
        NOP
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0F0H, CKNP
        SETB KR2
        CLR  KR3
        NOP
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0F0H, CKNP
        SETB KR3
        CLR  KR4
        NOP
        MOV  A, P3
        ANL  A, #0F0H
        CJNE A, #0F0H, CKNP
        RET
CKNP:   LJMP GET_KEY            ; tail-call: GET_KEY will RET for us

;===========================================================
; LCD DRIVER
;===========================================================
; LCD_CH: clear display then set cursor to row0 col0
; Saves 1 LCALL vs calling LCD_CLEAR + LCD_HOME separately
LCD_CH:
        MOV  A, #01H
        LCALL LCD_CMD
        LCALL DLY_5MS
        MOV  A, #80H
        LCALL LCD_CMD
        RET

LCD_INIT:
        LCALL DLY_20MS
        MOV  A, #30H
        LCALL LCD_CMD
        LCALL DLY_5MS
        MOV  A, #30H
        LCALL LCD_CMD
        LCALL DLY_1MS
        MOV  A, #30H
        LCALL LCD_CMD
        LCALL DLY_1MS
        MOV  A, #38H
        LCALL LCD_CMD
        LCALL DLY_1MS
        MOV  A, #08H
        LCALL LCD_CMD
        LCALL DLY_1MS
        MOV  A, #01H
        LCALL LCD_CMD
        LCALL DLY_5MS
        MOV  A, #06H
        LCALL LCD_CMD
        LCALL DLY_1MS
        MOV  A, #0CH
        LCALL LCD_CMD
        LCALL DLY_1MS
        RET

LCD_CMD:
        MOV  P1, A
        CLR  LCD_RS
        CLR  LCD_RW
        SETB LCD_EN
        LCALL DLY_1MS
        CLR  LCD_EN
        LCALL DLY_2MS
        RET

LCD_WDAT:
        MOV  P1, A
        SETB LCD_RS
        CLR  LCD_RW
        SETB LCD_EN
        LCALL DLY_1MS
        CLR  LCD_EN
        LCALL DLY_1MS
        RET

LCD_HOME:
        MOV  A, #80H
        LCALL LCD_CMD
        RET

LCD_LINE2:
        MOV  A, #0C0H
        LCALL LCD_CMD
        RET

LCD_PSTR:
        CLR  A
        MOVC A, @A+DPTR
        JZ   LPDN
        LCALL LCD_WDAT
        INC  DPTR
        SJMP LCD_PSTR
LPDN:   RET

;===========================================================
; DELAY ROUTINES (12MHz)
; DC1=DLY_1MS only, DC2=mid-level, DC3=outer-level
;===========================================================
DLY_1MS:
        MOV  DC1, #0FAH
DM1A:   DJNZ DC1, DM1A
        MOV  DC1, #0FAH
DM1B:   DJNZ DC1, DM1B
        RET

DLY_2MS:
        MOV  DC2, #02H
DM2:    LCALL DLY_1MS
        DJNZ DC2, DM2
        RET

DLY_5MS:
        MOV  DC2, #05H
DM5:    LCALL DLY_1MS
        DJNZ DC2, DM5
        RET

DLY_10MS:
        MOV  DC2, #10
DM10:   LCALL DLY_1MS
        DJNZ DC2, DM10
        RET

DLY_20MS:
        MOV  DC2, #20
DM20:   LCALL DLY_1MS
        DJNZ DC2, DM20
        RET

DLY_100MS:
        MOV  DC3, #20
DM100:  LCALL DLY_5MS
        DJNZ DC3, DM100
        RET

DLY_1S:
        MOV  DC3, #200
DM1S:   LCALL DLY_5MS
        DJNZ DC3, DM1S
        RET

;===========================================================
; STRINGS
;===========================================================
MSG_M1:  DB "1:Time 2:Alm1  ", 0
MSG_M2:  DB "3:Alm2 4:Alm3  ", 0
MSG_TL:  DB "Time:", 0
MSG_ALM: DB "!! ALARM ", 0
MSG_HINT:DB "PassCode, A=Snz", 0
MSG_STOP:DB "Alarm Stopped! ", 0  ; shared by D-stop AND seq-stop
MSG_SOK: DB "Seq Correct :) ", 0
MSG_SN1: DB "Snooze Duration", 0
MSG_SN2: DB "Mins(01-59):   ", 0
MSG_SND: DB "Snoozed!       ", 0
MSG_STIM:DB "--- Set Time --", 0
MSG_EHR: DB "Hour(00-23):   ", 0
MSG_EMN: DB "Min (00-59):   ", 0
MSG_TST: DB "Time Set OK!   ", 0
MSG_SALM:DB "Set Alarm #", 0
MSG_ASET:DB "Alarm ", 0
MSG_SETOK:DB " Set OK!      ", 0
MSG_SP:  DB "         ", 0

        END