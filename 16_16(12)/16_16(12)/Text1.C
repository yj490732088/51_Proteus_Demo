#include<AT89X52.H>
sbit ST=P3^5;
sbit E1=P3^4;
sbit MR=P3^7;
char cashe[12];
char code wd[12][16]={
{0xFE,0xFE,0xFE,0xFE,0xFE,0xDE,0xDE,0xDE,0xDE,0xDE,0xDE,0xDE,0xDE,0x80,0xDF,0xFF},
{0xFF,0xFF,0xFF,0xFF,0xFF,0xFB,0xFB,0xFB,0xFB,0xFB,0xFB,0xFB,0xFB,0x03,0xFB,0xFF},/*"山",0*/

{0xFD,0xFD,0x80,0xFB,0xF7,0xF7,0xEF,0xE0,0xFF,0xF7,0xF3,0xE7,0xEF,0xDD,0xFE,0xFF},
{0xFF,0xFF,0x03,0xFF,0x7F,0x7F,0x7F,0x07,0x7F,0x5F,0x6F,0x77,0x73,0x7B,0x7F,0x7F},/*"东",1*/

{0xF9,0x87,0xF7,0xF7,0x01,0xE7,0xE3,0xD5,0xD7,0xB7,0x74,0xF7,0xF7,0xF7,0xF7,0xF7},
{0xF7,0x77,0xB7,0xB7,0xF7,0x77,0xB7,0xB7,0xF1,0x87,0x77,0xF7,0xF7,0xF7,0xF7,0xF7},/*"科",2*/

{0xEF,0xEF,0xEF,0x02,0xEF,0xEB,0xE6,0xCE,0x2F,0xEF,0xEF,0xEF,0xEF,0xEE,0xA9,0xDF},
{0xDF,0xDF,0xDF,0x01,0xDF,0xDF,0x03,0xF7,0x77,0x6F,0x9F,0x9F,0x6F,0xF1,0xFB,0xFF},/*"技",3*/

{0xFE,0xFE,0xFE,0xFE,0xFE,0x00,0xFE,0xFD,0xFD,0xFD,0xFB,0xFB,0xF7,0xEF,0xDF,0xBF},
{0xFF,0xFF,0xFF,0xFF,0xFF,0x01,0xFF,0x7F,0x7F,0xBF,0xBF,0xDF,0xEF,0xE7,0xF1,0xFB},/*"大",4*/

{0xFE,0xEF,0xF3,0xF7,0x80,0xBF,0x70,0xFF,0xFF,0x80,0xFF,0xFF,0xFF,0xFF,0xFD,0xFE},
{0xF7,0x73,0x37,0x6F,0x01,0xFB,0x17,0xBF,0x7F,0x01,0x7F,0x7F,0x7F,0x7F,0x7F,0xFF},/*"学",5*/

};


void del(int i)//============================//延时程序
{while(i--);}

aline()	////=======================发送一行的显示程序
{
char i=0;
TI=0;
for(i=0;i<12;i++)
{SBUF=cashe[i];while(~TI);TI=0;} //将缓存中的信息转存入595的存储器中，到此不显示
}



main()
{
int m=0,n=0;
	TI=0;
	SM0=0;
	SM1=0;
E1=0;
while(1)
for(m=0;m<16;m++)      //共有16行  循环16次显示这16行  串行的595送出行的数据
	{					//由74hc154选中要显示的行

	for(n=0;n<12;n++)         //这个for循环用来向缓存数组中装载要显示的内容
		{cashe[11-n]=wd[n][m];}  //将第m个字的第n行信息装载  ，因为595串接 数据第一个进去的会在最后一个595中，最后进去的会在第一个595中
    aline();     //将缓存中的一行信息载入595缓存中
	ST=0;ST=1; //595产生上升沿 输出595锁存的数据
	P2=m;  //选中要显示的行输出数据
      
	del(100);//延时一段时间，以造成视觉暂存效应

	  }

}












