// Based on a simple vignette shader by Ippokratis at ShaderToy.
// Ported by Nash Muhandes
// Modified by Chronos "phantombeta" Ouroboros

void main () {
    vec2 texSize = textureSize (InputTexture, 0);

    vec2 uv = TexCoord;
    uv *= 1. - uv.yx;
    float vig = uv.x * uv.y * 15;
    vig = pow (vig, .05 * vignetteStrength);

    vig = clamp (vig, 0., 1.);

    vec4 src = texture (InputTexture, TexCoord);
    vec4 c = vec4 (mix (src.rgb, vignetteColour, 1. - vig), src.a);
    FragColor = vec4 (c);
}