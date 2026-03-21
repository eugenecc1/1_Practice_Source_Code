/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第11章                     */
/* project: display                    */
/* outline: フェードインアウト、ワイプ */

#include <stdio.h>
#include "ff.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "xgpio.h"
#include "xbitblt.h"

/* GPIOのチャネル（１始まり） */
#define DISPADDR 1
#define DISPON   2
#define VBLANK   1
#define CLRVBLNK 2

/* サイズ */
#define XSIZE 640
#define YSIZE 480

int fileread( char *, int );

/* インスタンス変数 */
XGpio GpioAddrOn, GpioBlank;
XBitblt BitInstance;

/* VBLANK待ち */
void wait_vblank(void) {
    XGpio_DiscreteWrite(&GpioBlank, CLRVBLNK, 1);
    XGpio_DiscreteWrite(&GpioBlank, CLRVBLNK, 0);
    while (XGpio_DiscreteRead(&GpioBlank, VBLANK)==0);
}

/* bitblt_ipを制御してオリジナルのbitblt関数を再現 */
void bitblt( int srcin, int dstin, int dstout,
             int alpha, int width, int height ) {
    XBitblt_Set_srcin(&BitInstance, srcin);
    XBitblt_Set_dstin(&BitInstance, dstin);
    XBitblt_Set_dstout(&BitInstance, dstout);
    XBitblt_Set_alpha(&BitInstance, alpha);
    XBitblt_Set_width(&BitInstance, width);
    XBitblt_Set_height(&BitInstance, height);
    XBitblt_Start(&BitInstance);
    while (XBitblt_IsDone(&BitInstance)==0);
}

/* ページアドレス算出 */
int get_addr( int page ) {
    return 0x10000000 + XSIZE*YSIZE*4*page;
}

int main()
{
    /* GPIO_0（表示アドレス、表示ON/OFF）の初期化 */
    int Status = XGpio_Initialize(&GpioAddrOn, XPAR_GPIO_0_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    XGpio_SetDataDirection(&GpioAddrOn, DISPADDR, 0);
    XGpio_SetDataDirection(&GpioAddrOn, DISPON,   0);

    /* GPIO_1（VBLANK関連）の初期化 */
    Status = XGpio_Initialize(&GpioBlank, XPAR_GPIO_1_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    XGpio_SetDataDirection(&GpioBlank, VBLANK,   1);
    XGpio_SetDataDirection(&GpioBlank, CLRVBLNK, 0);

    /* 表示ON */
    wait_vblank();
    XGpio_DiscreteWrite(&GpioAddrOn, DISPADDR, get_addr(0));
    XGpio_DiscreteWrite(&GpioAddrOn, DISPON, 1);

    /* Bitbltの初期化 */
    Status = XBitblt_Initialize(&BitInstance, XPAR_BITBLT_0_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* 1枚目画像をページ2に読み込む */
    fileread("funamori.raw", 2);

    /* 2枚目画像をページ3に読み込む */
    fileread("FPGA_boards.raw", 3);

    while(1) {
        /* フェードイン/アウトを4回繰り返す */
        for (int i=0; i<4; i++) {
            for(int alpha=0; alpha<512; alpha++) {
                wait_vblank();
                bitblt(get_addr(2), get_addr(3), get_addr(0),
                    (alpha<256 ? alpha: 511-alpha), XSIZE, YSIZE);
            }
        }
        /* 左右のワイプを4回繰り返す */
        for (int i=0; i<4; i++) {
            for(int cnt=0; cnt<XSIZE*2; cnt+=4) {
                wait_vblank();
                int x = (cnt<XSIZE ? cnt: XSIZE*2-cnt);
                bitblt(get_addr(2), get_addr(3), get_addr(0), 255, x, YSIZE);
                bitblt(get_addr(2), get_addr(3)+x*4, get_addr(0)+x*4,
                                                          0, XSIZE-x, YSIZE);
            }
        }
    }

    return 0;
}

/* 画像ファイルの読み込み */
int fileread( char *filename, int page )
{
    FIL fil;
    FATFS fatfs;
    FRESULT Res;
    UINT NumBytesRead;
    u32 FileSize = 9*1024;
    TCHAR *Path = "0:/";
    unsigned char buff[9300], r, g, b;
    int i, blk=0;
    unsigned int *VRAM = (unsigned int *)get_addr(page);

    xil_printf("file name = %s\n", filename);
    Res = f_mount(&fatfs, Path, 0);
    if (Res != FR_OK) {
        xil_printf("ERROR: f_mount\n");
        return XST_FAILURE;
    }

    Res = f_open(&fil, filename, FA_READ);
    if (Res) {
        xil_printf("ERROR: f_open\n");
        return XST_FAILURE;
    }

    Xil_DCacheDisable(); /* キャッシュ無効 */
    while(1) {
        Res = f_read(&fil, buff, FileSize, &NumBytesRead);
        if (Res) {
            xil_printf("ERROR: f_read\n");
            return XST_FAILURE;
        }
        for ( i=0; i<NumBytesRead; i+=3 ) {
            r = buff[i]; g = buff[i+1]; b = buff[i+2];
            VRAM[i/3 + blk] = (r<<16) | (g<<8) | b;
        }
        if ( NumBytesRead<FileSize )
            break;
        else
            blk += NumBytesRead/3;
    }
    f_close(&fil);
    Xil_DCacheEnable(); /* キャッシュ有効 */
    return XST_SUCCESS;
}
