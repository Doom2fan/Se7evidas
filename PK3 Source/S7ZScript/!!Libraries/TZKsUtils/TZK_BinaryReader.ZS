// Copyright (c) 2017 Benjamin Moir. All rights reserved.
// This work is licensed under the terms of the MIT license.
// To obtain a copy, visit <https://opensource.org/licenses/MIT>.

class S7_TZK_BinaryReader
{
    private S7_TZK_Stream m_BaseStream;

    S7_TZK_Stream GetBaseStream()
    {
        return m_BaseStream;
    }

    private int Read()
    {
        return m_BaseStream.Read();
    }

    private int Peek()
    {
        return m_BaseStream.Peek();
    }

    int ReadByte()
    {
        return Read();
    }

    int ReadInt16()
    {
        return
            (Read() << 0) |
            (Read() << 8);
    }

    int ReadInt32()
    {
        return
            (Read() <<  0) |
            (Read() <<  8) |
            (Read() << 16) |
            (Read() << 24);
    }

    int ReadInt64()
    {
        return
            (Read() <<  0) |
            (Read() <<  8) |
            (Read() << 16) |
            (Read() << 24) |
            (Read() << 32) |
            (Read() << 40) |
            (Read() << 48) |
            (Read() << 56);
    }

    void ReadBytes(int count, out Array<int8> arr)
    {
        arr.Clear();
        for(int i = 0; i < count; i++)
            arr.Push(Read());
    }

    string ReadString(int length = -1)
    {
        string result = "";

        if(length > 0)
            for(int i = 0; i < length; i++)
        {
            result.AppendFormat("%c", Read());
        }
        else
            while(true)
        {
            int c = Read();
            if(c == 0) break;
            result.AppendFormat("%c", c);
        }

        return result;
    }

    float ReadFloat32()
    {
        return 0.0;
    }

    double ReadFloat64()
    {
        return 0.0;
    }

    static S7_TZK_BinaryReader Create(S7_TZK_Stream input)
    {
        let br = new("S7_TZK_BinaryReader");
        br.m_BaseStream = input;
        return br;
    }
}
