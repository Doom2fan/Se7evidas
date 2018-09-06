// By Rachael
// Edited by Chronos "phantombeta" Ouroboros

void main () {
    vec4 c = texture (InputTexture, TexCoord);
    float red = clamp (0., c.r - c.g - c.b, 1.);
    vec3 lum = vec3 (pow (dot (c.rgb, vec3 (.3, .56, .14)), 1. / .75));

    float thing = .8 + pow (lum.r, .5) * .8;
    vec3 z = mix (lum, vec3 (thing * .25, 0., thing), red);

    FragColor = vec4 (mix (z, c.rgb, .25), 1.);
}