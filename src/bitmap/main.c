/*************************
*main.c文件
*************************/
#include "bmp.h"

int main()
{
  int devfb, filefb;
  struct fb_var_screeninfo scrinfo;
  struct fb_fix_screeninfo fix;
  unsigned long screensize;
  char *fbp ;
  char bmpname[20] = {0};

  //打开设备文件
  devfb = open("/dev/fb0", O_RDWR);
  if(!devfb)
  {
    printf("devfb open error!\r\n");
    return -1;
  }
  //printf("devfb open OK! %d\r\n", devfb);

  //获取屏幕信息

  //若屏幕显示区域大小不合适，可用ioctl(devfb, FBIOPUT_VSCREENINFO, &scrinfo)设置
  if(ioctl(devfb, FBIOGET_VSCREENINFO, &scrinfo))
  {
    printf("get screen infomation error!\r\n");
    return -1;
  }
  ioctl(devfb, FBIOGET_FSCREENINFO, &fix); //显示缓存信息（framebuff）

  //printf(".xres=%d, .yres=%d, .bit=%d\r\n",scrinfo.xres, scrinfo.yres, scrinfo.bits_per_pixel);

  //printf(".xres_virtual=%d, .yres_virtual=%d\r\n",scrinfo.xres_virtual, scrinfo.yres_virtual);

  if(32 != scrinfo.bits_per_pixel)
  {
    printf("screen infomation.bits error!\r\n");
    return -1;
  }


  //计算需要的映射内存大小
  screensize = scrinfo.xres_virtual * scrinfo.yres_virtual * scrinfo.bits_per_pixel / 8;
  printf("screensize=%lu! %lu\r\n", screensize, fix.smem_len);

  // //内存映射
  // fbp = (char *)mmap(NULL, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, devfb, 0);

  fbp = (char*)mmap(NULL, fix.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, devfb, 0); //系统调用mmap()用来实现内存映射IO    

  if(-1 == (int)fbp)
  {
    printf("mmap error!\r\n");
    return -1;
  }
  
  scanf("%s", bmpname);
  
  //显示图片
  show_photo(fbp, &scrinfo, bmpname);


  //取消映射，关闭文件
  munmap(fbp, screensize);
  close(devfb);

  return 0;
}

// *说明：1.图片是24位或32位bmp图
//     2.屏幕是32位屏幕
//     3.不同的设备，可能设备文件不同
//     4.需要在root用户下执行
