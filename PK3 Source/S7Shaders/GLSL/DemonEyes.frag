/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Rachael Alexanderson, Chronos "phantombeta" Ouroboros
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
    vec4 c = texture (InputTexture, TexCoord);

    float purple = clamp ((c.r + c.b) / 2. - c.g * 2., 0., 1.);
    float red = clamp (c.r - c.g - c.b, 0., 1.);
    vec3 lum = vec3 (pow (dot (c.rgb, vec3 (.3, .56, .14)), 1 / .75));

    float thing = .8 + pow (lum.r, .5) * .8;
    float thing2 = .4 + pow (lum.r, .5) * .4;
    vec3 z = mix (lum, vec3 (thing2, 0., thing), purple);
    z = mix (z, vec3 (thing * .25, 0., thing), red);

    FragColor = vec4 (mix (z, c.rgb, .25), 1.);
}