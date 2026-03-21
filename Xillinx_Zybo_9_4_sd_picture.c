/* Copyright(C) 2016 Cobac.Net All Rights Reserved. */
/* chapter: 第9章課題                         */
/* project: display                           */
/* outline: SDカードのRAW画像を読み出して表示 */

#include "xparameters.h"
#include "xsdps.h"
#include "xil_printf.h"
#include "ff.h"
#include "xil_cache.h"

#define GPIO_00_CTRL (*(volatile unsigned int *) (XPAR_AXI_GPIO_0_BASEADDR +0x04))
#define GPIO_01_CTRL (*(volatile unsigned int *) (XPAR_AXI_GPIO_0_BASEADDR +0x0C))
#define GPIO_10_CTRL (*(volatile unsigned int *) (XPAR_AXI_GPIO_1_BASEADDR +0x04))
#define GPIO_11_CTRL (*(volatile unsigned int *) (XPAR_AXI_GPIO_1_BASEADDR +0x0C))

#define DISPADDR (*(volatile unsigned int *) (XPAR_AXI_GPIO_0_BASEADDR +0x00))
#define DISPON   (*(volatile unsigned int *) (XPAR_AXI_GPIO_0_BASEADDR +0x08))
#define VBLANK   (*(volatile unsigned int *) (XPAR_AXI_GPIO_1_BASEADDR +0x00))
#define CLRVBLNK (*(volatile unsigned int *) (XPAR_AXI_GPIO_1_BASEADDR +0x08))

#define XSIZE 640
#define YSIZE 480
#define VRAM ((volatile unsigned int *) 0x10000000)

void wait_vblank(void) {
    CLRVBLNK = 1;
    CLRVBLNK = 0;
    while (VBLANK==0);
}

int main()
{
    FIL fil;
    FATFS fatfs;
    char FileName[32] = "funamori.raw";

    FRESULT Res;
    UINT NumBytesRead;
    u32 FileSize = 9*1024;
    TCHAR *Path = "0:/";
    unsigned char buff[9300], r, g, b;
    unsigned int pic;
    int i, blk=0;

    Res = f_mount(&fatfs, Path, 0);
    if (Res != FR_OK) {
        xil_printf("ERROR: f_mount\n");
        return XST_FAILURE;
    }

    Res = f_open(&fil, FileName, FA_READ);
    if (Res) {
        xil_printf("ERROR: f_open\n");
        return XST_FAILURE;
    }

    while(1) {
        Res = f_read(&fil, buff, FileSize, &NumBytesRead);
        if (Res) {
            xil_printf("ERROR: f_read\n");
            return XST_FAILURE;
        }
        for ( i=0; i<NumBytesRead; i+=3 ) {
            r = buff[i]; g = buff[i+1]; b = buff[i+2];
            pic = (r<<16) | (g<<8) | b;
            VRAM[i/3 + blk] = pic;
        }
        if ( NumBytesRead<FileSize )
            break;
        else
            blk += NumBytesRead/3;
    }
    Xil_DCacheFlush();

    GPIO_00_CTRL = 0;
    GPIO_01_CTRL = 0;
    GPIO_10_CTRL = 1;
    GPIO_11_CTRL = 0;

    wait_vblank();
    DISPADDR = 0x10000000;
    DISPON = 1;

    /* 表示をオフして終了 */
    wait_vblank();    /* ★この行にブレークポイントを置く★ */
    DISPON = 0;

    return 0;
}
