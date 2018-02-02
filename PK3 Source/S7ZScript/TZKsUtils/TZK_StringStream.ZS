// Copyright (c) 2017 Benjamin Moir. All rights reserved.
// This work is licensed under the terms of the MIT license.
// To obtain a copy, visit <https://opensource.org/licenses/MIT>.

// A stream that operates on strings
class TZK_StringStream : TZK_Stream
{
    protected string m_Data;

    override bool CanRead() { return true; }
    override bool CanWrite() { return false; }
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

    static TZK_StringStream Create(string data)
    {
        let ss = new("TZK_StringStream");
        ss.m_Data = data;
        return ss;
    }
}
