/* VGA文字表示回路のテストプログラム                */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

#include <stdio.h>
#include "platform.h"

#define VRAM ((volatile unsigned int *) 0xc4000000)

int main()
{
    int i;
    init_platform();

    for ( i=0; i<4096; i++ ) {
        VRAM[i] = (i<<8) | (0xff & i);
    }

    cleanup_platform();

    return 0;
}
