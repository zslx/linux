/*************************
*main.c�ļ�
*************************/
#include "bmp.h"

int main()
{
  int devfb, filefb;
  struct fb_var_screeninfo scrinfo;
  unsigned long screensize;
  char *fbp ;
  char bmpname[20] = {0};

  //���豸�ļ�
  devfb = open("/dev/fb0", O_RDWR);
  if(!devfb)
  {
    printf("devfb open error!\r\n");
    return -1;
  }
  //printf("devfb open OK! %d\r\n", devfb);
 

  //��ȡ��Ļ��Ϣ

  //����Ļ��ʾ�����С�����ʣ�����ioctl(devfb, FBIOPUT_VSCREENINFO, &scrinfo)����
  if(ioctl(devfb, FBIOGET_VSCREENINFO, &scrinfo))
  {
    printf("get screen infomation error!\r\n");
    return -1;
  }

  //printf(".xres=%d, .yres=%d, .bit=%d\r\n",scrinfo.xres, scrinfo.yres, scrinfo.bits_per_pixel);

  //printf(".xres_virtual=%d, .yres_virtual=%d\r\n",scrinfo.xres_virtual, scrinfo.yres_virtual);

  if(32 != scrinfo.bits_per_pixel)
  {
    printf("screen infomation.bits error!\r\n");
    return -1;
  }


  //������Ҫ��ӳ���ڴ��С
  screensize = scrinfo.xres_virtual * scrinfo.yres_virtual * scrinfo.bits_per_pixel / 8;
  //printf("screensize=%lu!\r\n", screensize);
  
  //�ڴ�ӳ��
  fbp = (char *)mmap(NULL, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, devfb, 0);
  if(-1 == (int)fbp)
  {
    printf("mmap error!\r\n");
    return -1;
  }
  
  scanf("%s", bmpname);
  
  //��ʾͼƬ
  show_photo(fbp, &scrinfo, bmpname);

 

  //ȡ��ӳ�䣬�ر��ļ�
  munmap(fbp, screensize);
  close(devfb);

  return 0;
}

// *˵����1.ͼƬ��24λ��32λbmpͼ
//     2.��Ļ��32λ��Ļ
//     3.��ͬ���豸�������豸�ļ���ͬ
//     4.��Ҫ��root�û���ִ��
