/* ポーリングによるタイマー制御                      */
/* Copyright(C) 2013 Cobac.Net, All rights reserved. */

#include "platform.h"
#include "IO_Module.h"
#include "mb_interface.h"

#define LED  GPO1
#define FIT1_int 0x80

void timer_int_handler( void * );

int count;
int LEDdata;

int main()
{
    init_platform();

    LEDdata = 0;

    while (1) {
        while( (IRQ_STATUS & FIT1_int)==0 );
        timer_int_handler( (void *)0 );
        switch ( LEDdata ) {
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
            default:  LED = 0xFF; break;
        }
    }
    cleanup_platform();

    return 0;
}


void timer_int_handler( void *arg )
{
    count++;
    if ( (count%1000)==999 ) {
        LEDdata++;
        if ( LEDdata>9 )
            LEDdata = 0;
    }
    IRQ_ACK = FIT1_int;
}
