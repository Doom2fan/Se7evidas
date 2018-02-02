// Copyright (c) 2017 Chronos Ouroboros. All rights reserved.
// This work is licensed under the terms of the MIT license.
// To obtain a copy, visit <https://opensource.org/licenses/MIT>.

// A stream that operates on byte arrays
class TZK_ByteStream : TZK_Stream {
    protected TZK_ArrayI32 m_Data;

    override bool CanRead () { return true; }
    override bool CanWrite () { return false; }
    override int Length () { int ret = m_Data.Size (); return ret; }
    override bool EOF () { return Position () >= Length (); }

    override int Read () {
        if (EOF ()) return -1;
        int b = (m_Data.Values [Position ()]) & 255;
        Seek (1, SEEK_Current);
        return b;
    }

    override int Peek () {
        int pos = Position ();
        int b   = Read ();
        Seek (pos, SEEK_Begin);
        return b;
    }

    static TZK_ByteStream Create (TZK_ArrayI32 data) {
        let bs = new ("TZK_ByteStream");
        bs.m_Data = new ("TZK_ArrayI32");
        bs.m_Data.Clear ();
        bs.m_Data.Copy (data);
        return bs;
    }
}
