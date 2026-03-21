/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第9章                                   */
/* project: display                                 */
/* outline: グラフィック表示回路のテストプログラム  */

#include <stdio.h>
#include "xparameters.h"
#include "xgpio.h"
#include "xil_cache.h"

/* GPIOのチャネル（１始まり） */
#define DISPADDR 1
#define DISPON   2
#define VBLANK   1
#define CLRVBLNK 2

#define XSIZE 640
#define YSIZE 480
#define VRAM ((volatile unsigned int *) 0x10000000)

/* インスタンス変数 */
XGpio GpioAddrOn, GpioBlank;

/* VBLANK待ち */
void wait_vblank(void) {
    XGpio_DiscreteWrite(&GpioBlank, CLRVBLNK, 1);
    XGpio_DiscreteWrite(&GpioBlank, CLRVBLNK, 0);
    while (XGpio_DiscreteRead(&GpioBlank, VBLANK)==0);
}

/* 原点（xpos, ypos)、大きさ（width, height）、色（color）を指定して箱を書く */
void drawbox( int xpos, int ypos, int width, int height, int col ) {
    int x, y;

    for ( x=xpos; x<xpos+width; x++ ) {
        VRAM[ ypos*XSIZE + x ] = col;
        VRAM[ (ypos+height-1)*XSIZE + x ] = col;
    }
    for ( y=ypos; y<ypos+height; y++ ) {
        VRAM[ y*XSIZE + xpos ] = col;
        VRAM[ y*XSIZE + xpos + width -1 ] = col;
    }
}

int main()
{
    int i, Status;

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
    XGpio_DiscreteWrite(&GpioAddrOn, DISPADDR, 0x10000000);
    XGpio_DiscreteWrite(&GpioAddrOn, DISPON, 1);

    /* 画面クリア */      /* ★この行にブレークポイントを置く★ */
    for ( i=0; i<XSIZE*YSIZE; i++) {
        VRAM[i] = 0;
    }
    Xil_DCacheFlush();

    /* 枠線をいくつか引いてみる */
    drawbox(  0,   0, 640, 480, 0x00ffffff); /* ★この行にブレークポイント★ */
    drawbox( 10,  10, 200, 100, 0x00ff0000); // R
    drawbox( 40,  30, 150, 300, 0x0000ff00); // G
    drawbox(100, 150, 400, 300, 0x000000ff); // B
    Xil_DCacheFlush();

    /* 縞模様を書く */    /* ★この行にブレークポイント★ */
    for ( i=0; i<XSIZE*YSIZE; i++) {
        VRAM[i] = i;
    }
    Xil_DCacheFlush();

    /* 表示をオフして終了 */
    wait_vblank();    /* ★この行にブレークポイント★ */
    XGpio_DiscreteWrite(&GpioAddrOn, DISPON, 0);

    return 0;
}
