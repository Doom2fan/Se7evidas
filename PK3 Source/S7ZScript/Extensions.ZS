class SplitResult { Array<String> Result; }
class S7_Extensions {
    static SplitResult Split (string input, string sep) {
        int sepLen = sep.Length ();
        int idx;
        string cur = input;
        SplitResult ret = new ("SplitResult");

        while ((idx = cur.IndexOf (sep)) >= 0) {
            ret.Result.Push (cur.Left (idx));
            cur = cur.Mid (idx + sepLen, cur.Length () - (idx + sepLen));
        }
        ret.Result.Push (cur);

        return ret;
    }
}