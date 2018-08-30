// By Nikos Papadopoulos, 4rknova / 2013
// Converted to a GZDoom shader by Chronos "phantombeta" Ouroboros
// Edited by Chronos "phantombeta" Ouroboros

// Sobel Kernel - Horizontal
// -1 -2 -1
//  0  0  0
//  1  2  1

// Sobel Kernel - Horizontal
// -1  0 -1
// -2  0 -2
// -1  0 -1

vec3 samplef (const int x, const int y) {
    vec2 uv = TexCoord.xy * textureSize (InputTexture, 0).xy;
    uv = (uv + vec2 (x, y)) / textureSize (InputTexture, 0).xy;
    return texture (InputTexture, uv).xyz;
}

float luminance (vec3 c) {
    return dot (c, vec3 (.2126, .7152, .0722));
}

vec3 filterf () {
    vec3 hc =samplef (-1,-1) *  1. + samplef ( 0,-1) *  2.
            +samplef ( 1,-1) *  1. + samplef (-1, 1) * -1.
            +samplef ( 0, 1) * -2. + samplef ( 1, 1) * -1.;     

    vec3 vc =samplef (-1,-1) *  1. + samplef (-1, 0) *  2.
            +samplef (-1, 1) *  1. + samplef ( 1,-1) * -1.
            +samplef ( 1, 0) * -2. + samplef ( 1, 1) * -1.;

    return samplef (0, 0) * pow (luminance (vc*vc + hc*hc), .6);
}

void main () {
    FragColor = vec4 (filterf (), 1);
}