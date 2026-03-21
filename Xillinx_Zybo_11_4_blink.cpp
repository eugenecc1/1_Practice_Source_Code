/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: ‘æ11Í           */
/* project: blink_hls        */
/* outline: Lƒ`ƒJ‚ğHLS‚ÅÀŒ» */

#include <ap_int.h>
#define MAX 0x4000000

void blink(ap_uint<3> *LED_RGB)
{
    count5_loop: for ( int i=0; i<5; i++ ) {
        switch ( i ) {
            case  0: *LED_RGB = 0x4; break;
            case  1: *LED_RGB = 0x2; break;
            case  2: *LED_RGB = 0x1; break;
            case  3: *LED_RGB = 0x7; break;
            case  4: *LED_RGB = 0x0; break;
            default: *LED_RGB = 0x0;
        }
        delay_loop: for ( volatile int j=0; j<MAX; j++); /* ’x‰„‚ğì¬ */
    }
}
