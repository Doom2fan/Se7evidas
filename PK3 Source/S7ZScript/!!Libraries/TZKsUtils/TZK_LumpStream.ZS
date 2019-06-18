// Copyright (c) 2017 Benjamin Moir. All rights reserved.
// This work is licensed under the terms of the MIT license.
// To obtain a copy, visit <https://opensource.org/licenses/MIT>.

class S7_TZK_LumpStream : S7_TZK_StringStream
{
    override bool CanWrite() { return false; }
    override int Length() { return m_Data.Length() - 1; }
    override void Write(int c) { }
    override void Flush() { }

    static S7_TZK_LumpStream Create(int lumpID)
    {
        let ss = new("S7_TZK_LumpStream");
        ss.m_Data = Wads.ReadLump(lumpID);
        return ss;
    }
}
