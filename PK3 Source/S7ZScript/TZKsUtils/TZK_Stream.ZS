// Copyright (c) 2017 Benjamin Moir. All rights reserved.
// This work is licensed under the terms of the MIT license.  
// To obtain a copy, visit <https://opensource.org/licenses/MIT>.

enum ESeekOrigin
{
    SEEK_Begin,
    SEEK_Current,
    SEEK_End,
}

/*abstract*/ class TZK_Stream
{
    protected int m_Position;

    virtual bool CanRead() { return false; }
    virtual bool CanWrite() { return false; }
    virtual bool CanSeek() { return true; }
    virtual int Length() { return 0; }
    virtual int Position() { return m_Position; }
    virtual int Read() { return -1; }
    virtual int Peek() { return -1; }
    virtual void Write(int c) {}
    virtual void Flush() {}
    virtual bool EOF() { return Position() >= Length(); }

    virtual int Seek(int offset, ESeekOrigin origin)
    {
        switch(origin)
        {
        case SEEK_Begin:
            m_Position = offset;
            break;
        case SEEK_Current:
            m_Position += offset;
            break;
        case SEEK_End:
            m_Position = Length() + offset;
            break;
        }

        if(m_Position > Length()) m_Position = Length();
        if(m_Position < 0) m_Position = 0;

        return m_Position;
    }
}
