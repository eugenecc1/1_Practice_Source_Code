/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第11章            */
/* project: pattern_hls       */
/* outline: VGA用パラメータ他 */

#ifndef PATTERN_H_
#define PATTERN_H_

/* VGA(640×480)パラメータ */
#define HPERIOD 800
#define HFRONT   16
#define HWIDTH   96
#define HBACK    48

#define VPERIOD 525
#define VFRONT   10
#define VWIDTH    2
#define VBACK    33

/* 専用データタイプ */
typedef ap_uint<1>  u1;
typedef ap_uint<3>  u3;
typedef ap_uint<8>  u8;
typedef ap_uint<16> u16;

#endif /* PATTERN_H_ */
