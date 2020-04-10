/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

const int samples = 50;
const float samplesF = float (samples);
const float blurAmount = .75;

void main () {
    vec4 texel = texture (InputTexture, TexCoord);

    // Blur
    vec4 blurImage = vec4 (0.);
    float scale = 0.;

    for (int i = 0; i < samples; i++){
        float p = float (i) / samplesF;
        blurImage += texture (InputTexture, TexCoord + (vec2 (.5) - TexCoord) * p * blurAmount * blurStrength) / samplesF;
    }

    // Fading
    vec2 centeredCoord = TexCoord - 0.5;
    float distance = sqrt (dot (centeredCoord, centeredCoord));

    FragColor = mix (texel, blurImage, clamp (pow (distance, 1.2) * 1.5 * vignetteStrength, 0., 1.));
}