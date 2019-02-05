enum ETokenType
{
    TOK_Identifier,
    TOK_Number,
    TOK_String,
    TOK_Bang,
    TOK_Hash,
    TOK_Dollar,
    TOK_Percent,
    TOK_And,
    TOK_ParenO,
    TOK_ParenC,
    TOK_Asterisk,
    TOK_Plus,
    TOK_Comma,
    TOK_Minus,
    TOK_Period,
    TOK_Slash,
    TOK_Colon,
    TOK_Semicolon,
    TOK_LessThan,
    TOK_Equals,
    TOK_MoreThan,
    TOK_Question,
    TOK_At,
    TOK_BrackO,
    TOK_Backslash,
    TOK_BrackC,
    TOK_Exponent,
    TOK_Backquote,
    TOK_BraceO,
    TOK_VerticalBar,
    TOK_BraceC,
    TOK_Tilde,
    TOK_EOF,
    TOK_Unknown,
}

class S7_TZK_Token
{
    ETokenType type;
    string value;
    int line;
    int charPos;

    static string AsString(ETokenType type)
    {
        switch(type)
        {
        case TOK_Identifier: return "TOK_Identifier";
        case TOK_Number: return "TOK_Number";
        case TOK_String: return "TOK_String";
        case TOK_Bang: return "TOK_Bang";
        case TOK_Hash: return "TOK_Hash";
        case TOK_Dollar: return "TOK_Dollar";
        case TOK_Percent: return "TOK_Percent";
        case TOK_And: return "TOK_And";
        case TOK_ParenO: return "TOK_ParenO";
        case TOK_ParenC: return "TOK_ParenC";
        case TOK_Asterisk: return "TOK_Asterisk";
        case TOK_Plus: return "TOK_Plus";
        case TOK_Comma: return "TOK_Comma";
        case TOK_Minus: return "TOK_Minus";
        case TOK_Period: return "TOK_Period";
        case TOK_Slash: return "TOK_Slash";
        case TOK_Colon: return "TOK_Colon";
        case TOK_Semicolon: return "TOK_Semicolon";
        case TOK_LessThan: return "TOK_LessThan";
        case TOK_Equals: return "TOK_Equals";
        case TOK_MoreThan: return "TOK_MoreThan";
        case TOK_Question: return "TOK_Question";
        case TOK_At: return "TOK_At";
        case TOK_BrackO: return "TOK_BrackO";
        case TOK_Backslash: return "TOK_Backslash";
        case TOK_BrackC: return "TOK_BrackC";
        case TOK_Exponent: return "TOK_Exponent";
        case TOK_Backquote: return "TOK_Backquote";
        case TOK_BraceO: return "TOK_BraceO";
        case TOK_VerticalBar: return "TOK_VerticalBar";
        case TOK_BraceC: return "TOK_BraceC";
        case TOK_Tilde: return "TOK_Tilde";
        case TOK_EOF: return "TOK_EOF";
        default:
        case TOK_Unknown: return "TOK_Unknown";
        }
    }

    string TypeString()
    {
        return AsString(type);
    }
}

class S7_TZK_Tokenizer
{
    protected int posLine, posChar;
    private S7_TZK_Stream m_Stream;

    static S7_TZK_Tokenizer Create(S7_TZK_Stream input)
    {
        if(!input.CanRead() || !input.CanSeek())
            return null;

        let tok = new("S7_TZK_Tokenizer");

        tok.posLine = 1;
        tok.posChar = 1;
        tok.m_Stream = input;

        return tok;
    }

    private void SkipWhitespace()
    {
        while(S7_TZK_Character.IsWhitespace(m_Stream.Peek()))
            ReadChar();
    }

    virtual S7_TZK_Token Peek()
    {
        let curLine = posLine;
        let curChar = posChar;
        let pos = m_Stream.Position();
        let tok = Next();
        m_Stream.Seek(pos, SEEK_Begin);
        posLine = curLine;
        curChar = posChar;
        return tok;
    }

    protected virtual int ReadChar()
    {
        int ret = m_Stream.Read();

        if(ret == ASCII_LF)
        {
            posLine++;
            posChar = 1;
        }
        else
        {
            posChar++;
        }

        return ret;
    }

    virtual S7_TZK_Token Next()
    {
        SkipWhitespace();
        let tk = new("S7_TZK_Token");

        // are we at the end of the stream?
        if(m_Stream.EOF())
        {
            tk.type = TOK_EOF;
            return tk;
        }

        tk.line = posLine;
        tk.charPos = posChar;
        let c    = ReadChar();
        tk.value = S7_TZK_Character.ToString(c);
        switch(c)
        {
        case ASCII_DblQuote:
        case ASCII_Quote:
        {
            tk.type  = TOK_String;
            tk.value = "";

            let end = c;

            do
            {
                c = ReadChar();

                // handle escape sequences
                if(c == ASCII_Backslash)
                {
                    let peek = m_Stream.Peek();
                    switch(peek)
                    {
                    case ASCII_DblQuote: // '"'
                    case ASCII_Quote: // '''
                    case ASCII_Backslash: // '\'
                        tk.value.AppendFormat("%c", peek);
                        ReadChar();
                        break;
                    case ASCII_Lower_A: // 'a'
                        tk.value.AppendFormat("%s", "\a");
                        ReadChar();
                        break;
                    case ASCII_Lower_N: // 'n'
                        tk.value.AppendFormat("%s", "\n");
                        ReadChar();
                        break;
                    case ASCII_Lower_R: // 'r'
                        tk.value.AppendFormat("%s", "\r");
                        ReadChar();
                        break;
                    default: // ignore unknown sequences
                        tk.value.AppendFormat("%c", c);
                        break;
                    }
                }
                else if(c != end)
                    tk.Value.AppendFormat("%c", c);
            } while(c != end);
            break;
        }

        case ASCII_Slash:
        {
            switch(m_Stream.Peek())
            {
            case ASCII_Asterisk: // '/*' - multi-line comment
                c = ReadChar();
                while(true)
                {
                    c = ReadChar();

                    // have we encountered "*/"?
                    if(c == ASCII_Asterisk && m_Stream.Peek() == ASCII_Slash)
                    {
                        ReadChar();
                        break;
                    }

                    // are we at the end of the stream?
                    if(m_Stream.EOF()) break;
                }
                tk.Destroy();
                return Next();
            case ASCII_Slash: // '//' - single-line comment
                do
                {
                    // keep reading until we reach a
                    // new line or the end of the stream.
                    c = ReadChar();
                } while(c != ASCII_LF && !m_Stream.EOF())
                tk.Destroy();
                return Next();
            }

            tk.type = TOK_Slash;
            break;
        }

        case ASCII_Underscore:
        default:
        {
            // identifiers are made up of alphanumeric characters
            // and underscores. However, they cannot begin with a digit.
            if(S7_TZK_Character.IsLetter(c) || c == ASCII_Underscore)
            {
                tk.type  = TOK_Identifier;
                tk.value = "";

                let peek = m_Stream.Peek();

                while(S7_TZK_Character.IsLetterOrDigit(c) || c == ASCII_Underscore)
                {
                    tk.value.AppendFormat("%c", c);

                    // are we at the end of the identifier?
                    if(!S7_TZK_Character.IsLetterOrDigit(peek) && peek != ASCII_Underscore)
                        break;

                    c = ReadChar();
                    peek = m_Stream.Peek();
                }
            }
            else if(S7_TZK_Character.IsDigit(c))
            {
                tk.type  = TOK_Number;
                tk.value = "";

                let peek = m_Stream.Peek();

                while(S7_TZK_Character.IsDigit(c))
                {
                    tk.value.AppendFormat("%c", c);

                    // are we at the end of the digit?
                    if(!S7_TZK_Character.IsDigit(peek))
                        break;

                    c = ReadChar();
                    peek = m_Stream.Peek();
                }
            }
            else
                tk.type = TOK_Unknown;
            break;
        }

        case ASCII_Bang:        tk.type = TOK_Bang; break;
        case ASCII_Hash:        tk.type = TOK_Hash; break;
        case ASCII_Dollar:      tk.type = TOK_Dollar; break;
        case ASCII_Percent:     tk.type = TOK_Percent; break;
        case ASCII_And:         tk.type = TOK_And; break;
        case ASCII_ParenO:      tk.type = TOK_ParenO; break;
        case ASCII_ParenC:      tk.type = TOK_ParenC; break;
        case ASCII_Asterisk:    tk.type = TOK_Asterisk; break;
        case ASCII_Plus:        tk.type = TOK_Plus; break;
        case ASCII_Comma:       tk.type = TOK_Comma; break;
        case ASCII_Minus:       tk.type = TOK_Minus; break;
        case ASCII_Period:      tk.type = TOK_Period; break;
        case ASCII_Colon:       tk.type = TOK_Colon; break;
        case ASCII_Semicolon:   tk.type = TOK_Semicolon; break;
        case ASCII_LessThan:    tk.type = TOK_LessThan; break;
        case ASCII_Equals:      tk.type = TOK_Equals; break;
        case ASCII_MoreThan:    tk.type = TOK_MoreThan; break;
        case ASCII_Question:    tk.type = TOK_Question; break;
        case ASCII_At:          tk.type = TOK_At; break;
        case ASCII_BrackO:      tk.type = TOK_BrackO; break;
        case ASCII_Backslash:   tk.type = TOK_Backslash; break;
        case ASCII_BrackC:      tk.type = TOK_BrackC; break;
        case ASCII_Exponent:    tk.type = TOK_Exponent; break;
        case ASCII_Backquote:   tk.type = TOK_Backquote; break;
        case ASCII_BraceO:      tk.type = TOK_BraceO; break;
        case ASCII_VerticalBar: tk.type = TOK_VerticalBar; break;
        case ASCII_BraceC:      tk.type = TOK_BraceC; break;
        case ASCII_Tilde:       tk.type = TOK_Tilde; break;
        }

        return tk;
    }
}
