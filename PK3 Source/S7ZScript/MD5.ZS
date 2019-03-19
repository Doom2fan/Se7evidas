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

class S7_MD5 {
    static S7_MD5 Create () {
        S7_MD5 ret = new ('S7_MD5');
        ret.Reset ();

        return ret;
    }

    static string FromStream (S7_TZK_Stream stream) {
        let md5 = S7_MD5.Create ();

        let tmpArr = new ('S7_TZK_ArrayI32');

        for (int i = 0; i < stream.Length (); i++)
            tmpArr.Push (stream.Read ());

        md5.Put (tmpArr);

        string ret = md5.Finish ();

        md5.Reset (); md5 = NULL;

        return ret;
    }

    static string FromString (string input) {
        let stream = S7_TZK_StringStream.Create (input);
        
        string ret = FromStream (stream);
        stream = NULL;

        return ret;
    }

    static string FromBytes (S7_TZK_ArrayI32 input) {
        let md5 = S7_MD5.Create ();

        md5.Put (input);

        return md5.Finish ();
    }

    static bool IsHashValid (string hash) {
        if (hash.Length () != 32)
            return false;

        hash.ToUpper ();
        for (int i = 0; i < hash.Length (); i++) {
            int c = hash.CharCodeAt (i);

            if ((c >= 65 && c <= 70) || (c >= 48 && c <= 57)) // Continue if char matches [0-9A-Z]
                continue;

            if (i == (hash.Length () - 1) && c == ASCII_NUL) // Ignore NULs
                continue;

            return false;
        }

        return true;
    }

    private uint _state [4]; // state (ABCD)
    private uint _count; // number of bits, modulo 2^64
    private uint _buffer [64]; // input buffer

    static const uint8 _padding [] = {
        0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    };

    static uint F (uint x, uint y, uint z) { return (x & y) | (~x & z); }
    static uint G (uint x, uint y, uint z) { return (x & z) | (y & ~z); }
    static uint H (uint x, uint y, uint z) { return x ^ y ^ z; }
    static uint I (uint x, uint y, uint z) { return y ^ (x | ~z); }

    static uint rotateLeft (uint x, uint n) {
        uint ret = uint ((x << n) | (x >>> (32-n)));
        return ret;
    }

    static void FF (out uint a, uint b, uint c, uint d, uint x, uint s, uint ac) {
        a += (F (b, c, d) + x + ac);
        a = rotateLeft (a, s);
        a += b;
    }

    static void GG (out uint a, uint b, uint c, uint d, uint x, uint s, uint ac) {
        a += (G (b, c, d) + x + ac);
        a = rotateLeft (a, s);
        a += b;
    }

    static void HH (out uint a, uint b, uint c, uint d, uint x, uint s, uint ac) {
        a += (H (b, c, d) + x + ac);
        a = rotateLeft (a, s);
        a += b;
    }

    static void II (out uint a, uint b, uint c, uint d, uint x, uint s, uint ac) {
        a += (I (b, c, d) + x + ac);
        a = rotateLeft (a, s);
        a += b;
    }

    /*
     * MD5 basic transformation. Transforms state based on block.
     */

    //Constants for MD5Transform routine.
    enum TransConsts {
        S11 = 7,
        S12 = 12,
        S13 = 17,
        S14 = 22,
        S21 = 5,
        S22 = 9,
        S23 = 14,
        S24 = 20,
        S31 = 4,
        S32 = 11,
        S33 = 16,
        S34 = 23,
        S41 = 6,
        S42 = 10,
        S43 = 15,
        S44 = 21,
    }

    private void transform (S7_TZK_ArrayI32 block) {
        //Console.PrintF ("pre-transform: %.8X%.8X%.8X%.8X", _state[0], _state[1], _state[2], _state[3]);
        uint a = _state [0],
             b = _state [1],
             c = _state [2],
             d = _state [3];

        uint x [16];

        for (int i = 0; i < 16; i++)
            x [i] = block.Values [i];

        // Round 1
        FF (a, b, c, d, x [ 0], S11, 0xd76aa478); /* 1 */
        FF (d, a, b, c, x [ 1], S12, 0xe8c7b756); /* 2 */
        FF (c, d, a, b, x [ 2], S13, 0x242070db); /* 3 */
        FF (b, c, d, a, x [ 3], S14, 0xc1bdceee); /* 4 */
        FF (a, b, c, d, x [ 4], S11, 0xf57c0faf); /* 5 */
        FF (d, a, b, c, x [ 5], S12, 0x4787c62a); /* 6 */
        FF (c, d, a, b, x [ 6], S13, 0xa8304613); /* 7 */
        FF (b, c, d, a, x [ 7], S14, 0xfd469501); /* 8 */
        FF (a, b, c, d, x [ 8], S11, 0x698098d8); /* 9 */
        FF (d, a, b, c, x [ 9], S12, 0x8b44f7af); /* 10 */
        FF (c, d, a, b, x [10], S13, 0xffff5bb1); /* 11 */
        FF (b, c, d, a, x [11], S14, 0x895cd7be); /* 12 */
        FF (a, b, c, d, x [12], S11, 0x6b901122); /* 13 */
        FF (d, a, b, c, x [13], S12, 0xfd987193); /* 14 */
        FF (c, d, a, b, x [14], S13, 0xa679438e); /* 15 */
        FF (b, c, d, a, x [15], S14, 0x49b40821); /* 16 */

        // Round 2
        GG (a, b, c, d, x [ 1], S21, 0xf61e2562); /* 17 */
        GG (d, a, b, c, x [ 6], S22, 0xc040b340); /* 18 */
        GG (c, d, a, b, x [11], S23, 0x265e5a51); /* 19 */
        GG (b, c, d, a, x [ 0], S24, 0xe9b6c7aa); /* 20 */
        GG (a, b, c, d, x [ 5], S21, 0xd62f105d); /* 21 */
        GG (d, a, b, c, x [10], S22,  0x2441453); /* 22 */
        GG (c, d, a, b, x [15], S23, 0xd8a1e681); /* 23 */
        GG (b, c, d, a, x [ 4], S24, 0xe7d3fbc8); /* 24 */
        GG (a, b, c, d, x [ 9], S21, 0x21e1cde6); /* 25 */
        GG (d, a, b, c, x [14], S22, 0xc33707d6); /* 26 */
        GG (c, d, a, b, x [ 3], S23, 0xf4d50d87); /* 27 */
        GG (b, c, d, a, x [ 8], S24, 0x455a14ed); /* 28 */
        GG (a, b, c, d, x [13], S21, 0xa9e3e905); /* 29 */
        GG (d, a, b, c, x [ 2], S22, 0xfcefa3f8); /* 30 */
        GG (c, d, a, b, x [ 7], S23, 0x676f02d9); /* 31 */
        GG (b, c, d, a, x [12], S24, 0x8d2a4c8a); /* 32 */

        // Round 3
        HH (a, b, c, d, x [ 5], S31, 0xfffa3942); /* 33 */
        HH (d, a, b, c, x [ 8], S32, 0x8771f681); /* 34 */
        HH (c, d, a, b, x [11], S33, 0x6d9d6122); /* 35 */
        HH (b, c, d, a, x [14], S34, 0xfde5380c); /* 36 */
        HH (a, b, c, d, x [ 1], S31, 0xa4beea44); /* 37 */
        HH (d, a, b, c, x [ 4], S32, 0x4bdecfa9); /* 38 */
        HH (c, d, a, b, x [ 7], S33, 0xf6bb4b60); /* 39 */
        HH (b, c, d, a, x [10], S34, 0xbebfbc70); /* 40 */
        HH (a, b, c, d, x [13], S31, 0x289b7ec6); /* 41 */
        HH (d, a, b, c, x [ 0], S32, 0xeaa127fa); /* 42 */
        HH (c, d, a, b, x [ 3], S33, 0xd4ef3085); /* 43 */
        HH (b, c, d, a, x [ 6], S34,  0x4881d05); /* 44 */
        HH (a, b, c, d, x [ 9], S31, 0xd9d4d039); /* 45 */
        HH (d, a, b, c, x [12], S32, 0xe6db99e5); /* 46 */
        HH (c, d, a, b, x [15], S33, 0x1fa27cf8); /* 47 */
        HH (b, c, d, a, x [ 2], S34, 0xc4ac5665); /* 48 */

        // Round 4
        II (a, b, c, d, x [ 0], S41, 0xf4292244); /* 49 */
        II (d, a, b, c, x [ 7], S42, 0x432aff97); /* 50 */
        II (c, d, a, b, x [14], S43, 0xab9423a7); /* 51 */
        II (b, c, d, a, x [ 5], S44, 0xfc93a039); /* 52 */
        II (a, b, c, d, x [12], S41, 0x655b59c3); /* 53 */
        II (d, a, b, c, x [ 3], S42, 0x8f0ccc92); /* 54 */
        II (c, d, a, b, x [10], S43, 0xffeff47d); /* 55 */
        II (b, c, d, a, x [ 1], S44, 0x85845dd1); /* 56 */
        II (a, b, c, d, x [ 8], S41, 0x6fa87e4f); /* 57 */
        II (d, a, b, c, x [15], S42, 0xfe2ce6e0); /* 58 */
        II (c, d, a, b, x [ 6], S43, 0xa3014314); /* 59 */
        II (b, c, d, a, x [13], S44, 0x4e0811a1); /* 60 */
        II (a, b, c, d, x [ 4], S41, 0xf7537e82); /* 61 */
        II (d, a, b, c, x [11], S42, 0xbd3af235); /* 62 */
        II (c, d, a, b, x [ 2], S43, 0x2ad7d2bb); /* 63 */
        II (b, c, d, a, x [ 9], S44, 0xeb86d391); /* 64 */

        _state [0] += a;
        _state [1] += b;
        _state [2] += c;
        _state [3] += d;
        //Console.PrintF ("post-transform: %.8X%.8X%.8X%.8X", _state[0], _state[1], _state[2], _state[3]);
    }

    const BlockSize = 512;

    void Reset () {
        _count = 0;

        for (int i = 0; i < 64; i++)
            _buffer [i] = 0;

        _state [0] = 0x67452301;
        _state [1] = 0xefcdab89;
        _state [2] = 0x98badcfe;
        _state [3] = 0x10325476;
    }

    bool Put (S7_TZK_ArrayI32 data) {
        uint i, index, partLen;
        uint inputLen = data.Size ();
        //Console.PrintF ("%d", inputLen);
        let tmpBuffer = new ('S7_TZK_ArrayI32');

        // Compute number of bytes mod 64
        index = uint ((uint (_count) >>> 3) & (64 - 1));

        // Update number of bits
        _count += inputLen * 8;

        partLen = 64 - index;

        // Transform as many times as possible
        if (inputLen >= partLen) {
            for (int j = 0; j < partLen; j++)
                _buffer [index + j] = (data.Values [j] & 0xFF);

            tmpBuffer.Clear ();
            for (int j = 0; j < 64; j+=4) {
                tmpBuffer.Push (
                    ((_buffer [j+3] << 8*3) & 0xFF000000) |
                    ((_buffer [j+2] << 8*2) & 0x00FF0000) |
                    ((_buffer [j+1] << 8*1) & 0x0000FF00) |
                    ( _buffer [j]           & 0x000000FF)
                );
            }

            transform (tmpBuffer);
            for (i = partLen; i + 64 < inputLen; i += 64) {
                tmpBuffer.Clear ();
                for (int j = 0; j < 64; j+=4) {
                    tmpBuffer.Push (
                        ((data.Values [i+j+3] << 8*3) & 0xFF000000) |
                        ((data.Values [i+j+2] << 8*2) & 0x00FF0000) |
                        ((data.Values [i+j+1] << 8*1) & 0x0000FF00) |
                        ( data.Values [i+j]           & 0x000000FF)
                    );
                }

                transform (tmpBuffer);
            }

            index = 0;
        } else
            i = 0;

        /* Buffer remaining input */
        if (inputLen - i) {
            for (int j = 0; j < inputLen-i; j++)
                _buffer [index+j] = data.Values [i+j] & 0xFF;
        }

        return true;
    }

    string Finish () {
        string data = "";
        let padArr = new ('S7_TZK_ArrayI32'), bitsArr = new ('S7_TZK_ArrayI32');
        uint index, padLen;
        
        // Save number of bits
        bitsArr.Clear ();
        bitsArr.Push ( _count          & 0xFF);
        bitsArr.Push ((_count >>> 8*1) & 0xFF);
        bitsArr.Push ((_count >>> 8*2) & 0xFF);
        bitsArr.Push ((_count >>> 8*3) & 0xFF);
        for (int i = 0; i < 4; i++)
            bitsArr.Push (0);

        // Pad out to 56 mod 64
        index = uint ((uint (_count) >>> 3) & (64 - 1));
        padLen = (index < 56) ? (56 - index) : (120 - index);

        padArr.Clear ();
        for (int i = 0; i < padLen; i++)
            padArr.Push (_padding [i]);

        Put (padArr);

        // Append length (before padding)
        Put (bitsArr);

        //Store state in digest
        for (int i = 0; i < 4; i++) {
            uint val = _state [i];
            data.AppendFormat ("%.2X%.2X%.2X%.2X", val & 0xFF, (val >>> 8*1) & 0xFF, (val >>> 8*2) & 0xFF, (val >>> 8*3) & 0xFF);
        }

        /* Zeroize sensitive information. */
        Reset ();
        return data;
    }
}