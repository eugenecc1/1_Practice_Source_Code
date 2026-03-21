/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第11章課題                 */
/* project: display                    */
/* outline: ドット文字描画回路のテスト */

#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xgpio.h"
#include "xil_cache.h"
#include "xdrawchar.h"

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
XDrawchar Instance;

/* VBLANK待ち */
void wait_vblank(void) {
    XGpio_DiscreteWrite(&GpioBlank, CLRVBLNK, 1);
    XGpio_DiscreteWrite(&GpioBlank, CLRVBLNK, 0);
    while (XGpio_DiscreteRead(&GpioBlank, VBLANK)==0);
}

void drawchar( short xpos, short ypos, char letter, char dotsize, int col ) {
    XDrawchar_Set_xpos(&Instance, xpos);
    XDrawchar_Set_ypos(&Instance, ypos);
    XDrawchar_Set_letter(&Instance, letter);
    XDrawchar_Set_dotsize(&Instance, dotsize);
    XDrawchar_Set_color(&Instance, col);
    XDrawchar_Start(&Instance);
    while (XDrawchar_IsDone(&Instance)==0);
}

int main()
{
    int i, ch, dotsize, xpos, ypos, Status;

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

    /* 画面クリア */
    for ( i=0; i<XSIZE*YSIZE; i++) {
        VRAM[i] = 0;
    }
    Xil_DCacheFlush();

    /* drawchaの初期化 */
    Status = XDrawchar_Initialize(&Instance, XPAR_XDRAWCHAR_0_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    XDrawchar_Set_dstout(&Instance, (u32)0x10000000);

    /* いろいろな大きさで文字を書く */
    ypos = 16; ch = '!';
    for ( dotsize=2; ; dotsize++ ){
        for ( xpos=0; xpos<(XSIZE-dotsize*8); xpos+=dotsize*8 ) {
            drawchar( xpos, ypos, ch, dotsize, rand());
            if ( ++ch >= 128 ) ch = '!';
        }
        ypos += dotsize*8;
        if ( (ypos + dotsize*8)>YSIZE) break;
    }

    /* 表示をオフして終了 */
    wait_vblank();  /* ★この行にブレークポイント★ */
    XGpio_DiscreteWrite(&GpioAddrOn, DISPON, 0);

    return 0;
}
