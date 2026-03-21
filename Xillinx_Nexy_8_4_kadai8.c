/* 第８章課題　フォトフレーム                       */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

#include <stdio.h>
#include "platform.h"

#define MEMC     ((volatile unsigned char *) 0xc0000000)
#define MODEREG  *((volatile unsigned int *) 0xc1000000)
#define DISPPAGE *((volatile unsigned int *) 0xc5000000)
#define DBLANK   *((volatile unsigned int *) 0xc5000004)
#define PICT     ((volatile unsigned char *) 0xc0800000)

#define DISPMODE 0
#define MCSMODE  2

#define XSIZE 640
#define YSIZE 480

#define PICTNUM 4

void wait_dblank( void );

int main()
{
    int i, j, R, G, B;

    init_platform();
    wait_dblank();
    MODEREG = MCSMODE;
    /* 画像フォーマットの変換 */
    for ( j=0; j<PICTNUM; j++ ) {
        for (i=0; i<XSIZE*YSIZE; i++) {
            R = PICT[(XSIZE*YSIZE*j+i)*3  ];
            G = PICT[(XSIZE*YSIZE*j+i)*3+1];
            B = PICT[(XSIZE*YSIZE*j+i)*3+2];
            MEMC[XSIZE*YSIZE*j+i] = (R & 0xe0) | ((G & 0xe0)>>3) | ((B & 0xc0)>>6);
        }
    }
    /* 表示モード切替 */
    wait_dblank();
    MODEREG = DISPMODE;

    j = 0;
    while(1) {
        DISPPAGE = j;
        for ( i=0; i<60; i++)
            wait_dblank();
        if (++j==PICTNUM) j=0;
    }
    cleanup_platform();
    return 0;
}

/* 画面表示の終了を待つ */
void wait_dblank( void )
{
    DBLANK = 0;
    while ( DBLANK == 0 );
}
