/* グラフィック表示のテストプログラム               */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

#include <stdio.h>
#include "platform.h"

#define MEMC     ((volatile unsigned char *) 0xc0000000)
#define MODEREG  *((volatile unsigned int *) 0xc1000000)
#define DISPPAGE *((volatile unsigned int *) 0xc5000000)
#define DBLANK   *((volatile unsigned int *) 0xc5000004)

#define DISPMODE 0
#define MCSMODE  2

#define XSIZE 640
#define YSIZE 480

void wait_dblank( void );

int main()
{
    int x, y, i;

    init_platform();
    DISPPAGE = 0;
    wait_dblank();
    MODEREG = MCSMODE;

    /* ページ0にタイル模様を書く */
    for (y=0; y<YSIZE; y++) {
        for ( x=0; x<XSIZE; x++) {
            MEMC[x+y*XSIZE] = ((x/80)<<5) | ((y/60)<<2) | 3;
        }
    }
    /* ページ1に縞模様を書く */
    for (i=0; i<XSIZE*YSIZE; i++)
        MEMC[i+XSIZE*YSIZE] = i;

    wait_dblank();
    MODEREG = DISPMODE;

    /* 60フレームごとに表示ページを切り替える */
    while (1) {
        for ( i=0; i<60; i++)
            wait_dblank();
        DISPPAGE ^= 1;
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
