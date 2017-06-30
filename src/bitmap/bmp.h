/*************************
*bmp.h�ļ�
*************************/

#ifndef __BMP_H__
#define __BMP_H__

#include <unistd.h>
#include <stdio.h> 
#include <stdlib.h>    
#include <fcntl.h>
#include <string.h>
#include <linux/fb.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <arpa/inet.h>

//�ļ�ͷ�ṹ��
typedef struct 
{ 
  unsigned char bfType[2];    //�ļ�����
  unsigned long bfSize;     //λͼ��С
  unsigned short bfReserved1;  //λ0 
  unsigned short bfReserved2;  //λ0
  unsigned long bfOffBits;    //������ƫ����
} __attribute__((packed)) BitMapFileHeader;   //ʹ���������Ż������СΪ14�ֽ� 

//��Ϣͷ�ṹ��
typedef struct 
{ 
  unsigned long biSize;          // BitMapFileHeader �ֽ���
  long biWidth;                 //λͼ��� 
  long biHeight;              //λͼ�߶ȣ���λ���򣬷�֮Ϊ��ͼ 
  unsigned short biPlanes;        //ΪĿ���豸˵��λ��������ֵ�����Ǳ���Ϊ1
  unsigned short biBitCount;        //˵��������/���أ�Ϊ1��4��8��16��24����32�� 
  unsigned long biCompression;       //ͼ������ѹ��������û��ѹ�������ͣ�BI_RGB 
  unsigned long biSizeImage;      //˵��ͼ��Ĵ�С�����ֽ�Ϊ��λ 
  long biXPelsPerMeter;           //˵��ˮƽ�ֱ��� 
  long biYPelsPerMeter;        //˵����ֱ�ֱ��� 
  unsigned long biClrUsed;       //˵��λͼʵ��ʹ�õĲ�ɫ���е���ɫ������
  unsigned long biClrImportant;    //��ͼ����ʾ����ҪӰ�����������0����Ҫ�� 
} __attribute__((packed)) BitMapInfoHeader; 

//���ص�ṹ��
typedef struct 
{ 
  unsigned char Blue;      //����ɫ����ɫ���� 
  unsigned char Green;     //����ɫ����ɫ���� 
  unsigned char Red;          //����ɫ�ĺ�ɫ���� 
  unsigned char Reserved;    //����ֵ�����ȣ�   
} __attribute__((packed)) RgbQuad;

int show_photo(const char *fbp, struct fb_var_screeninfo *scrinfo, const char *bmpname);

#endif //__BMP_H__
