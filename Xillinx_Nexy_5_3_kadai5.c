/* 第５章課題　ソフトウェアによるダイナミック点灯    */
/* Copyright(C) 2013 Cobac.Net, All rights reserved. */

#include "platform.h"
#include "IO_Module.h"
#include "mb_interface.h"

#define LED  GPO1
#define nAN  GPO2

#define FIT1_int 0x80
#define DIG1_ON  0xe
#define DIG10_ON 0xd

void timer_int_handler( void * );
int  seg7dec( int );
void mkdigit( void );

int count, sec;
int dig10, dig1;
int dig1sel;

int main()
{
    init_platform();

    sec = 0;
    nAN = DIG1_ON;
    dig1sel = 1;
    mkdigit();

    microblaze_register_handler(timer_int_handler, (void *)0);
    microblaze_enable_interrupts();
    IRQ_ENABLE = FIT1_int;

    while (1);

    cleanup_platform();

    return 0;
}

void timer_int_handler( void *arg )
{
    count++;
    if ( (count%5)==0 ) {
        if ( dig1sel==0 ) {
            LED = dig1;
            nAN = DIG1_ON;
            dig1sel = 1;
        }
        else {
            LED = dig10;
            nAN = DIG10_ON;
            dig1sel = 0;
        }
    }

    if ( (count%1000)==0 ) {
        sec++;
        if ( sec>=60 )
            sec = 0;
        mkdigit();
    }
    IRQ_ACK = FIT1_int;
}

void mkdigit( void )
{
    dig10 = seg7dec( sec/10 );
    dig1  = seg7dec( sec%10 );
}

int seg7dec( int din )
{
    switch ( din ) {
        case 0x0: return 0xc0;
        case 0x1: return 0xf9;
        case 0x2: return 0xa4;
        case 0x3: return 0xb0;
        case 0x4: return 0x99;
        case 0x5: return 0x92;
        case 0x6: return 0x82;
        case 0x7: return 0xd8;
        case 0x8: return 0x80;
        case 0x9: return 0x90;
        default:  return 0xFF;
    }
}
