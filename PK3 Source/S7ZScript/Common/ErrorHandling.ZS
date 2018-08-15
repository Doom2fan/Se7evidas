/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

class S7_Error {
    protected string message;
    protected string source;

    virtual string GetMessage () { return message; }
    virtual void SetMessage (string msg) { message = msg; }
    virtual string GetSource () { return source; }
    virtual void SetSource (string src) { source = src; }

    static S7_Error Create (string message = "", string source = "") {
        let ret = new ("S7_Error");
        ret.message = message;
        ret.source = source;
        return ret;
    }
}

class S7_Exception : S7_Error {
    S7_Exception innerException;

    static S7_Exception Create (string message = "", string source = "", S7_Exception innerException = NULL) {
        let ret = new ("S7_Exception");
        ret.message = message;
        ret.source = source;
        ret.innerException = innerException;
        return ret;
    }

    static string GetTrace (S7_Exception ex) {
        if (!ex) return "";

        string trace = "";
        S7_Exception e = ex;

        while (e) {
            string msg = e.GetMessage (), src = e.GetSource ();
            string curLine = "";

            if (msg) {
                if (e.innerException != NULL && src)
                    curLine.AppendFormat ("-------------------------------------------------------------------------------\n");

                curLine.AppendFormat ("%s [%s]\n", e.GetClassName (), msg);
            }
            if (src)
                curLine.AppendFormat ("  called from %s", src);

            if (msg || src)
                trace = String.Format ("%s\n%s", curLine, trace);

            e = e.innerException;
        }

        return trace;
    }
}