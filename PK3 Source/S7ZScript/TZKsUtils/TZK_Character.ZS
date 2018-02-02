// Helper class to work with chars
class TZK_Character
{
    static bool IsWhitespace(int c)
    {
        switch(c)
        {
        case ASCII_TAB:
        case ASCII_LF:
        case ASCII_VT:
        case ASCII_FF:
        case ASCII_CR:
        case ASCII_Space:
        case ASCII_NUL:
             return true;
        default:
             return false;
        }
    }

    static bool IsControl(int c)
    {
        switch(c)
        {
        case ASCII_LF:
        case ASCII_CR:
             return true;
        default:
             return c <= ASCII_US && c >= ASCII_NUL;
        }
    }

    static bool IsDigit(int c)
    {
        return c <= ASCII_9 && c >= ASCII_0;
    }

    static bool IsLetter(int c)
    {
        return IsLower(c) || IsUpper(c);
    }

    static bool IsLetterOrDigit(int c)
    {
        return IsLetter(c) || IsDigit(c);
    }

    static bool IsLower(int c)
    {
        return c <= ASCII_Lower_Z && c >= ASCII_Lower_A;
    }

    static bool IsUpper(int c)
    {
        return c <= ASCII_Z && c >= ASCII_A;
    }

    static int ToUpper(int c)
    {
        if(IsLower(c))
            return c + ASCII_A - ASCII_Lower_A;
        return c;
    }

    static int ToLower(int c)
    {
        if(IsUpper(c))
            return c - ASCII_A + ASCII_Lower_A;
        return c;
    }

    static string ToString(int c)
    {
        return string.Format("%c", c);
    }
}
