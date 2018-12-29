/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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

void main () {
    vec2 texSize = textureSize (InputTexture, 0);

    vec2 uv = TexCoord;
    uv *= 1. - uv.yx;
    float vig = uv.x * uv.y * 15;
    vig = pow (vig, .05 * stealthFactor);

    vig = clamp (vig, 0., 1.);

    vec4 src = texture (InputTexture, TexCoord);
    vec4 c = vec4 (src.rgb + vec3 (.625, .25, 1.) * .75 * (1 - vig), src.a);
    FragColor = vec4 (c);
}