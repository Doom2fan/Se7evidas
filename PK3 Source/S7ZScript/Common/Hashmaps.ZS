/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

class S7_Hashmap_StrObj {
    static S7_Hashmap_StrObj Create () {
        let ret = new ('S7_Hashmap_StrObj');

        ret.Keys.Clear ();
        ret.Values.Clear ();

        return ret;
    }

    protected Array<string> Keys;
    protected Array<Object> Values;

    void GetKeys   (S7_TZK_ArrayStr other) { other.Values.Copy (Keys  ); }
    void GetValues (S7_TZK_ArrayObj other) { other.Values.Copy (Values); }

    uint Size () { return Keys.Size (); }

    void Copy (S7_Hashmap_StrObj other) {
        Keys.Copy (other.Keys);
        Values.Copy (other.Values);
    }

    void Move (S7_Hashmap_StrObj other) {
        Keys.Move (other.Keys);
        Values.Move (other.Values);
    }

    string Find (Object item) {
        int idx = Values.Find (item);

        if (idx == Values.Size ())
            return "";

        return Keys [idx];
    }

    Object Get (string key) {
        if (key == "" || !key)
            ThrowAbortException ("The key cannot be null or an empty string");

        int idx = Keys.Find (key);

        if (idx == Keys.Size ())
            return null;

        return Values [idx];
    }

    void Set (string key, Object val) {
        if (key == "" || !key)
            ThrowAbortException ("The key cannot be null or an empty string");

        int idx = Keys.Find (key);

        if (idx == Keys.Size ()) {
            Keys.Push (key);
            Values.Push (val);

            return;
        }

        Values [idx] = val;
    }

    void Push (string key, Object val) {
        if (key == "" || !key)
            ThrowAbortException ("The key cannot be null or an empty string");

        Keys.Push (key);
        Values.Push (val);
    }

    void Delete (string key) {
        int idx = Keys.Find (key);

        if (idx == Keys.Size ())
            return;

        Keys.Delete (idx, 1);
        Values.Delete (idx, 1);
    }

    void Clear () {
        Keys.Clear ();
        Values.Clear ();
    }
}