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

enum EParserError {
    ERR_None,
    ERR_BadToken,
    ERR_UnknownKeyword,
    ERR_Misc,
}

enum EValueType {
    VT_String,
    VT_Identifier,
    VT_Integer,
    VT_Float,
    VT_Vec2,
    VT_Vec3,
}

class S7_ParsingException : S7_Exception {
    bool notException;
    EParserError error;
    S7_TZK_Token tkn;

    override string GetMessage () {
        if (tkn)
            return String.Format ("Line %d, char %d: %s", tkn.line, tkn.charPos, message);

        return message;
    }

    static S7_ParsingException Create (string msg = "", string src = "", S7_Exception inner = null,
        EParserError err = ERR_None, S7_TZK_Token tkn = null, bool notEx = false
    ) {
        let ret = new ('S7_ParsingException');
        ret.message = msg; ret.source = src; ret.innerException = inner;
        ret.error = err;
        ret.tkn = tkn;
        ret.notException = notEx;
        return ret;
    }
    static S7_ParsingException CreateParserError (string src, EParserError err, S7_TZK_Token tkn) {
        return Create ("", src, null, err, tkn, false);
    }
}

class S7_UnexpectedToken : S7_ParsingException {
    string fakeValue;

    override string GetMessage () {
        string val = "";

        if (!fakeValue.Length ())
            val = tkn.value;
        else
            val = fakeValue;

        return String.Format ("Line %d, char %d: Unexpected token \"%s\" (%s)", tkn.line, tkn.charPos, val, tkn.TypeString ());
    }
    override void SetMessage (string msg) { }

    static S7_UnexpectedToken Create (string src, S7_TZK_Token tkn, string value = "") {
        let ret = new ('S7_UnexpectedToken');
        ret.message = ""; ret.innerException = null; ret.notException = false;
        ret.source = src;
        ret.error = ERR_BadToken;
        ret.tkn = tkn;
        ret.fakeValue = value;
        return ret;
    }
}

class S7_BadTokenPE : S7_ParsingException {
    ETokenType type;

    override string GetMessage () {
        return String.Format ("Line %d, char %d: Expected %s, got \"%s\" (%s)", tkn.line, tkn.charPos, S7_TZK_Token.AsString (type), tkn.value, tkn.TypeString ());
    }
    override void SetMessage (string msg) { }

    static S7_BadTokenPE Create (string src, ETokenType expectedType, S7_TZK_Token tkn) {
        let ret = new ('S7_BadTokenPE');
        ret.message = ""; ret.innerException = null; ret.notException = false;
        ret.source = src;
        ret.error = ERR_BadToken;
        ret.tkn = tkn;
        ret.type = expectedType;
        return ret;
    }
}

class S7_BaseParser {
    protected S7_TZK_Stream    m_Stream;
    protected S7_TZK_Tokenizer m_Tokenizer;
    protected S7_ParsingException m_ParsingException;

    S7_ParsingException GetError () { return m_ParsingException; }

    string GetTrace (bool full = false) {
        if (!m_ParsingException) return "";
        string trace;

        if (full)
            trace = S7_Exception.GetTrace (m_ParsingException);
        else
            trace = m_ParsingException.GetMessage ();

        return trace;
    }

    protected bool ParseGenericType (out string value, EValueType valueType) {
        value = "";
        ETokenType tType;

        switch (valueType) {
            case VT_String: tType = TOK_String; break;
            case VT_Identifier: tType = TOK_Identifier; break;
            case VT_Integer: tType = TOK_Number; break;
            default: return false;
        }

        S7_TZK_Token t = m_Tokenizer.Next ();
        if (t.type != tType) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseGenericType", tType, t);
            return false;
        }

        value = t.value;
        return true;
    }

    protected bool ParseFloat (out string value) {
        value = "";
        S7_TZK_Token t = m_Tokenizer.Next ();
        string intPart = "0", fracPart = "0";
        bool parseDec;

        if (t.type == TOK_Number)
            intPart = t.value;
        else if (t.type == TOK_Period)
            parseDec = true;
        else {
            m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseFloat", TOK_Number, t);
            return false;
        }

        if (parseDec || m_Tokenizer.Peek ().type == TOK_Period) {
            if (!parseDec) m_Tokenizer.Next ();

            if (parseDec && (t = m_Tokenizer.Peek ()).type != TOK_Number) {
                m_ParsingException = m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseFloat", TOK_Number, t);
                return false;
            }

            if ((t = m_Tokenizer.Peek ()).type == TOK_Number) {
                t = m_Tokenizer.Next ();
                fracPart = t.value;
            }
        }

        value = String.Format ("%s.%s", intPart, fracPart);
        return true;
    }

    protected bool ParseVector (out string value, bool vec3) {
        value = "";
        S7_TZK_Token t;

        if ((t = m_Tokenizer.Next ()).type != TOK_ParenO) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseVector", TOK_ParenO, t);
            return false;
        }
        string xStr, yStr, zStr;
        ParseFloat (xStr);

        t = m_Tokenizer.Next ();

        if (t.type == TOK_ParenC) {
            zStr = yStr = xStr;
            return true;
        } else if (t.type == TOK_Comma) {
            ParseFloat (yStr);
            if (m_ParsingException != null) {
                m_ParsingException = S7_ParsingException.Create ("", "S7_BaseParser.ParseVector", m_ParsingException);
                return false;
            }

            if (vec3) {
                if ((t = m_Tokenizer.Next ()).type != TOK_Comma) {
                    m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseVector", TOK_Comma, t);
                    return false;
                }

                ParseFloat (zStr);
                if (m_ParsingException != null) {
                    m_ParsingException = S7_ParsingException.Create ("", "S7_BaseParser.ParseVector", m_ParsingException);
                    return false;
                }
            }

            if ((t = m_Tokenizer.Next ()).type != TOK_ParenC) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseVector", TOK_ParenC, t);
                return false;
            }
        } else {
            m_ParsingException = S7_UnexpectedToken.Create ("S7_BaseParser.ParseVector", t);
            return false;
        }

        if (vec3) value = String.Format ("%s:%s:%s", xStr, xStr, xStr);
        else      value = String.Format ("%s:%s"   , xStr, xStr);
        return true;
    }

    protected bool ParseValue (out string value, EValueType valueType) {
        switch (valueType) {
            case VT_Float: ParseFloat (value); break;
            case VT_Vec2: ParseVector (value, false); break;
            case VT_Vec3: ParseVector (value, true); break;

            case VT_String:
            case VT_Identifier:
            case VT_Integer:
            default: ParseGenericType (value, valueType); break;
        }

        if (m_ParsingException != null) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_BaseParser.ParseValue", m_ParsingException);
            return false;
        }

        return true;
    }

    protected bool ParseAssignment (out string value, EValueType valueType) {
        value = "";
        S7_TZK_Token t;

        if ((t = m_Tokenizer.Next ()).type != TOK_Equals) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseAssignment", TOK_Equals, t);
            return false;
        }

        ParseValue (value, valueType);

        if (m_ParsingException != null) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_BaseParser.ParseAssignment", m_ParsingException);
            return false;
        }

        if ((t = m_Tokenizer.Next ()).type != TOK_Semicolon) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseAssignment", TOK_Semicolon, t);
            return false;
        }

        return true;
    }

    protected bool ParseArrayAssignment (out Array<string> values, EValueType valueType) {
        S7_TZK_Token t;

        if ((t = m_Tokenizer.Next ()).type != TOK_Equals) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseArrayAssignment", TOK_Equals, t);
            return false;
        }

        ParseArray (values, valueType);

        if (m_ParsingException != null) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_BaseParser.ParseArrayAssignment", m_ParsingException);
            return false;
        }

        if ((t = m_Tokenizer.Next ()).type != TOK_Semicolon) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseArrayAssignment", TOK_Semicolon, t);
            return false;
        }

        return true;
    }

    protected bool ParseArray (out Array<string> values, EValueType valueType) {
        values.Clear ();
        S7_TZK_Token t;

        if ((t = m_Tokenizer.Next ()).type != TOK_BrackO) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseArray", TOK_BrackO, t);
            return false;
        }

        while ((t = m_Tokenizer.Peek ()).type != TOK_BrackC) {
            string val = "";

            ParseValue (val, valueType);
            values.Push (val);

            if (m_ParsingException != null) {
                m_ParsingException = S7_ParsingException.Create ("", "S7_BaseParser.ParseArray", m_ParsingException);
                values.Clear ();
                return false;
            }

            t = m_Tokenizer.Next ();
            if (t.type == TOK_BrackC) // Don't require a comma if it's the last value in the array.
                return true;
            else if (t.type != TOK_Comma) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_BaseParser.ParseArray", TOK_Comma, t);
                values.Clear ();
                return false;
            }
        }

        m_Tokenizer.Next ();

        return true;
    }

    virtual bool Parse () { return false; }
}