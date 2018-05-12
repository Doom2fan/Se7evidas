// ========================================================
//
//  The code in this file was made by Marrub
//
// ========================================================

#ifndef UTIL_MATH_H
#define UTIL_MATH_H

#include "common/defs.h"

#define TIME_SEC  35
#define TIME_MIN  35 * 60
#define TIME_HOUR TIME_MIN * 60
#define TIME_DAY  TIME_HOUR * 24

#define SinA ACS_Sin
#define CosA ACS_Cos

accum AbsA (accum x);
accum Absine (accum speed, int amplitude);
accum SineA (accum speed, int amplitude);
int RoundA (accum x);
int IDistance (int tid1, int tid2);
accum Distance (int tid1, int tid2);
int Percent (int x, int max);
accum PercentA (accum x, accum max);
int PercentMinMax (int min, int max, int x);
accum PercentMinMaxA (accum min, accum max, accum x);
int PercentVal (int min, int max, int x);
accum PercentValA (accum min, accum max, accum x);
accum MaxA (accum x, accum y);
accum MinA (accum x, accum y);
accum MinMaxA (accum x, accum y, accum z);
int SRandom (int x, int y, unsigned int s);
accum MagA (accum x, accum y, accum z);
accum MagDistA (accum x1, accum y1, accum z1, accum x2, accum y2, accum z2);

#endif