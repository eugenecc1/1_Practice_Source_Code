/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第11章                 */
/* project: display                */
/* outline: PatbltとBitbltのテスト */

#include <stdio.h>
#include "xparameters.h"
#include "xgpio.h"
#include "xil_cache.h"
#include "xpatblt.h"
#include "xbitblt.h"

/* GPIOのチャネル（１始まり） */
#define DISPADDR 1
#define DISPON   2
#define VBLANK   1
#define CLRVBLNK 2

/* サイズ、先頭アドレス */
#define XSIZE 640
#define YSIZE 480
#define WIDTH  320
#define HEIGHT 240
#define VRAM 0x10000000     /* page 0 */
#define TEX  0x1012c000     /* page 1 */

/* 読み出し元と書き込み先のオフセットアドレス */
#define SRC0 (  0 +   0 * XSIZE)*4
#define SRC1 (320 +   0 * XSIZE)*4
#define DST0 ( 80 +  60 * XSIZE)*4
#define DST1 (240 + 180 * XSIZE)*4

/* インスタンス変数 */
XGpio GpioAddrOn, GpioBlank;
XPatblt PatInstance;
XBitblt BitInstance;

/* VBLANK待ち */
void wait_vblank(void) {
    XGpio_DiscreteWrite(&GpioBlank, CLRVBLNK, 1);
    XGpio_DiscreteWrite(&GpioBlank, CLRVBLNK, 0);
    while (XGpio_DiscreteRead(&GpioBlank, VBLANK)==0);
}

/* patblt_ipを制御してオリジナルのpatblt関数を再現 */
void patblt( int xpos, int ypos, int width, int height, int color ) {
    XPatblt_Set_xpos(&PatInstance, xpos);
    XPatblt_Set_ypos(&PatInstance, ypos);
    XPatblt_Set_width(&PatInstance, width);
    XPatblt_Set_height(&PatInstance, height);
    XPatblt_Set_color(&PatInstance, color);
    XPatblt_Start(&PatInstance);
    while (XPatblt_IsDone(&PatInstance)==0);
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

int main()
{
    int Status;

    /* GPIO_0（表示アドレス、表示ON/OFF）の初期化 */
    Status = XGpio_Initialize(&GpioAddrOn, XPAR_GPIO_0_DEVICE_ID);
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
    XGpio_DiscreteWrite(&GpioAddrOn, DISPADDR, VRAM);
    XGpio_DiscreteWrite(&GpioAddrOn, DISPON, 1);

    /* Patbltの初期化 */
    Status = XPatblt_Initialize(&PatInstance, XPAR_PATBLT_0_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    XPatblt_Set_dstout(&PatInstance, VRAM);

    /* Bitbltの初期化 */
    Status = XBitblt_Initialize(&BitInstance, XPAR_BITBLT_0_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* 画面クリア */ 
    patblt(  0,   0, 640, 480, 0);  /* ★この行にブレークポイントを置く★ */

    /* Patbltのテストベンチと同じ内容で描画 */
    patblt(  0,   0, 320, 240, 0x00ff0000);
    patblt(160, 120, 320, 240, 0x0000ff00);
    patblt(320, 240, 320, 240, 0x000000ff);

    /* 画面クリア */ 
    patblt(  0,   0, 640, 480, 0);  /* ★この行にブレークポイントを置く★ */

    /* Bitbltのテストベンチと同じ内容で描画 */

    /* テクスチャ画面左上に赤青の箱を書く */
    XPatblt_Set_dstout(&PatInstance, TEX+SRC0);
    patblt(   0, 0, WIDTH, HEIGHT, 0x00ff0000);
    XPatblt_Set_dstout(&PatInstance, TEX+SRC1);
    patblt(   0, 0, WIDTH, HEIGHT, 0x000000ff);

    /* テクスチャ1個目書き込み */
    bitblt(TEX+SRC0, VRAM+DST0, VRAM+DST0, 255, WIDTH, HEIGHT);

    /* テクスチャ2個目と背景を読み込み画素間演算 */
    bitblt(TEX+SRC1, VRAM+DST1, VRAM+DST1, 128, WIDTH, HEIGHT);

    /* 表示をオフして終了 */
    wait_vblank();    /* ★この行にブレークポイント★ */
    XGpio_DiscreteWrite(&GpioAddrOn, DISPON, 0);

    return 0;
}
