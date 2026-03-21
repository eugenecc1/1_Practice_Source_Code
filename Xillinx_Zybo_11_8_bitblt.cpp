/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第11章課題                         */
/* project: bitblt_trans_ip                    */
/* outline: 透過処理付きビットブロック描画回路 */

#include <ap_int.h>
#include "bitblt.h"

/* 画素間演算 */
u32 calc(u32 src, u32 dst, u8 alpha, u8 transparent)
{
    /* RGB各8ビットで取り出す */
    u32 src_r = (src>>16) & 0xff;
    u32 src_g = (src>> 8) & 0xff;
    u32 src_b =  src      & 0xff;

    u32 dst_r = (dst>>16) & 0xff;
    u32 dst_g = (dst>> 8) & 0xff;
    u32 dst_b =  dst      & 0xff;

    /* srcのα値が0の部分を透過させる */
    u8 temp = (transparent!=0 && (src & 0xff000000)==0) ? (u8)0: alpha;

    /* 各色ごとに画素間演算 */
    dst_r = (temp*src_r + (255-temp)*dst_r)/255;
    dst_g = (temp*src_g + (255-temp)*dst_g)/255;
    dst_b = (temp*src_b + (255-temp)*dst_b)/255;

    return ((dst_r<<16) & 0xff0000) | ((dst_g<<8) & 0xff00) | (dst_b & 0xff);
}

/* bitblt本体 */
void bitblt(
    volatile u32 *srcin,
    volatile u32 *dstin,
    volatile u32 *dstout,
    u8  alpha,
    u11 width,
    u11 height,
    u8 transparent)
{
    u32 src[XSIZE], dst[XSIZE];

    height_loop: for (int y=0; y<height; y++) {
        src_loop: for (int x=0; x<width; x++) {     /* テクスチャ */
            src[x] = srcin[x + y*XSIZE];
        }
        dstin_loop: for (int x=0; x<width; x++) {   /* 背景 */
            dst[x] = dstin[x + y*XSIZE];
        }
        dstout_loop: for (int x=0; x<width; x++) {  /* 演算結果を書く */
            dstout[x + y*XSIZE] = calc(src[x], dst[x], alpha, transparent);
        }
    }
}
