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