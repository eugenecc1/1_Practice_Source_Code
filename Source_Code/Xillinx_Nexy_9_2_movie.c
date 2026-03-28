/* 動画記録再生プログラム                           */
/* Copyright(C) 2013 Cobac.Net All rights reserved. */

#include <stdio.h>
#include "platform.h"
#include "ov7670.h"

#define MODEREG  *((volatile unsigned int *) 0xc1000000)
#define DISPMODE 0
#define CAPTMODE 1
#define MCSMODE  2

#define DISPPAGE *((volatile unsigned int *) 0xc5000000)
#define DBLANK   *((volatile unsigned int *) 0xc5000004)

#define CAPTPAGE *((volatile unsigned int *) 0xc6000000)
#define CAPTREG  *((volatile unsigned int *) 0xc6000004)
#define CBLANK   1
#define CAPTON   2

#define SCCBREG  *((volatile unsigned int *) 0xc7000000)
#define SCCBSTAT *((volatile unsigned int *) 0xc7000004)
#define SCCBBUSY 1

void wait_dblank( void );
void wait_cblank( void );
void sccb_write( int );
void ov7670_init( void );

#define MAXPIC 54

int main()
{
    int i;
    init_platform();

    ov7670_init();

    MODEREG  = DISPMODE;
    DISPPAGE = 0;
    CAPTPAGE = 0;
    CAPTREG  = 0;

    /* 録画 */
    wait_cblank();        // ここにブレークポイントを置いてもいい
    MODEREG = CAPTMODE;
    CAPTREG |= CAPTON;    // キャプチャ開始
    for (i=0; i<MAXPIC; i++ ) {
        CAPTPAGE = i;
        wait_cblank();
    }
    CAPTREG &= ~CAPTON;   // キャプチャ終了

    /* 再生 */
    wait_dblank();
    MODEREG = DISPMODE;
    i = 0;
    while (1) {
        DISPPAGE = i;
        wait_dblank();    // キャプチャは30fpsなので2回待つ
        wait_dblank();
        if ( ++i==MAXPIC )
            i = 0;
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

/* 画面取り込み終了を待つ */
void wait_cblank( void )
{
    CAPTREG &= ~CBLANK;
    while ( (CAPTREG & CBLANK) == 0 );
}


/* SCCB経由でカメラの設定レジスタに書き込み */
void sccb_write( int data )
{
    while ((SCCBSTAT & SCCBBUSY) != 0);
    SCCBREG = data;
}

/* センサーチップOV7670の初期化 */
void ov7670_init( void )
{
    int i=0;
    int data=init_data[0];

    while ( data!=0xffff ) {
        sccb_write( data );
        data = init_data[++i];
    }
    while ((SCCBSTAT & SCCBBUSY) != 0);
}
