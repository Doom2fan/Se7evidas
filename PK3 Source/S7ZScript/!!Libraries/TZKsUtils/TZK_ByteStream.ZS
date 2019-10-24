// Copyright (c) 2017 Chronos Ouroboros. All rights reserved.
// This work is licensed under the terms of the MIT license.
// To obtain a copy, visit <https://opensource.org/licenses/MIT>.

// A stream that operates on byte arrays
class S7_TZK_ByteStream : S7_TZK_Stream {
    protected Array<int> m_Data;
    protected Array<int> m_WriteBuffer;

    override bool CanRead () { return true; }
    override bool CanWrite () { return true; }
    override int Length () { int ret = m_Data.Size (); return ret; }
    override bool EOF () { return Position () >= Length (); }
    override void Write (int c) { m_WriteBuffer.Push (c & 0xFF); }

    override int Read () {
        if (EOF ()) return -1;
        int b = (m_Data [Position ()]) & 255;
        Seek (1, SEEK_Current);
        return b;
    }

    override int Peek () {
        int pos = Position ();
        int b   = Read ();
        Seek (pos, SEEK_Begin);
        return b;
    }

    override void Flush () {
        for (int i = 0; i < m_WriteBuffer.Size (); i++)
            m_Data.Push (m_WriteBuffer [i]);

        m_WriteBuffer.Clear ();
        Seek (0, SEEK_End);
    }

    static S7_TZK_ByteStream Create (Array<int> data) {
        let bs = new ("S7_TZK_ByteStream");
        bs.m_Data.Clear ();
        if (data) bs.m_Data.Copy (data);
        bs.m_WriteBuffer.Clear ();
        return bs;
    }
}
