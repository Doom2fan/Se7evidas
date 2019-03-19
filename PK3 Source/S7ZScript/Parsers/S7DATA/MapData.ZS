/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
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

extend class S7_S7DataParser {
    protected void ParseMapData () {
        S7_TZK_Token t;
        // We expect an opening brace '{' to immediately follow
        if ((t = m_Tokenizer.Next ()).type != TOK_BraceO) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseMapData", TOK_BraceO, t);
            return;
        }

        // We're going to keep reading tokens until we hit a closing brace '}'
        for (; (t = m_Tokenizer.Next ()).type != TOK_BraceC;) {
            if (t.type != TOK_Identifier) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseMapData", TOK_Identifier, t);
                return;
            }

            if (t.value ~== "Map")
                ParseMapData_Map ();
            else {
                m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseMapData", tkn: t);
                return;
            }

            if (m_ParsingException != NULL)
                break;
        }

        if (m_ParsingException != NULL) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_S7DataParser.ParseMapData", m_ParsingException);
            return;
        }
    }

    protected void ParseMapData_Map () {
        S7_TZK_Token t;
        let mData = new ('S7_S7Data_MapData');
        Array<string> hashes; hashes.Clear ();

        do {
            string tmpHash;

            if (hashes.Size () > 0) // If hashes has anything in it, that means the peeked token was a comma.
                m_Tokenizer.Next (); // Consume the comma.

            t = m_Tokenizer.Peek ();
            if (!ParseGenericType (tmpHash, VT_String))
                return;

            if (!S7_MD5.IsHashValid (tmpHash)) {
                m_ParsingException = S7_ParsingException.Create (String.Format ("Invalid MD5 hash \"%s\"", tmpHash), "S7_S7DataParser.ParseMapData_Map", tkn: t);
                return;
            }

            hashes.Push (tmpHash);
        } while ((t = m_Tokenizer.Peek ()).type == TOK_Comma);

        if ((t = m_Tokenizer.Next ()).type != TOK_BraceO) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseMapData_Map", TOK_BraceO, t);
            return;
        }

        for (; (t = m_Tokenizer.Next ()).type != TOK_BraceC;) {
            if (t.type != TOK_Identifier) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseMapData", TOK_Identifier, t);
                return;
            }

            if (t.value ~== "corruption") {
                string valStr;
                ParseAssignment (valStr, VT_Float);

                if (valStr)
                    mData.corruption = Clamp (valStr.ToDouble (), 0.0, 1.0);
            } else {
                m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown identifier %s", t.value), "S7_S7DataParser.ParseMapData_Map", tkn: t);
                return;
            }

            if (m_ParsingException != NULL)
                break;
        }

        if (m_ParsingException != NULL) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_S7DataParser.ParseMapData_Map", m_ParsingException);
            return;
        }

        for (int i = 0; i < hashes.Size (); i++) {
            let mDataMap = new ('S7_S7Data_Map');

            mDataMap.hash = hashes [i];
            mDataMap.data = mData;

            parsedData.mapData.Push (mDataMap);
        }
    }
}