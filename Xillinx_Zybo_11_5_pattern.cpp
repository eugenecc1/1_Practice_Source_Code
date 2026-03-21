/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第11章                        */
/* project: pattern_hls                   */
/* outline: HLSで作成したパターン表示回路 */

#include <ap_int.h>
#include "pattern.h"

#define HSIZE  80
#define VSIZE 120

#define HBLANK (HFRONT + HWIDTH + HBACK)
#define VBLANK (VFRONT + VWIDTH + VBACK)

void pattern(u8 *VGA_R,  u8 *VGA_G,  u8 *VGA_B,
             u1 *VGA_HS, u1 *VGA_VS, u1 *VGA_DE)
{
    vcnt_loop: for (u16 VCNT=0; VCNT<VPERIOD; VCNT++) {
        hcnt_loop: for (u16 HCNT=0; HCNT<HPERIOD; HCNT++) {
            /* HとVの同期信号作成 */
            if ( (HFRONT <= HCNT) && (HCNT < HFRONT+HWIDTH) ) {
                *VGA_HS = 0;
                if ( (VFRONT <= VCNT) && (VCNT < VFRONT+VWIDTH) )
                    *VGA_VS = 0;
                else
                    *VGA_VS = 1;
            }
            else
                *VGA_HS = 1;
                
            /* VGA_DE信号作成 */
            if ( (VBLANK <= VCNT) && (HBLANK <= HCNT) )
                *VGA_DE = 1;
            else
                *VGA_DE = 0;
                
            /* RGB出力を作成 */
            unsigned int rgb_0 = (HCNT-HBLANK)/HSIZE;
            unsigned int rgb_1 = (((VCNT-VBLANK)/VSIZE)&1)==0 ? 7-rgb_0: rgb_0;

            if (*VGA_DE==0) {
                *VGA_R = 0x00; *VGA_G = 0x00; *VGA_B = 0x00;
            }
            else
                switch ( rgb_1 ) {
                    case 0: *VGA_R = 0x00; *VGA_G = 0x00; *VGA_B = 0x00; break;
                    case 1: *VGA_R = 0x00; *VGA_G = 0x00; *VGA_B = 0xff; break;
                    case 2: *VGA_R = 0x00; *VGA_G = 0xff; *VGA_B = 0x00; break;
                    case 3: *VGA_R = 0x00; *VGA_G = 0xff; *VGA_B = 0xff; break;
                    case 4: *VGA_R = 0xff; *VGA_G = 0x00; *VGA_B = 0x00; break;
                    case 5: *VGA_R = 0xff; *VGA_G = 0x00; *VGA_B = 0xff; break;
                    case 6: *VGA_R = 0xff; *VGA_G = 0xff; *VGA_B = 0x00; break;
                    case 7: *VGA_R = 0xff; *VGA_G = 0xff; *VGA_B = 0xff; break;
                }
        }
    }
}
