#include <REG52.H>
#include "SoundPlay.h"

unsigned char RunMode;

//**********************************System Fuction*************************************************
void Delay1ms(unsigned int count)
{
	unsigned int i,j;
	for(i=0;i<count;i++)
	for(j=0;j<120;j++);
}

unsigned char code LEDDisplayCode[] = { 0xC0,0xF9,0xA4,0xB0,0x99,0x92,0x82,0xF8,	//0~7
                          				0x80,0x90,0x88,0x83,0xC6,0xA1,0x86,0x8E,0xFF};

void Display(unsigned char Value)
{
	P3 = LEDDisplayCode[Value];
}

void LEDFlash(unsigned char Count)
{
	unsigned char i;
	bit Flag;
	for(i = 0; i<Count;i++)
	{
		Flag = !Flag;
		if(Flag)
			Display(RunMode);
		else
			Display(0x10);
		Delay1ms(100);
	}
	Display(RunMode);
}

unsigned char GetKey(void)
{
	unsigned char KeyTemp,CheckValue,Key = 0x00;
	CheckValue = P2&0x32;
	if(CheckValue==0x32)
		return 0x00;
	
	Delay1ms(10);
	KeyTemp = P2&0x32;
	if(KeyTemp==CheckValue)
		return 0x00;

	if(!(CheckValue&0x02))
		Key|=0x01;
	if(!(CheckValue&0x10))
		Key|=0x02;
	if(!(CheckValue&0x20))
		Key|=0x04;
	return Key;
}

unsigned int Timer0Count,SystemSpeed,SystemSpeedIndex;
void InitialTimer2(void)
{
	T2CON  = 0x00;			//16 Bit Auto-Reload Mode
 	TH2 = RCAP2H = 0xFC;  	//��װֵ,��ʼֵ	TL2 = RCAP2L = 0x18;
	ET2=1;					//��ʱ�� 2 �ж�����
	TR2 = 1;				//��ʱ�� 2 ����
	EA=1;
}

unsigned int code SpeedCode[]={   1,   2,   3,   5,   8,  10,  14,  17,  20,  30,
							     40,  50,  60,  70,  80,  90, 100, 120, 140, 160,
								180, 200, 300, 400, 500, 600, 700, 800, 900,1000};//30
void SetSpeed(unsigned char Speed)
{
	SystemSpeed =SpeedCode[Speed];
}

void LEDShow(unsigned int LEDStatus)
{
	P1 = ~(LEDStatus&0x00FF);
	P0 = ~((LEDStatus>>8)&0x00FF);
}

void InitialCPU(void)
{
	RunMode = 0x00;
	Timer0Count = 0;
	SystemSpeedIndex = 9;

	P1 = 0x00;
	P0 = 0x00;
	P2 = 0xFF;
	P3 = 0x00;
	Delay1ms(500);
	P1 = 0xFF;
	P0 = 0xFF;
	P2 = 0xFF;
	P3 = 0xFF;
	SetSpeed(SystemSpeedIndex);
	Display(RunMode);
}

//Mode 0
unsigned int LEDIndex = 0;
bit LEDDirection = 1,LEDFlag = 1;
void Mode_0(void)
{
	LEDShow(0x0001<<LEDIndex);
	LEDIndex = (LEDIndex+1)%16;
}
//Mode 1
void Mode_1(void)
{
	LEDShow(0x8000>>LEDIndex);
	LEDIndex = (LEDIndex+1)%16;
}
//Mode 2
void Mode_2(void)
{
	if(LEDDirection)
		LEDShow(0x0001<<LEDIndex);
	else
		LEDShow(0x8000>>LEDIndex);
	if(LEDIndex==15)
		LEDDirection = !LEDDirection;
   LEDIndex = (LEDIndex+1)%16;
}
//Mode 3
void Mode_3(void)
{
	if(LEDDirection)
		LEDShow(~(0x0001<<LEDIndex));
	else
		LEDShow(~(0x8000>>LEDIndex));
	if(LEDIndex==15)
		LEDDirection = !LEDDirection;
   LEDIndex = (LEDIndex+1)%16;
}

//Mode 4
void Mode_4(void)
{
	if(LEDDirection)
	{
		if(LEDFlag)
			LEDShow(0xFFFE<<LEDIndex);
	   	else
			LEDShow(~(0x7FFF>>LEDIndex));
	}
	else
	{
		if(LEDFlag)
			LEDShow(0x7FFF>>LEDIndex);
		else
			LEDShow(~(0xFFFE<<LEDIndex));
	}
	if(LEDIndex==15)
	{
		LEDDirection = !LEDDirection;
		if(LEDDirection)	LEDFlag = !LEDFlag;
	}
   	LEDIndex = (LEDIndex+1)%16;
}

//Mode 5
void Mode_5(void)
{
	if(LEDDirection)
		LEDShow(0x000F<<LEDIndex);
	else
		LEDShow(0xF000>>LEDIndex);
	if(LEDIndex==15)
		LEDDirection = !LEDDirection;
    LEDIndex = (LEDIndex+1)%16;
}

//Mode 6
void Mode_6(void)
{
	if(LEDDirection)
		LEDShow(~(0x000F<<LEDIndex));
	else
		LEDShow(~(0xF000>>LEDIndex));
	if(LEDIndex==15)
		LEDDirection = !LEDDirection;
   	LEDIndex = (LEDIndex+1)%16;
}

//Mode 7
void Mode_7(void)
{
	if(LEDDirection)
		LEDShow(0x003F<<LEDIndex);
	else
		LEDShow(0xFC00>>LEDIndex);
	if(LEDIndex==9)
		LEDDirection = !LEDDirection;
    LEDIndex = (LEDIndex+1)%10;
}

//Mode 8
void Mode_8(void)
{
	LEDShow(++LEDIndex);
}

void Timer0EventRun(void)
{
	if(RunMode==0x00)
	{
		Mode_0();	
	}
	else if(RunMode ==0x01)
	{
		Mode_1();
	}
	else if(RunMode ==0x02)
	{
		Mode_2();
	}
	else if(RunMode ==0x03)
	{
		Mode_3();
	}
	else if(RunMode ==0x04)
	{
		Mode_4();
	}
	else if(RunMode ==0x05)
	{
		Mode_5();
	}
	else if(RunMode ==0x06)
	{
		Mode_6();
	}
	else if(RunMode ==0x07)
	{
		Mode_7();
	}
	else if(RunMode ==0x08)
	{
		Mode_8();
	}
}

void Timer2(void) interrupt 5 using 3
{
	TF2 = 0; 	//�жϱ�־���( Timer2 �����������־!)
	if(++Timer0Count>=SystemSpeed)
	{
		Timer0Count = 0;
		Timer0EventRun();
   	}
}
unsigned char MusicIndex = 0;
void KeyDispose(unsigned char Key)
{
	if(Key&0x01)
	{
		LEDDirection = 1;
		LEDIndex = 0;
		LEDFlag = 1;
		RunMode = (RunMode+1)%10;
		Display(RunMode);
		if(RunMode==0x09)
			TR2 = 0;
		else
			TR2 = 1;
	}
	if(Key&0x02)
	{
		if(RunMode==0x09)
		{
			MusicIndex =(MusicIndex+MUSICNUMBER-1)%MUSICNUMBER;
		}
		else
		{
			if(SystemSpeedIndex>0)
			{
				--SystemSpeedIndex;
				SetSpeed(SystemSpeedIndex);
			}
			else
			{
				LEDFlash(6);
			}
	 	}
	}
	if(Key&0x04)
	{
		if(RunMode==0x09)
		{
			MusicIndex =(MusicIndex+1)%MUSICNUMBER;
		}
		else
		{
			if(SystemSpeedIndex<28)
			{
				++SystemSpeedIndex;
				SetSpeed(SystemSpeedIndex);
			}
			else
			{
				LEDFlash(6);
			}
	   	}
	}	
}
//*****************************Music******************************************************
//���ų���Ů��
unsigned char code Music_Girl[]={ 0x17,0x02, 0x17,0x03, 0x18,0x03, 0x19,0x02, 0x15,0x03,
                                  0x16,0x03, 0x17,0x03, 0x17,0x03, 0x17,0x03, 0x18,0x03,
                                  0x19,0x02, 0x16,0x03, 0x17,0x03, 0x18,0x02, 0x18,0x03,
                                  0x17,0x03, 0x15,0x02, 0x18,0x03, 0x17,0x03, 0x18,0x02,
                                  0x10,0x03, 0x15,0x03, 0x16,0x02, 0x15,0x03, 0x16,0x03,
                                  0x17,0x02, 0x17,0x03, 0x18,0x03, 0x19,0x02, 0x1A,0x03,
                                  0x1B,0x03, 0x1F,0x03, 0x1F,0x03, 0x17,0x03, 0x18,0x03,
                                  0x19,0x02, 0x16,0x03, 0x17,0x03, 0x18,0x03, 0x17,0x03,
                                  0x18,0x03, 0x1F,0x03, 0x1F,0x02, 0x16,0x03, 0x17,0x03,
                                  0x18,0x03, 0x17,0x03, 0x18,0x03, 0x20,0x03, 0x20,0x02,
                                  0x1F,0x03, 0x1B,0x03, 0x1F,0x66, 0x20,0x03, 0x21,0x03,
                                  0x20,0x03, 0x1F,0x03, 0x1B,0x03, 0x1F,0x66, 0x1F,0x03,
                                  0x1B,0x03, 0x19,0x03, 0x19,0x03, 0x15,0x03, 0x1A,0x66,
                                  0x1A,0x03, 0x19,0x03, 0x15,0x03, 0x15,0x03, 0x17,0x03,
                                  0x16,0x66, 0x17,0x04, 0x18,0x04, 0x18,0x03, 0x19,0x03,
                                  0x1F,0x03, 0x1B,0x03, 0x1F,0x66, 0x20,0x03, 0x21,0x03,
                                  0x20,0x03, 0x1F,0x03, 0x1B,0x03, 0x1F,0x66, 0x1F,0x03,
                                  0x1B,0x03, 0x19,0x03, 0x19,0x03, 0x15,0x03, 0x1A,0x66,
                                  0x1A,0x03, 0x19,0x03, 0x19,0x03, 0x1F,0x03, 0x1B,0x03,
                                  0x1F,0x00, 0x1A,0x03, 0x1A,0x03, 0x1A,0x03, 0x1B,0x03,
                                  0x1B,0x03, 0x1A,0x03, 0x19,0x03, 0x19,0x02, 0x17,0x03,
                                  0x15,0x17, 0x15,0x03, 0x16,0x03, 0x17,0x03, 0x18,0x03,
                                  0x17,0x04, 0x18,0x0E, 0x18,0x03, 0x17,0x04, 0x18,0x0E,
                                  0x18,0x66, 0x17,0x03, 0x18,0x03, 0x17,0x03, 0x18,0x03,
                                  0x20,0x03, 0x20,0x02, 0x1F,0x03, 0x1B,0x03, 0x1F,0x66,
                                  0x20,0x03, 0x21,0x03, 0x20,0x03, 0x1F,0x03, 0x1B,0x03,
                                  0x1F,0x66, 0x1F,0x04, 0x1B,0x0E, 0x1B,0x03, 0x19,0x03,
                                  0x19,0x03, 0x15,0x03, 0x1A,0x66, 0x1A,0x03, 0x19,0x03,
                                  0x15,0x03, 0x15,0x03, 0x17,0x03, 0x16,0x66, 0x17,0x04,
                                  0x18,0x04, 0x18,0x03, 0x19,0x03, 0x1F,0x03, 0x1B,0x03,
                                  0x1F,0x66, 0x20,0x03, 0x21,0x03, 0x20,0x03, 0x1F,0x03,
                                  0x1B,0x03, 0x1F,0x66, 0x1F,0x03, 0x1B,0x03, 0x19,0x03,
                                  0x19,0x03, 0x15,0x03, 0x1A,0x66, 0x1A,0x03, 0x19,0x03,
                                  0x19,0x03, 0x1F,0x03, 0x1B,0x03, 0x1F,0x00, 0x18,0x02,
                                  0x18,0x03, 0x1A,0x03, 0x19,0x0D, 0x15,0x03, 0x15,0x02,
                                  0x18,0x66, 0x16,0x02, 0x17,0x02, 0x15,0x00, 0x00,0x00};
//ͬһ�׸�
unsigned char code Music_Same[]={ 0x0F,0x01, 0x15,0x02, 0x16,0x02, 0x17,0x66, 0x18,0x03,
                                  0x17,0x02, 0x15,0x02, 0x16,0x01, 0x15,0x02, 0x10,0x02,
                                  0x15,0x00, 0x0F,0x01, 0x15,0x02, 0x16,0x02, 0x17,0x02,
                                  0x17,0x03, 0x18,0x03, 0x19,0x02, 0x15,0x02, 0x18,0x66,
                                  0x17,0x03, 0x19,0x02, 0x16,0x03, 0x17,0x03, 0x16,0x00,
                                  0x17,0x01, 0x19,0x02, 0x1B,0x02, 0x1B,0x70, 0x1A,0x03,
                                  0x1A,0x01, 0x19,0x02, 0x19,0x03, 0x1A,0x03, 0x1B,0x02,
                                  0x1A,0x0D, 0x19,0x03, 0x17,0x00, 0x18,0x66, 0x18,0x03,
                                  0x19,0x02, 0x1A,0x02, 0x19,0x0C, 0x18,0x0D, 0x17,0x03,
                                  0x16,0x01, 0x11,0x02, 0x11,0x03, 0x10,0x03, 0x0F,0x0C,
                                  0x10,0x02, 0x15,0x00, 0x1F,0x01, 0x1A,0x01, 0x18,0x66,
                                  0x19,0x03, 0x1A,0x01, 0x1B,0x02, 0x1B,0x03, 0x1B,0x03,
                                  0x1B,0x0C, 0x1A,0x0D, 0x19,0x03, 0x17,0x00, 0x1F,0x01,
                                  0x1A,0x01, 0x18,0x66, 0x19,0x03, 0x1A,0x01, 0x10,0x02,
                                  0x10,0x03, 0x10,0x03, 0x1A,0x0C, 0x18,0x0D, 0x17,0x03,
                                  0x16,0x00, 0x0F,0x01, 0x15,0x02, 0x16,0x02, 0x17,0x70,
                                  0x18,0x03, 0x17,0x02, 0x15,0x03, 0x15,0x03, 0x16,0x66,
                                  0x16,0x03, 0x16,0x02, 0x16,0x03, 0x15,0x03, 0x10,0x02,
                                  0x10,0x01, 0x11,0x01, 0x11,0x66, 0x10,0x03, 0x0F,0x0C,
                                  0x1A,0x02, 0x19,0x02, 0x16,0x03, 0x16,0x03, 0x18,0x66,
                                  0x18,0x03, 0x18,0x02, 0x17,0x03, 0x16,0x03, 0x19,0x00,
                                  0x00,0x00 };
//��ֻ����                                  
unsigned char code Music_Two[] ={ 0x17,0x03, 0x16,0x03, 0x17,0x01, 0x16,0x03, 0x17,0x03,
                                  0x16,0x03, 0x15,0x01, 0x10,0x03, 0x15,0x03, 0x16,0x02,
                                  0x16,0x0D, 0x17,0x03, 0x16,0x03, 0x15,0x03, 0x10,0x03,
                                  0x10,0x0E, 0x15,0x04, 0x0F,0x01, 0x17,0x03, 0x16,0x03,
                                  0x17,0x01, 0x16,0x03, 0x17,0x03, 0x16,0x03, 0x15,0x01,
                                  0x10,0x03, 0x15,0x03, 0x16,0x02, 0x16,0x0D, 0x17,0x03,
                                  0x16,0x03, 0x15,0x03, 0x10,0x03, 0x15,0x03, 0x16,0x01,
                                  0x17,0x03, 0x16,0x03, 0x17,0x01, 0x16,0x03, 0x17,0x03,
                                  0x16,0x03, 0x15,0x01, 0x10,0x03, 0x15,0x03, 0x16,0x02,
                                  0x16,0x0D, 0x17,0x03, 0x16,0x03, 0x15,0x03, 0x10,0x03,
                                  0x10,0x0E, 0x15,0x04, 0x0F,0x01, 0x17,0x03, 0x19,0x03,
                                  0x19,0x01, 0x19,0x03, 0x1A,0x03, 0x19,0x03, 0x17,0x01,
                                  0x16,0x03, 0x16,0x03, 0x16,0x02, 0x16,0x0D, 0x17,0x03,
                                  0x16,0x03, 0x15,0x03, 0x10,0x03, 0x10,0x0D, 0x15,0x00,
                                  0x19,0x03, 0x19,0x03, 0x1A,0x03, 0x1F,0x03, 0x1B,0x03,
                                  0x1B,0x03, 0x1A,0x03, 0x17,0x0D, 0x16,0x03, 0x16,0x03,
                                  0x16,0x0D, 0x17,0x01, 0x17,0x03, 0x17,0x03, 0x19,0x03,
                                  0x1A,0x02, 0x1A,0x02, 0x10,0x03, 0x17,0x0D, 0x16,0x03,
                                  0x16,0x01, 0x17,0x03, 0x19,0x03, 0x19,0x03, 0x17,0x03,
                                  0x19,0x02, 0x1F,0x02, 0x1B,0x03, 0x1A,0x03, 0x1A,0x0E,
                                  0x1B,0x04, 0x17,0x02, 0x1A,0x03, 0x1A,0x03, 0x1A,0x0E,
                                  0x1B,0x04, 0x1A,0x03, 0x19,0x03, 0x17,0x03, 0x16,0x03,
                                  0x17,0x0D, 0x16,0x03, 0x17,0x03, 0x19,0x01, 0x19,0x03,
                                  0x19,0x03, 0x1A,0x03, 0x1F,0x03, 0x1B,0x03, 0x1B,0x03,
                                  0x1A,0x03, 0x17,0x0D, 0x16,0x03, 0x16,0x03, 0x16,0x03,
                                  0x17,0x01, 0x17,0x03, 0x17,0x03, 0x19,0x03, 0x1A,0x02,
                                  0x1A,0x02, 0x10,0x03, 0x17,0x0D, 0x16,0x03, 0x16,0x01,
                                  0x17,0x03, 0x19,0x03, 0x19,0x03, 0x17,0x03, 0x19,0x03,
                                  0x1F,0x02, 0x1B,0x03, 0x1A,0x03, 0x1A,0x0E, 0x1B,0x04,
                                  0x17,0x02, 0x1A,0x03, 0x1A,0x03, 0x1A,0x0E, 0x1B,0x04,
                                  0x17,0x16, 0x1A,0x03, 0x1A,0x03, 0x1A,0x0E, 0x1B,0x04,
                                  0x1A,0x03, 0x19,0x03, 0x17,0x03, 0x16,0x03, 0x0F,0x02,
                                  0x10,0x03, 0x15,0x00, 0x00,0x00 };
//***********************************************************************************
unsigned char * SelectMusic(unsigned char SoundIndex)
{
	unsigned char *MusicAddress = 0;
	switch (SoundIndex)
	{	
		case 0x00:
			MusicAddress = &Music_Girl[0];	//���ų���Ů��		
			break;
		case 0x01:
			MusicAddress = &Music_Same[0];	//ͬһ�׸�		
			break;
		case 0x02:
			MusicAddress = &Music_Two[0];	//��ֻ����  
			break;
		case 0x03:
			break;
		case 0x04:
			break;
		case 0x05:
			break;
		case 0x06:
			break;
		case 0x07:
			break;
		case 0x08:
			break;
		case 0x09:
			break;
		default:break;
	}
	return MusicAddress;
}

void PlayMusic(void)
{	
	Delay1ms(200);
	Play(SelectMusic(MusicIndex),0,3,360);
}
//***********************************************************************************
main()
{
	unsigned char Key;
	InitialCPU();
	InitialSound();
	InitialTimer2();

	while(1)
	{
		Key = GetKey();
		if(RunMode==0x09)
		{
			PlayMusic();
		}
		if(Key!=0x00)
		{
			KeyDispose(Key);
		}
	}
}