/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第11章                           */
/* project: blink_hls                        */
/* outline: HLSで作成したLチカのテストベンチ */

#include <ap_int.h>

void blink(ap_uint<3>*);

int main()
{
    ap_uint<3> LED_RGB;

    blink( &LED_RGB );

    return 0;
}
