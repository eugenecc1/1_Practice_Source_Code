/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第6章課題                    */
/* project: chardisp_mb                  */
/* outline: 文字表示回路テストプログラム */

#include "xparameters.h"
#include "xil_printf.h"

#define VRAM   ((volatile unsigned int  *) XPAR_CHARDISP_IP_V1_0_0_BASEADDR)
#define VRAM_C ((volatile unsigned char *) XPAR_CHARDISP_IP_V1_0_0_BASEADDR)

int main()
{
    int i;
    /* 各色で各文字を表示 */
    for ( i=0; i<4000; i++ ) {
        VRAM[i] = (i<<8) | (0xff & i);
    }

    for ( i=0; i<40; i++ ) {
        xil_printf("VRAM[%d] = %x %x\r\n", i, VRAM[i]>>8, VRAM[i] & 0xff);
    }

    /* 文字だけ全部Aにしてみる      ★この行にブレークポイントを置く★ */
    for ( i=0; i<4000; i++ ) {
        VRAM_C[i*4] = 'A';
    }

    for ( i=0; i<40; i++ ) {
        xil_printf("VRAM[%d] = %x %x\r\n", i, VRAM[i]>>8, VRAM[i] & 0xff);
    }

    /* スクロールして最下行をクリア ★この行にブレークポイントを置く★ */
    for ( i=0; i<3920; i++ ) {
        VRAM[i] = VRAM[i+80];
    }
    for ( i=3920; i<4000; i++ ) {
        VRAM[i] = ' ';
    }


    return 0;
}
