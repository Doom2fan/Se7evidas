// Copyright (c) 2017 Benjamin Moir. All rights reserved.
// This work is licensed under the terms of the MIT license.
// To obtain a copy, visit <https://opensource.org/licenses/MIT>.

// A stream that operates on strings
class TZK_StringStream : TZK_Stream
{
    protected bool m_Writable;
    protected string m_Data;
    protected string m_WriteBuffer;

    override bool CanRead() { return true; }
    override bool CanWrite() { return m_Writable; }
    override int Length() { return m_Data.Length(); }
    override bool EOF() { return Position() >= Length(); }

    override int Read()
    {
        if(EOF()) return -1;
        int c = m_Data.CharCodeAt(Position()) & 255;
        Seek(1, SEEK_Current);
        return c;
    }

    override int Peek()
    {
        int pos = Position();
        int c   = Read();
        Seek(pos, SEEK_Begin);
        return c;
    }

    override void Write (int c) {
        if (!m_Writable)
            return;

        m_WriteBuffer.AppendFormat ("%c", c & 0xFF);
    }

    override void Flush () {
        if (!m_Writable)
            return;

        m_Data.AppendFormat ("%s", m_WriteBuffer);
        m_WriteBuffer = "";
        Seek (0, SEEK_End);
    }

    static TZK_StringStream Create(string data, bool writable = false)
    {
        let ss = new("TZK_StringStream");
        ss.m_Data = data;
        ss.m_Writable = writable;
        ss.m_WriteBuffer = "";
        return ss;
    }
}
