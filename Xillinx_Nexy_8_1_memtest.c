/* 外部メモリのテストプログラム                     */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

#include <stdio.h>
#include "platform.h"

#define MEM_C  ((volatile unsigned char  *)0xc0000000)
#define MEM_S  ((volatile unsigned short *)0xc0000000)
#define MEM_I  ((volatile unsigned int   *)0xc0000000)

#define MODEREG *((volatile unsigned int *)0xc1000000)
#define MCSMODE 2

#define MEMSIZE 0x1000000

int main()
{
    int i, err=0;
    unsigned int i1, i2, i3;
    unsigned int ary[3];

    init_platform();
    MODEREG = MCSMODE;

    /* RAMに書き込む値 */
    ary[0] = 0x47bd9f6a;
    ary[1] = 0x1e806c95;
    ary[2] = 0x2fdc3a5c;

   /* BYTE書き込み */
    xil_printf("BYTE Checking...\n");

    for ( i=0; i<MEMSIZE-3; i=i+3 ) {
        MEM_C[i]   = ary[0];
        MEM_C[i+1] = ary[1];
        MEM_C[i+2] = ary[2];
    }

    /* BYTE読み出し */
    for ( i=0; i<MEMSIZE-3; i=i+3 ) {
        i1 = MEM_C[i];
        i2 = MEM_C[i+1];
        i3 = MEM_C[i+2];
        if ( i1 != (ary[0] & 0xff) ) err=1;
        if ( i2 != (ary[1] & 0xff) ) err=1;
        if ( i3 != (ary[2] & 0xff) ) err=1;
    }

    /* SHORT書き込み */
    xil_printf("SHORT Checking...\n");

    for ( i=0; i<MEMSIZE/2-3; i=i+3 ) {
        MEM_S[i]   = ary[0];
        MEM_S[i+1] = ary[1];
        MEM_S[i+2] = ary[2];
    }

    /* SHORT読み出し */
    for ( i=0; i<MEMSIZE/2-3; i=i+3 ) {
        i1 = MEM_S[i];
        i2 = MEM_S[i+1];
        i3 = MEM_S[i+2];
        if ( i1 != (ary[0] & 0xffff) ) err=1;
        if ( i2 != (ary[1] & 0xffff) ) err=1;
        if ( i3 != (ary[2] & 0xffff) ) err=1;
    }

    /* INT書き込み */
    xil_printf("INT Checking...\n");

    for ( i=0; i<MEMSIZE/4-3; i=i+3 ) {
        MEM_I[i]   = ary[0];
        MEM_I[i+1] = ary[1];
        MEM_I[i+2] = ary[2];
    }

    /* INT読み出し */
    for ( i=0; i<MEMSIZE/4-3; i=i+3 ) {
        i1 = MEM_I[i];
        i2 = MEM_I[i+1];
        i3 = MEM_I[i+2];
        if ( i1 != ary[0] ) err=1;
        if ( i2 != ary[1] ) err=1;
        if ( i3 != ary[2] ) err=1;
    }

    /* 結果表示 */
    if ( err==1 )
        xil_printf("NG!\n");
    else
        xil_printf("OK! Checking End.\n");

    cleanup_platform();

    return 0;
}
