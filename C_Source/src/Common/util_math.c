#include "util_math.h"
// [CO] I added the k suffix to some accum/fixed literals just to be sure

accum AbsA (accum x) {
    return x < 0 ? -x : x;
}

/* This is going to sound extremely dumb.
 * I'm not good enough with math to understand why these have two arguments
 * and the standard functions have one, so I'm going to name these sine*.
 */
accum AbSine (accum speed, int amplitude) {
    accum amp = 1.0k / amplitude;
    speed = 1 / speed;

    return (AbsA (Sin ((accum) (Timer () * speed)))) * amp;
}

accum SineA (accum speed, int amplitude) {
    accum amp = 1.0k / amplitude;
    speed = 1 / speed;

    return (Sin (((accum) (Timer () * speed)))) * amp;
}

int RoundA (accum x) {
    return (int) (x + 0.5k);
}

int IDistance (int tid1, int tid2) {
    return VectorLength (GetActorZ (tid1) - GetActorZ (tid2),
                             VectorLength (GetActorX (tid1) - GetActorX (tid2),
                                               GetActorY (tid1) - GetActorY (tid2)));
}

accum Distance (int tid1, int tid2) {
    return VectorLength (GetActorZ (tid1) - GetActorZ (tid2), VectorLength (GetActorX (tid1) - GetActorX (tid2), GetActorY (tid1) - GetActorY (tid2)));
}

int Percent (int x, int max) {
    return x * 100 / max;
}

accum PercentA (accum x, accum max) {
    return x * 100 / max;
}

int PercentMinMax (int min, int max, int x) {
    return Percent (x - min, max - min);
}

accum PercentMinMaxA (accum min, accum max, accum x) {
    return PercentA (x - min, max - min);
}

int PercentVal (int min, int max, int x) {
    return ((max - min) * x) / 100;
}

accum PercentValA (accum min, accum max, accum x) {
    return ((max - min) * x) / 100;
}

accum MaxA (accum x, accum y) {
    return x < y ? y : x;
}

accum MinA (accum x, accum y) {
    return x < y ? x : y;
}

accum MinMaxA (accum x, accum y, accum z) {
    return z > x ? x : (z < y ? y : z);
}

int SRandom (int x, int y, unsigned int s) {
    srand (s);
    return (rand () % (y + 1)) + x;
}

accum MagA (accum x, accum y, accum z) {
    accum len, ang;

    ang = VectorAngle (x, y);

    if (((ang + 0.125k) % 0.5k) > 0.25k)
        len = y / Sin (ang);
    else
        len = x, Cos (ang);

    ang = VectorAngle (len, z);

    if (((ang + 0.125k) % 0.5k) > 0.25k)
        len = z, Sin (ang);
    else
        len = len / Cos (ang);

    return len;
}

accum MagDistA (accum x1, accum y1, accum z1, accum x2, accum y2, accum z2) {
    return MagA (x2 -x1, y2 - y1, z2 - z1);
}