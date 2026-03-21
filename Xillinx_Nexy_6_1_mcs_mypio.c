/* ©ìƒpƒ‰ƒŒƒ‹I/O‚Ì§Œä                             */
/* Copyright(C) 2013 Cobac.Net, All rights reserved. */

#include <stdio.h>
#include "platform.h"

#define LED  *((volatile unsigned int *) 0xC0000000)
#define SW   *((volatile unsigned int *) 0xC0000004)

int main()
{
    int in, out;

    init_platform();
    xil_printf("hello, Xilinx world.\n");

    while (1) {
        in = 0xf & SW;
        switch ( in ) {
            case 0x0: out = 0xc0; break;
            case 0x1: out = 0xf9; break;
            case 0x2: out = 0xa4; break;
            case 0x3: out = 0xb0; break;
            case 0x4: out = 0x99; break;
            case 0x5: out = 0x92; break;
            case 0x6: out = 0x82; break;
            case 0x7: out = 0xd8; break;
            case 0x8: out = 0x80; break;
            case 0x9: out = 0x90; break;
            case 0xA: out = 0x88; break;
            case 0xB: out = 0x83; break;
            case 0xC: out = 0xc6; break;
            case 0xD: out = 0xa1; break;
            case 0xE: out = 0x86; break;
            case 0xF: out = 0x8e; break;
            default:  out = 0xff; break;
        }
        LED = out;
    }
    cleanup_platform();
    return 0;
}
