/*************************
*bmp.c�ļ�
*************************/
#include "bmp.h"

/*************************

*fbp��ӳ���ڴ���ʼ��ַ
*scrinfo����Ļ��Ϣ�ṹ��
*bmpname��.bmpλͼ�ļ���

*************************/
int show_photo(const char *fbp, struct fb_var_screeninfo *scrinfo, const char *bmpname)
{
����if(NULL == fbp || NULL == scrinfo || NULL == bmpname)
��������return -1;

����int line_x = 0, line_y = 0;
����unsigned long tmp = 0;
����int xres = scrinfo->xres_virtual;��������//��Ļ�����⣩
����int bits_per_pixel = scrinfo->bits_per_pixel;����//��Ļλ��
����BitMapFileHeader FileHead;
����BitMapInfoHeader InfoHead;
����RgbQuad rgb;��������

����unsigned long location = 0;

����//��.bmp�ļ�
����FILE *fb = fopen(bmpname, "rb");
����if (fb == NULL)
����{
��������printf("fopen bmp error\r\n");
��������return -1;
����}

����//���ļ���Ϣ
����if (1 != fread( &FileHead, sizeof(BitMapFileHeader),1, fb))
����{
��������printf("read BitMapFileHeader error!\n");
��������fclose(fb);
��������return -1;
����}
����if (memcmp(FileHead.bfType, "BM", 2) != 0)
����{
��������printf("it's not a BMP file\n");
��������fclose(fb);
��������return -1;
����}
����
����//��λͼ��Ϣ
����if (1 != fread( (char *)&InfoHead, sizeof(BitMapInfoHeader),1, fb))
����{
��������printf("read BitMapInfoHeader error!\n");
��������fclose(fb);
��������return -1;
����}
����
����//��ת��������
����fseek(fb, FileHead.bfOffBits, SEEK_SET);
����
����int len = InfoHead.biBitCount / 8;    //ԭͼһ������ռ���ֽ�
����int bits_len = bits_per_pixel / 8;    //��Ļһ������ռ���ֽ�

//ѭ����ʾ
����while(!feof(fb))
����{
��������tmp = 0;
��������rgb.Reserved = 0xFF;
����
��������if (len != fread((char *)&rgb, 1, len, fb))
������������break;
����
��������//�����������ӳ���ڴ���ʼ��ַ��ƫ����
��������location = line_x * bits_len + (InfoHead.biHeight - line_y - 1) * xres * bits_len;
����
��������tmp |= rgb.Reserved << 24 | rgb.Red << 16 | rgb.Green << 8 | rgb.Blue;
����
��������*((unsigned long *)(fbp + location)) = tmp;    
����
��������line_x++;    
��������if (line_x == InfoHead.biWidth )
��������{
������������line_x = 0;
������������line_y++;
������������if(line_y == InfoHead.biHeight)    
����������������break;    
��������}    
����}
����
����fclose(fb);

����return 0;
}
