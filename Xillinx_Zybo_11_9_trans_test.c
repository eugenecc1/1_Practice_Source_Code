/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第11章課題       */
/* project: display          */
/* outline: 透過画像のテスト */

#include <stdio.h>
#include <stdlib.h>
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

#define TEX_WIDTH  320
#define TEX_HEIGHT 100

int fileread( char *, int );
int fileread_RGBA( char *, int, int, int );

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
             int alpha, int width, int height, int transparent ) {
    XBitblt_Set_srcin(&BitInstance, srcin);
    XBitblt_Set_dstin(&BitInstance, dstin);
    XBitblt_Set_dstout(&BitInstance, dstout);
    XBitblt_Set_alpha(&BitInstance, alpha);
    XBitblt_Set_width(&BitInstance, width);
    XBitblt_Set_height(&BitInstance, height);
    XBitblt_Set_transparent(&BitInstance, transparent);
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

    /* 画像をページ2に読み込む */
    fileread("FPGA_boards.raw", 2);

    /* α付きテクスチャをページ3に読み込む */
    fileread_RGBA("fpga_320_100_RGBA.raw", 3, TEX_WIDTH, TEX_HEIGHT);

    while(1) {
        /* 1/2秒待つ */
        for(int i=0; i<40; i++) wait_vblank();
        /* 背景画像を転送 */
        bitblt(get_addr(2), get_addr(0), get_addr(0), 255, XSIZE, YSIZE, 0);
        /* ランダムな位置にテクスチャを透過処理付きで転送 */
        int xpos = rand() % (XSIZE-TEX_WIDTH);
        int ypos = rand() % (YSIZE-TEX_HEIGHT);
        bitblt(get_addr(3), get_addr(0) + (xpos + ypos*XSIZE)*4,
            get_addr(0) + (xpos + ypos*XSIZE)*4, 255, TEX_WIDTH, TEX_HEIGHT, 1);

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


/* α付き画像ファイルの読み込み */
int fileread_RGBA( char *filename, int page, int width, int height )
{
    FIL fil;
    FATFS fatfs;
    FRESULT Res;
    UINT NumBytesRead;
    u32 FileSize = 8*1024;
    TCHAR *Path = "0:/";
    unsigned char buff[8200], r, g, b, a;
    int i;
    unsigned int *VRAM = (unsigned int *)get_addr(page);

    unsigned char pic[XSIZE*YSIZE*4]; /* VGA１画面分の配列！！ */
    
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
    int j = 0;
    while(1) {
        Res = f_read(&fil, buff, FileSize, &NumBytesRead);
        if (Res) {
            xil_printf("ERROR: f_read\n");
            return XST_FAILURE;
        }
        for ( i=0; i<NumBytesRead; i++ ) {
            pic[j++] = buff[i];
        }
        if ( NumBytesRead<FileSize )
            break;
    }
    f_close(&fil);
    Xil_DCacheEnable(); /* キャッシュ有効 */

    i = 0;
    for(int y=0; y<height; y++)
        for(int x=0; x<width; x++) {
            r = pic[i]; g = pic[i+1]; b = pic[i+2]; a = pic[i+3];
            VRAM[x + y*XSIZE] = (a<<24) | (r<<16) | (g<<8) | b;
            i += 4;
        }
    Xil_DCacheFlush();
    return XST_SUCCESS;
}
