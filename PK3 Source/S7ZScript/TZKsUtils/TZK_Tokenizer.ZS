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

class TZK_Token
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

class TZK_Tokenizer
{
    private TZK_Stream m_Stream;

    static TZK_Tokenizer Create(TZK_Stream input)
    {
        if(!input.CanRead() || !input.CanSeek ())
            return null;

        let tok = new("TZK_Tokenizer");
        tok.m_Stream = input;
        return tok;
    }

    private void SkipWhitespace()
    {
        while(TZK_Character.IsWhitespace(m_Stream.Peek()))
            m_Stream.Read();
    }

    virtual int, int CurPos()
    {
        int pos = m_Stream.Position();
        int curChar;
        int lines = 0;
        int lastLinePos = 0;

        m_Stream.Seek(0, SEEK_Begin);
        while(m_Stream.Position() <= pos && !m_Stream.EOF())
        {
            curChar = m_Stream.Read();

            if(curChar == ASCII_LF) {
                lines++;
                lastLinePos = m_Stream.Position();
            }
        }

        m_Stream.Seek(lastLinePos, SEEK_Begin);
        int charPos = 0;
        while(m_Stream.Position() <= pos && !m_Stream.EOF())
        {
            curChar = m_Stream.Read();
            charPos++;
        }

        m_Stream.Seek(pos, SEEK_Begin);

        return lines + 1, charPos;
    }

    virtual TZK_Token Peek()
    {
        let pos = m_Stream.Position();
        let tok = Next();
        m_Stream.Seek(pos, SEEK_Begin);
        return tok;
    }

    virtual TZK_Token Next()
    {
        SkipWhitespace();
        let tk = new("TZK_Token");

        // are we at the end of the stream?
        if(m_Stream.EOF())
        {
            tk.type = TOK_EOF;
            return tk;
        }

        [tk.line, tk.charPos] = CurPos ();
        let c    = m_Stream.Read();
        tk.value = TZK_Character.ToString(c);
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
                c = m_Stream.Read();

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
                        m_Stream.Read();
                        break;
                    case ASCII_Lower_A: // 'a'
                        tk.value.AppendFormat("%s", "\a");
                        m_Stream.Read();
                        break;
                    case ASCII_Lower_N: // 'n'
                        tk.value.AppendFormat("%s", "\n");
                        m_Stream.Read();
                        break;
                    case ASCII_Lower_R: // 'r'
                        tk.value.AppendFormat("%s", "\r");
                        m_Stream.Read();
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
                c = m_Stream.Read();
                while(true)
                {
                    c = m_Stream.Read();

                    // have we encountered "*/"?
                    if(c == ASCII_Asterisk && m_Stream.Peek() == ASCII_Slash)
                    {
                        m_Stream.Read();
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
                    c = m_Stream.Read();
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
            if(TZK_Character.IsLetter(c) || c == ASCII_Underscore)
            {
                tk.type  = TOK_Identifier;
                tk.value = "";

                let peek = m_Stream.Peek();

                while(TZK_Character.IsLetterOrDigit(c) || c == ASCII_Underscore)
                {
                    tk.value.AppendFormat("%c", c);

                    // are we at the end of the identifier?
                    if(!TZK_Character.IsLetterOrDigit(peek) && peek != ASCII_Underscore)
                        break;

                    c = m_Stream.Read();
                    peek = m_Stream.Peek();
                }
            }
            else if(TZK_Character.IsDigit(c))
            {
                tk.type  = TOK_Number;
                tk.value = "";

                let peek = m_Stream.Peek();

                while(TZK_Character.IsDigit(c))
                {
                    tk.value.AppendFormat("%c", c);

                    // are we at the end of the digit?
                    if(!TZK_Character.IsDigit(peek))
                        break;

                    c = m_Stream.Read();
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
