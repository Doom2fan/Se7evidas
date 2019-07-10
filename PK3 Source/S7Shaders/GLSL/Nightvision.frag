/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018      Rachael Alexanderson
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

vec4 gaussrand (vec2 co);

float grayscale (vec4 color) {
    return dot (color.rgb, vec3 (.75, .75, .75));
}

void main () {
    vec4 texel = texture (InputTexture, TexCoord);

    float lum = grayscale (texel / (160. / 256.));

    vec3 c = vec3 (.35, 1., .35) * lum;

    vec3 grain = gaussrand (TexCoord).xyz;

    c = clamp (c + (grain * .15 * (1.-flashlightIntensity)), 0., 1.);

    FragColor = vec4 (c, texel.a);
}

// THE CODE BELOW IS (C) Thomas Moulard AND LICENSED UNDER THE APACHE LICENSE
/*
 * Software License Agreement (Apache License)
 *
 * Copyright 2012 Open Source Robotics Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/
// From https://github.com/thomas-moulard/gazebo-deb/blob/master/media/materials/programs/camera_noise_gaussian_fs.glsl
#define PI 3.14159265358979323846264

float rand (vec2 co) {
    // This one-liner can be found in many places, including:
    // http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
    // I can't find any explanation for it, but experimentally it does seem to
    // produce approximately uniformly distributed values in the interval [0,1].
    float r = fract (sin (dot (co.xy, vec2 (12.9898, 78.233))) * 43758.5453);

    // Make sure that we don't return 0.0
    if (r == 0.)
        return .000000000001;
    else
        return r;
}

vec4 gaussrand (vec2 co) {
    // Box-Muller method for sampling from the normal distribution
    // http://en.wikipedia.org/wiki/Normal_distribution#Generating_values_from_normal_distribution
    // This method requires 2 uniform random inputs and produces 2 Gaussian random outputs.
    // We'll take a 3rd random variable and use it to switch between the two outputs.

    float U, V, R, Z;

    // Add in the CPU-supplied random offsets to generate the 3 random values that we'll use.
    U = rand (co + vec2 (offsets.x, offsets.x));
    V = rand (co + vec2 (offsets.y, offsets.y));
    R = rand (co + vec2 (offsets.z, offsets.z));

    // Switch between the two random outputs.
    if (R < 0.5)
        Z = sqrt (-2.0 * log (U)) * sin (2.0 * PI * V);
    else
        Z = sqrt (-2.0 * log (U)) * cos (2.0 * PI * V);

    // Apply the stddev and mean.
    Z = Z * stddev + mean;

    // Return it as a vec4, to be added to the input ("true") color.
    return vec4 (Z, Z, Z, 0.0);
}