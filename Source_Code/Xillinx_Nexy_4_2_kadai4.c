/* 第４章課題　ソフトウェアによる１秒桁              */
/* Copyright(C) 2013 Cobac.Net, All rights reserved. */

#include <stdio.h>
#include "platform.h"

#define LED  *((volatile unsigned int *) 0x80000010)
#define SW   *((volatile unsigned int *) 0x80000020)

#define MAX 3800000

int main()
{
    int i, cnt = 0;
    init_platform();

    while (1) {
        if ( (SW & 0x02) != 0 ) {
            cnt = 0;
        }
        else if ( (SW & 0x01) != 0 ) {
            for ( i=0; i<MAX; i++ );
            cnt++;
        }
        switch ( cnt%10 ) {
            case 0x0: LED = 0xc0; break;
            case 0x1: LED = 0xf9; break;
            case 0x2: LED = 0xa4; break;
            case 0x3: LED = 0xb0; break;
            case 0x4: LED = 0x99; break;
            case 0x5: LED = 0x92; break;
            case 0x6: LED = 0x82; break;
            case 0x7: LED = 0xd8; break;
            case 0x8: LED = 0x80; break;
            case 0x9: LED = 0x90; break;
            default:  LED = 0xff; break;
        }
    }
    cleanup_platform();
    return 0;
}
