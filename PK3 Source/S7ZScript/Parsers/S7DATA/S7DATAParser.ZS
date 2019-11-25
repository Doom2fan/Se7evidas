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

class S7_S7DataParser : S7_BaseParser {
    static S7_S7DataParser Create (S7_TZK_Stream input) {
        let parser = new ('S7_S7DataParser');
        parser.m_Stream = input;
        parser.m_Tokenizer = S7_TZK_Tokenizer.Create (input);
        return parser;
    }

    protected S7_S7Data parsedData;

    S7_S7Data GetOutput () {
        if (m_ParsingException) return null;
        return parsedData;
    }
    void SetInitialData (S7_S7Data data) { parsedData = data; }

    override bool Parse () {
        m_ParsingException = null;

        S7_TZK_Token tk;

        if (!parsedData)
            parsedData = new ('S7_S7Data');

        while ((tk = m_Tokenizer.Next ()).type != TOK_EOF) { // Read until the end of the file
            // Error out if we don't have an identifier
            if (tk.type != TOK_Identifier) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.Parse", TOK_Identifier, tk);
                return false;
            }

            // Are we parsing a map data block?
            switch (tk.type) {
            case TOK_Identifier:
                if (tk.value ~== "Include")
                    ParseInclude ();
                else if (tk.value ~== "MapData")
                    ParseMapData ();
                else if (tk.value ~== "Shop")
                    ParseShop ();
                else {
                    m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", tk.value), "S7_S7DataParser.Parse", tkn: tk);
                    break;
                }
                break;
            default:
                m_ParsingException = S7_UnexpectedToken.Create ("S7_S7DataParser.Parse", tk);
                break;
            }

            if (m_ParsingException != null)
                break;
        }

        if (m_ParsingException != null) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_S7DataParser.Parse", m_ParsingException);
            return false;
        }

        return true;
    }

    protected void ParseInclude () {
        string inclPath = "";
        ParseGenericType (inclPath, VT_String);

        S7_TZK_Token tk;
        if ((tk = m_Tokenizer.Next ()).type != TOK_Semicolon) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseInclude", TOK_Semicolon, tk);
            return;
        }

        if (m_ParsingException != null)
            return;

        let lmpNum = Wads.CheckNumForFullName (inclPath);

        if (lmpNum == -1) {
            m_ParsingException = S7_ParsingException.Create (String.Format ("Could not find include file \"%s\"", inclPath), "S7_S7DataParser.Parse", m_ParsingException);
            return;
        }

        let lump   = S7_TZK_LumpStream.Create (lmpNum);
        let parser = S7_S7DataParser.Create (lump);

        parser.SetInitialData (parsedData);

        if (parser.Parse ()) {
            parsedData = parser.GetOutput ();
        } else
            m_ParsingException = parser.GetError ();
    }
}