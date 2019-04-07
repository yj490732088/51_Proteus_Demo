;********************************************************************************
;*  ����:  ΰ�ɵ���ME300B��Ƭ������ϵͳ��ʾ���� - DS18B20�¶ȿ���1602LCD��ʾ    *
;*  �ļ�:  DS18B20-LCD.asm                                                      *
;*  ����:  2005-3-20                                                            *
;*  �汾:  1.0                                                                  *
;*  ����:  gguoqing                                                             *
;*  ����:  gguoqing@willar.com                                                  *
;*  ��վ�� http://www.willar.com                                                *
;********************************************************************************
;*  ����:                                                                       *
;*          DS18B20�¶ȿ���1602LCD��ʾ                                          *
;*                                                                              *
;*          ʹ�÷����ο�readme.txt�ĵ�                                          *
;*                                                                              *
;*                                                                              *
;********************************************************************************
;* ����Ȩ�� Copyright(C)ΰ�ɵ��� www.willar.com  All Rights Reserved            *
;* �������� �˳��������ѧϰ��ο���������ע����Ȩ��������Ϣ��                  *
;********************************************************************************

 

          TEMP_ZH   DATA  24H     ;ʵʱ�¶�ֵ��ŵ�Ԫ
          TEMPL     DATA  25H     ;
          TEMPH     DATA  26H     ;
          TEMP_TH   DATA  27H     ;���±���ֵ��ŵ�Ԫ
          TEMP_TL   DATA  28H     ;���±���ֵ��ŵ�Ԫ
          TEMPHC    DATA  29H     ;
          TEMPLC    DATA  2AH

          K1     EQU  P1.4
          K2     EQU  P1.5
          K3     EQU  P1.6
          K4     EQU  P1.7

          BEEP      EQU  P3.7
          RELAY     EQU  P1.3
          LCD_X     EQU  2FH      ;LCD ��ַ����
          LCD_RS    EQU  P2.0
          LCD_RW    EQU  P2.1
          LCD_EN    EQU  P2.2
          flag1     equ  20H.0    ;DS18B20�Ƿ���ڱ��
          KEY_UD    EQU  20H.1    ;�趨 KEY ��UP��DOWN ���
          date_line equ p3.3
;=====================================================
           ORG  0000H
           JMP  MAIN

		   
		  ORG  0030H
MAIN:     MOV  SP,#60H
          MOV  A,#00H
          MOV  R0,#20H       ;�� 20H-2FH ��Ԫ����
          MOV  R1,#10H
CLEAR:    MOV  @R0,A
          INC  R0
          DJNZ  R1,CLEAR

          CALL  SET_LCD
          CALL  RE_18B20

start:    CALL  RESET          ;18B20��λ�ӳ���
          JNB   FLAG1,START1   ;DS1820������
          CALL  MENU_OK
          CALL  READ_E2
          CALL  TEMP_BJ        ;��ʾ�¶ȱ��
          JMP   START2
START1:   CALL  MENU_ERROR
          CALL  TEMP_BJ        ;��ʾ�¶ȱ��
          JMP  $

START2:
          CALL  RESET
          JNB  FLAG1,START1    ;DS1820������
          MOV   A,#0CCH        ; ����ROMƥ��
          CALL  WRITE
          MOV   A,#44H         ; �����¶�ת������
          CALL  WRITE
          CALL  RESET
          MOV   A,#0CCH        ; ����ROMƥ��
          CALL  WRITE
          MOV   A,#0BEH        ; �������¶�����
          CALL  WRITE
          CALL  READ
          call CONVTEMP
          Call DISPBCD
          CALL CONV
          CALL TEMP_COMP
          CALL  PROC_KEY       ; ��ɨ��

   SJMP START2
;-----------------------------------------------------
PROC_KEY:
  JB  K1,PROC_K1    ; ����K1����
         CALL  BEEP_BL
         JNB  K1,$
         MOV  DPTR,#M_ALAX1
         MOV  A,#1
         CALL  LCD_PRINT
         CALL  LOOK_ALARM
         JB  K3,$
         CALL  BEEP_BL
         JMP  PROC_K2
PROC_K1:     ; ����K2����
         JB  K2,PROC_END
         CALL  BEEP_BL
         JNB  K2,$
         MOV   DPTR,#RESET_A1
         MOV   A,#1
         CALL  LCD_PRINT
         CALL  SET_ALARM
         CALL  RE_18B20           ;���趨��TH,TLֵд��DS18B20��
         CALL  WRITE_E2
PROC_K2:
         CALL  MENU_OK
         CALL  TEMP_BJ
PROC_END:
         RET
;============================================
;�趨����ֵ TH��TL
;============================================
SET_ALARM:
         ;CALL  RESET_ALARM
         CALL  LOOK_ALARM
AS0:
         JB   K1,AS00
         CALL  BEEP_BL
         JNB  K1,$
         CPL  20H.1            ;UP/DOWN ���
AS00:    JB  20H.1,ASZ01       ;20H.1=1��UP
         JMP  ASJ01            ;20H.1=0��DOWN

ASZ01:   JB  K2,ASZ02          ;THֵ���������ӣ�
         CALL  BEEP_BL
         INC  TEMP_TH
         MOV  A,TEMP_TH
         CJNE  A,#120,ASZ011
         MOV  TEMP_TH,#0
ASZ011:  CALL  LOOK_ALARM
         MOV  R5,#10
         CALL  DELAY
         JMP  ASZ01

ASZ02:   JB  K3,ASZ03          ;TLֵ���������ӣ�
         CALL  BEEP_BL
         INC  TEMP_TL
         MOV  A,TEMP_TL
         CJNE  A,#99,ASZ021
         MOV  TEMP_TL,#00H
ASZ021:  CALL  LOOK_ALARM    ;
         MOV  R5,#10
         CALL  DELAY
         JMP  ASZ02
ASZ03:   JB  K4,AS0          ;ȷ������ OK
         CALL  BEEP_BL
         JNB  K4,$
         RET

ASJ01:
         JB  K2,ASJ02          ;THֵ���� �����٣�
         CALL  BEEP_BL
         DEC   TEMP_TH
         MOV  A,TEMP_TH
         CJNE  A,#0FFH,ASJ011
         JMP  ASJ022
ASJ011:  CALL  LOOK_ALARM
         MOV  R5,#10
         CALL  DELAY
         JMP  AS0

ASJ02:   JB  K3,ASJ03         ;TLֵ���������٣�
         CALL  BEEP_BL
         DEC  TEMP_TL
         MOV  A,TEMP_TL
         CJNE  A,#0FFH,ASJ021
         JMP  ASJ022
ASJ021:  CALL  LOOK_ALARM    ;
         MOV  R5,#10
         CALL  DELAY
         JMP  AS0
ASJ022:  CPL  20H.1
         JMP  ASZ01
ASJ03:   JMP  ASZ03
         RET


RESET_ALARM:
          MOV  DPTR,#RESET_A1  ;ָ��ָ����ʾ��Ϣ��
          MOV  A,#1            ;��ʾ�ڵ�һ��
          CALL  LCD_PRINT
          RET
RESET_A1:
     DB  "RESET ALERT CODE"
;====================================================
;ʵ���¶�ֵ�����¶�ֵ�Ƚ��ӳ���
;====================================================
TEMP_COMP:
          MOV  A,TEMP_TH       
          SUBB  A,TEMP_ZH       ;����>����������
          JC  CHULI1            ;��λ��־λC=1��ת
          MOV  A,TEMP_ZH
          SUBB  A,TEMP_TL       ;����>����������
          JC  CHULI2            ;��λ��־λC=1��ת
          MOV  DPTR,#BJ5
          CALL  TEMP_BJ3
          CLR   RELAY           ;�̵�������
          RET
 CHULI1:
          MOV  DPTR,#BJ3
          CALL  TEMP_BJ3
          SETB  RELAY           ;�̵����ر�
          CALL  BEEP_BL
          RET
 CHULI2:
          MOV  DPTR,#BJ4
          CALL  TEMP_BJ3
          CALL  BEEP_BL
          RET
;-----------------------------------------
TEMP_BJ3:
          MOV  A,#0CEH
          CALL WCOM
          MOV  R1,#0
          MOV  R0,#2

BBJJ3:    MOV  A,R1
          MOVC A,@A+DPTR
          CALL  WDATA
          INC R1
          DJNZ  R0,BBJJ3
          RET
BJ3:
      DB  ">H"
BJ4:
      DB  "<L"
BJ5:
      DB  " !"
;==================================================
;��ʾ�¶ȱ���ӳ���
;==================================================
TEMP_BJ:
          MOV  A,#0CBH
          CALL WCOM
          MOV  DPTR,#BJ1  ;ָ��ָ����ʾ��Ϣ
          MOV  R1,#0
          MOV  R0,#2

BBJJ1:    MOV  A,R1
          MOVC A,@A+DPTR
          CALL  WDATA
          INC R1
          DJNZ  R0,BBJJ1
          RET
BJ1:
      DB  00H,"C"
;=================================================
MENU_OK:

          MOV  DPTR,#M_OK1  ;ָ��ָ����ʾ��Ϣ
          MOV  A,#1          ;��ʾ�ڵ�һ��
          CALL  LCD_PRINT
          MOV  DPTR,#M_OK2  ;ָ��ָ����ʾ��Ϣ
          MOV  A,#2          ;��ʾ�ڵ�һ��
          CALL  LCD_PRINT

          RET
M_OK1:
    DB   "   DS18B20 OK   ",0
M_OK2:
    DB   " TEMP:          ",0
;-----------------------------------------------
MENU_ERROR:
          MOV  DPTR,#M_ERROR1  ;ָ��ָ����ʾ��Ϣ1
          MOV  A,#1          ;��ʾ�ڵ�һ��
          CALL  LCD_PRINT
          MOV  DPTR,#M_ERROR2  ;ָ��ָ����ʾ��Ϣ1
          MOV  A,#2          ;��ʾ�ڵ�һ��
          CALL  LCD_PRINT
          RET
M_ERROR1:
    DB   " DS18B20 ERROR  ",0
M_ERROR2:
    DB   " TEMP: ----     ",0
;====================================================
reset:  setb date_line
        nop
        clr date_line
        mov r0,#6bh         ;����������ʱ��λ������
        mov r1,#04h
tsr1:   djnz r0,$
        mov r0,#6bh
        djnz r1,tsr1
        setb date_line        ;Ȼ������������
        nop
        nop
        nop
        mov r0,#32h
tsr2:   jnb date_line,tsr3   ;�ȴ�DS18B20��Ӧ
        djnz r0,tsr2
        jmp tsr4             ; ��ʱ
tsr3:   setb flag1           ; �ñ�־λ,��ʾDS1820����
        jmp tsr5
tsr4:   clr flag1            ; ���־λ,��ʾDS1820������
        jmp tsr7
tsr5:   mov r0,#06bh
tsr6:   djnz r0,$            ; ʱ��Ҫ����ʱһ��ʱ��
tsr7:   setb date_line
        ret
;=======================================================
RE_18B20:
        JB  FLAG1,RE_18B20A
        RET
RE_18B20A:
        CALL  RESET
        MOV  A,#0CCH       ;����ROMƥ��
        LCALL  WRITE
        MOV  A,#4EH        ;д�ݴ�Ĵ���
        LCALL  WRITE
        MOV  A,TEMP_TH     ;TH(�������ޣ�
        LCALL  WRITE
        MOV  A,TEMP_TL     ;TL(�������ޣ�
        LCALL  WRITE
        MOV  A,#7FH        ;12λ��ȷ��
        LCALL  WRITE
        RET
;------------------------------------------------------------
WRITE_E2:
        CALL  RESET
        MOV  A,#0CCH        ;����ROMƥ��
        LCALL  WRITE
        MOV  A,#48H         ;���ݴ�������¶ȱ���ֵ������EEROM
        LCALL  WRITE
        RET
;--------------------------------------------------------------
READ_E2:
        CALL  RESET
        MOV  A,#0CCH        ;����ROMƥ��
        LCALL  WRITE
        MOV  A,#0B8H        ;��EEROM����¶ȱ���ֵ�������ݴ���
        CALL  WRITE
        RET
;--------------------------------------------------------------
;���Զ����ַ�д��LCD1602��CGRAM��
;--------------------------------------------------------------
STORE_DATA:
        MOV  A,#40H
        CALL  WCOM
        MOV  R2,#08H
        MOV  DPTR,#D_DATA
        MOV  R3,#00H
S_DATA:
        MOV  A,R3
        MOVC  A,@A+DPTR
        CALL  WDATA      ;д������
        INC  R3
        DJNZ  R2,S_DATA
        RET

D_DATA:
    DB  0CH,12H,12H,0CH,00H,00H,00H,00H
;==============================================================
write:  mov r2,#8            ;һ��8λ����
        CLR  C
wr1:
        clr date_line        ;��ʼд��DS18B20����Ҫ���ڸ�λ���ͣ�״̬
        mov r3,#07
        djnz r3,$            ;���߸�λ����16΢������
        rrc a                ;��һ���ֽ�DATA �ֳ�8��BIT���Ƹ�C
        mov date_line,c      ;д��һ��BIT
        mov r3,#3CH
        djnz r3,$            ;�ȴ�100΢��
        setb date_line       ;�����ͷ�����
        nop
        djnz r2,wr1          ;д����һ��BIT
        setb date_line
        ret
;--------------------------------------------------------------------
read:    mov r4,#4          ; ���¶ȵ�λ����λ��TH��TL��DS18B20�ж���
         mov r1,#TEMPL        ; ����25H��26H��27H��28H
re00:    mov r2,#8
re01:    clr cy
         setb date_line
         nop
         nop
         clr date_line        ;��ǰ���߱���Ϊ��
         nop
         nop
         nop
         setb date_line       ;��ʼ�������ͷ�
         mov r3,#09           ;��ʱ18΢��
         djnz r3,$
         mov c,date_line      ;��DS18B20���߶���һ��BIT
         mov r3,#3CH
         djnz r3,$            ;�ȴ�100΢��
         rrc a                ;�Ѷ��õ�λֵ���Ƹ�A
         djnz r2,re01         ;����һ��BIT
         mov @r1,a
         inc r1
         djnz r4,re00
         ret


;*****************************************************
;  �����¶� BCD ���ӳ���
;****************************************************
CONVTEMP:      MOV  A,TEMPH       ;���¶��Ƿ�����
               ANL  A,#80H
               JZ  TEMPC1         ;�¶�����ת
               CLR  C
               MOV  A,TEMPL       ;���������󲹣�˫�ֽڣ�
               CPL  A             ;ȡ����1
               ADD  A,#01H
               MOV  TEMPL,A
               MOV  A,TEMPH
               CPL  A
               ADDC  A,#00H
               MOV  TEMPH,A
               SJMP  TEMPC11

TEMPC1:        MOV  TEMPHC,#0AH     ;+
TEMPC11:       MOV  A,TEMPHC
               SWAP  A
               MOV  TEMPHC,A
               MOV  A,TEMPL
               ANL  A,#0FH              ;��0.0625
               MOV  DPTR,#TEMPDOTTAB
               MOVC  A,@A+DPTR
               MOV  TEMPLC,A            ;TEMPLC LOW=С������ BCD

               MOV  A,TEMPL             ;��������
               ANL  A,#0F0H             ;ȡ������λ
               SWAP  A
               MOV  TEMPL,A
               MOV  A,TEMPH             ;ȡ������λ
               ANL  A,#0FH
               SWAP  A
               ORL  A,TEMPL             ;�������
               MOV  TEMP_ZH,A
               LCALL  HEX2BCD1
               MOV  TEMPL,A
               ANL  A,#0F0H
               SWAP  A
               ORL  A,TEMPHC            ;TEMPHC LOW = ʮλ�� BCD
               MOV  TEMPHC,A
               MOV  A,TEMPL
               ANL  A,#0FH
               SWAP  A                  ;TEMPLC HI = ��λ�� BCD
               ORL  A,TEMPLC
               MOV  TEMPLC,A
               MOV  A,R4
               JZ  TEMPC12
               ANL  A,#0FH
               SWAP  A
               MOV  R4,A
               MOV  A,TEMPHC            ;TEMPHC HI = ��λ�� BCD
               ANL  A,#0FH
               ORL  A,R4
               MOV  TEMPHC,A
TEMPC12:       RET
;---------------------------------------------------------------
HEX2BCD1:
              MOV  B,#064H          ;ʮ������-> BCD
              DIV  AB               ;B= A % 100
              MOV  R4,A             ;R7 = ��λ��
              MOV  A,#0AH
              XCH  A,B
              DIV  AB               ;B = A % B
              SWAP  A
              ORL  A,B
              RET
;-------------------------------------------------------------
;  С���������
;-------------------------------------------------------------
TEMPDOTTAB:
         DB   00H,00H,01H,01H,02H,03H,03H,04H
         DB   05H,05H,06H,06H,07H,08H,08H,09H
;=====================================================
LOOK_ALARM:

          MOV  DPTR,#M_ALAX2   ;ָ��ָ����ʾ��Ϣ��
          MOV  A,#2            ;��ʾ�ڵڶ���
          CALL  LCD_PRINT

          MOV  A,#0C6H
          CALL  TEMP_BJ1
          MOV  A,TEMP_TH       ;����TH����
          MOV  LCD_X,#3        ;����λ��
          CALL  SHOW_DIG2H     ;��ʾ����

          MOV  A,#0CEH
          CALL  TEMP_BJ1
          MOV  A,TEMP_TL       ;����TL����
          MOV  LCD_X,#12       ;����λ��
          CALL  SHOW_DIG2L     ;��ʾ����
          RET
;--------------------------------------------
M_ALAX1:
     DB   " LOOK ALERT CODE",0
M_ALAX2:
     DB   "TH:      TL:    ",0
;--------------------------------------------
TEMP_BJ1:
          CALL WCOM
          MOV  DPTR,#BJ2      ;ָ��ָ����ʾ��Ϣ��
          MOV  R1,#0
          MOV  R0,#2

BBJJ2:    MOV  A,R1
          MOVC A,@A+DPTR
          CALL  WDATA
          INC R1
          DJNZ  R0,BBJJ2
          RET
BJ2:
      DB  00H,"C"

;---------------------------------------------------
SHOW_DIG2H:                ;�� LCD �ĵڶ�����ʾ����
          MOV  B,#100
          DIV  AB
          ADD  A,#30H
          PUSH  B
          MOV  B,LCD_X
          CALL  LCDP2
          POP  B
          MOV  A,#0AH
          XCH  A,B
          DIV  AB
          ADD  A,#30H
          INC  LCD_X
          PUSH  B
          MOV  B,LCD_X
          CALL  LCDP2
          POP  B
          INC  LCD_X
          MOV  A,B
          MOV  B,LCD_X
          ADD  A,#30H
          CALL  LCDP2
          RET

SHOW_DIG2L:                ;�� LCD �ĵڶ�����ʾ����
          MOV  B,#100
          DIV  AB
          MOV  A,#0AH
          XCH  A,B
          DIV  AB
          ADD  A,#30H
          PUSH  B
          MOV  B,LCD_X
          CALL  LCDP2
          POP  B
          INC  LCD_X
          MOV  A,B
          MOV  B,LCD_X
          ADD  A,#30H
          CALL  LCDP2
          RET
;-------------------------------------------------------------
;��ʾ�� BCD ���¶�ֵˢ���ӳ���
;-------------------------------------------------------------
DISPBCD:
              MOV  A,TEMPLC
              ANL  A,#0FH
              MOV  70H,A                 ;С��λ
              MOV  A,TEMPLC
              SWAP  A
              ANL  A,#0FH
              MOV  71H,A                 ;��λ
              MOV  A,TEMPHC
              ANL  A,#0FH
              MOV  72H,A                 ;ʮλ
              MOV  A,TEMPHC
              SWAP  A
              ANL  A,#0FH
              MOV  73H,A                 ;��λ
              MOV  A,TEMPHC
              ANL  A,#0F0H
              CJNE  A,#010H,DISPBCD0
              SJMP  DISPBCD2

DISPBCD0:     MOV  A,TEMPHC
              ANL  A,#0FH
              JNZ  DISPBCD2               ;ʮλ����0
              MOV  A,TEMPHC
              SWAP  A
              ANL  A,#0FH
              MOV  73H,#0AH               ;����λ����ʾ
              MOV  72H,A                  ;ʮλ����ʾ����
DISPBCD2:     RET

;==========================================================
; LCD 1602 ��ʾ�ӳ���
;==========================================================
CONV:
          MOV  A,73H         ;���ذ�λ����
          MOV  LCD_X,#6      ;����λ��
          CJNE A,#1,CONV1
          JMP  CONV2
CONV1:    MOV  A,#" "
          MOV  B,LCD_X
          CALL  LCDP2
          JMP  CONV3
CONV2:    CALL  SHOW_DIG2    ;��ʾ����
CONV3:    INC  LCD_X             ;
          mov  a,72h         ;ʮλ
          CALL  SHOW_DIG2
          inc  LCD_X
          mov  a,71h         ;��λ
          CALL  SHOW_DIG2
          inc  LCD_X
          MOV  A,#'.'
          MOV  B,LCD_X
          CALL  LCDP2
          MOV  A,70h         ;����С����λ
          INC  LCD_X         ;����λ��
          CALL  SHOW_DIG2    ;��ʾ����
          RET
;-------------------------------------------------------
SHOW_DIG2:                 ;�� LCD �ĵڶ�����ʾ����
          ADD  A,#30H
          MOV  B,LCD_X
          CALL  LCDP2
          RET
;---------------------------------------------------------
LCDP2:                    ;��LCD�ĵڶ�����ʾ�ַ�
         PUSH  ACC        ;
         MOV  A,B         ;������ʾ��ַ
         ADD  A,#0C0H     ;����LCD�ĵڶ��е�ַ
         CALL  WCOM       ;д������
         POP  ACC         ;�ɶ�ջȡ��A
         CALL  WDATA      ;д������
         RET
;---------------------------------------------------------


SET_LCD:                     ;�� LCD ����ʼ�����ü�����
          CLR  LCD_EN
          CALL  INIT_LCD     ;��ʼ�� LCD
          CALL  STORE_DATA   ;���Զ����ַ�����LCD��CGRAM
          RET
INIT_LCD:                  ;8λI/O���� LCD �ӿڳ�ʼ��
          MOV  A,#38H        ;˫����ʾ������5*7����
          CALL  WCOM
          call  delay1
          MOV  A,#38H
          CALL  WCOM
          call  delay1

          MOV  A,#38H
          CALL  WCOM
          call  delay1
          MOV  A,#0CH        ;����ʾ����ʾ��꣬��겻��˸
          CALL  WCOM
          call  delay1
          MOV  A,#01H        ;��� LCD ��ʾ��
          CALL  WCOM
          call  delay1
          RET
;==================================================
CLR_LINE1:                   ;���LCD�ĵ�һ���ַ�
          MOV  A,#80H        ;���� LCD �ĵ�һ�е�ַ
          CALL  WCOM         ;
          MOV  R0,#24        ;���ü���ֵ
    C1:   MOV  A,#' '        ;����ո����LCD
          CALL  WDATA        ;����ַ���LCD
          DJNZ  R0,C1        ;��������
          RET
;==================================================
LCD_PRINT:       ;��LCD�ĵ�һ�л�ڶ�����ʾ�ַ�

          CJNE  A,#1,LINE2  ;�ж��Ƿ�Ϊ��һ��
  LINE1:  MOV  A,#80H       ;���� LCD �ĵ�һ�е�ַ
          CALL  WCOM        ;д������
          CALL  CLR_LINE    ;��������ַ�����
          MOV  A,#80H       ;���� LCD �ĵ�һ�е�ַ
          CALL  WCOM        ;д������
          JMP  FILL

  LINE2:  MOV  A,#0C0H      ;���� LCD �ĵڶ��е�ַ
          CALL  WCOM        ;д������
          CALL  CLR_LINE    ;��������ַ�����
          MOV  A,#0C0H      ;���� LCD �ĵڶ��е�ַ
          CALL  WCOM
  FILL:   CLR  A            ;�����ַ�
          MOVC  A,@A+DPTR   ;����Ϣ��ȡ���ַ�
          CJNE  A,#0,LC1    ;�ж��Ƿ�Ϊ������
          RET
  LC1:    CALL  WDATA       ;д������
          INC  DPTR         ;ָ���1
          JMP  FILL         ;���������ַ�
          RET
;=========================================
CLR_LINE:                  ;������� LCD ���ַ�
          MOV  R0,#24
   CL1:   MOV  A,#' '
          CALL  WDATA
          DJNZ  R0,CL1
          RET
   DE:    MOV  R7,#250
          DJNZ  R7,$
          RET
;============================================
WCOM:                     ;��8λ���Ʒ�ʽ������д��LCD
          MOV  P0,A       ;д������
          CLR LCD_RS      ;RS=L,RW=L,D0-D7=ָ���룬E=������
          CLR LCD_RW
          SETB LCD_EN
          ACALL DELAY1        
          CLR LCD_EN
          RET
;=============================================
WDATA:                    ;��8λ���Ʒ�ʽ������д��LCD
          MOV  P0,A       ;д������
          SETB  LCD_RS        
          CLR  LCD_RW
          SETB  LCD_EN        
          CALL  DE
          CLR  LCD_EN
          CALL  DE
          RET
;=============================================
;PRINT A CHAR ON LINE 1
;A=ASC DATA, B=LINE X POS
;==============================================
LCDP1:                    ;��LCD�ĵ�һ����ʾ�ַ�
         PUSH  ACC        ;
         MOV  A,B         ;������ʾ��ַ
         ADD  A,#80H      ;����LCD�ĵ�һ�е�ַ
         CALL  WCOM       ;д������
         POP  ACC         ;�ɶ�ջȡ��A
         CALL  WDATA      ;д������
         RET

;==============================================
BEEP_BL:
         MOV  R6,#100
 BL2:    CALL  DEX1
         CPL  BEEP
         DJNZ  R6,BL2
         MOV  R5,#10
         CALL  DELAY
         RET
 DEX1:   MOV  R7,#180
 DE2:    NOP
         DJNZ  R7,DE2
         RET
DELAY:                    ;(R5)*��ʱ10MS
         MOV  R6,#50
 DL1:    MOV  R7,#100
         DJNZ  R7,$
         DJNZ  R6,DL1
         DJNZ  R5,DELAY
         RET

DELAY1:                    ;��ʱ5MS
         MOV  R6,#25
 DL2:    MOV  R7,#100
         DJNZ  R7,$
         DJNZ  R6,DL2
         RET
;================================================
         END