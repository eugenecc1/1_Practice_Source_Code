/* Copyright(C) 2020 Cobac.Net All Rights Reserved.    */
/* chapter: 第7章課題                                  */
/* project: chardisp2                                  */
/* outline: 反転、点滅付き文字表示回路テストプログラム */

#include "xparameters.h"
#include "xil_printf.h"

#define VRAM   ((volatile unsigned int  *) XPAR_CHARDISP_IP_V1_0_0_BASEADDR)

#define XSIZE 80
#define YSIZE 50

#define REV   0x100000
#define BLINK 0x200000

int main()
{
    int x, y;
    /* 各色で各文字を表示 */
    for ( x=0; x<XSIZE*YSIZE; x++ ) {
        VRAM[x] = (x<<8) | (0xff & x);
    }

    /* １行ごとに反転と点滅にする */
    for ( y=0; y<YSIZE; y++ ) {
        for ( x=0; x<XSIZE; x++ ) {
            if ( y%4==1 )
                VRAM[y*XSIZE+x] = VRAM[y*XSIZE+x] | REV;
            else if ( y%4==3 )
                VRAM[y*XSIZE+x] = VRAM[y*XSIZE+x] | BLINK;
        }
    }

    return 0;
}
