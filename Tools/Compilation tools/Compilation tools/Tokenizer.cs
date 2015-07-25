using System;
// This file was Auto Generated with TokenIcer
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace Compilation_tools {
    /// <summary>
    /// Tokenizer
    /// </summary>
    /// <remarks>
    /// Tokenizer is the main parser engine for converting input into lexical tokens.
    /// </remarks>
    public class Tokenizer {
        // This dictionary will store our RegEx rules
        private readonly Dictionary<Tokens, string> _tokens;
        // This dictionary will store our matches
        private readonly Dictionary<Tokens, MatchCollection> _regExMatchCollection;
        // This input string will store the string to parse
        private string _inputString;
        // This index is used internally so the parser knows where it left off
        private int _index;
        // The current line
        private int _line;
        // The current column
        private int _column;
        // The current comment state
        private bool _comment;

        public bool Comment { get { return _comment; } }

        // This is our token enumeration. It holds every token defined in the grammar
        /// <summary>
        /// Tokens is an enumeration of all possible token values.
        /// </summary>
        [Flags]
        public enum Tokens {
            ANY = -1,
            UNDEFINED = 0,
            LCOMMENT = 1, //  Line comment
            STRING = 2, //  String constant
            INTIDENTIFIER = 3, //  Internal identifier
            IDENTIFIER = 4, //  Identifier
            DECIMAL = 5, //  Decimal value
            INTEGER = 6, //  Integer value
            LBRACE = 7, //  Open braces
            RBRACE = 8, //  Close Braces
            LPAREN = 9, //  Open parenthesis
            RPAREN = 10, //  Close parenthesis
            SEMICOLON = 11, //  Function end
            COMMA = 12, //  Comma
            ADDASSIGN = 13, //  Addition + assignment operator
            SUBASSIGN = 14, //  Subtraction + assignment operator
            MULASSIGN = 15, //  Multiplication + assignment operator
            DIVASSIGN = 16, //  Division + assignment operator
            ASSIGN = 17, //  Assignment operator
            ADD = 18, //  Addition operator
            SUB = 19, //  Subtraction operator
            MUL = 20, //  Multiplication operator
            DIV = 21, //  Division operator
            WHITESPACE = 22, //  Whitespace
            NEWLINE = 23 //  Newline
        }

        // A public setter for our input string
        /// <summary>
        /// InputString Property
        /// </summary>
        /// <value>
        /// The string value that holds the input string.
        /// </value>
        public string InputString {
            set {
                _inputString = value;
                PrepareRegex ();
            }
        }

        // Our Constructor, which simply initializes values
        /// <summary>
        /// Default Constructor
        /// </summary>
        /// <remarks>
        /// The constructor initalizes memory and adds all of the tokens to the token dictionary.
        /// </remarks>
        public Tokenizer () {
            _tokens = new Dictionary<Tokens, string> ();
            _regExMatchCollection = new Dictionary<Tokens, MatchCollection> ();
            _index = 0;
            _line = 1;
            _column = 1;
            _inputString = string.Empty;
            _comment = false;

            // These lines add each grammar rule to the dictionary
            _tokens.Add (Tokens.LCOMMENT, "//");
            _tokens.Add (Tokens.STRING, "\".*?\"");
            _tokens.Add (Tokens.INTIDENTIFIER, "[a-zA-Z][a-zA-Z0-9_]*");
            _tokens.Add (Tokens.IDENTIFIER, "_[a-zA-Z_][a-zA-Z0-9_]*");
            _tokens.Add (Tokens.DECIMAL, "[0-9]+\\.+[0-9]+");
            _tokens.Add (Tokens.INTEGER, "[0-9]+");
            _tokens.Add (Tokens.LBRACE, "\\{");
            _tokens.Add (Tokens.RBRACE, "\\}");
            _tokens.Add (Tokens.LPAREN, "\\(");
            _tokens.Add (Tokens.RPAREN, "\\)");
            _tokens.Add (Tokens.SEMICOLON, "\\;");
            _tokens.Add (Tokens.COMMA, "\\,");
            _tokens.Add (Tokens.ADDASSIGN, "\\+=");
            _tokens.Add (Tokens.SUBASSIGN, "\\-=");
            _tokens.Add (Tokens.MULASSIGN, "\\*=");
            _tokens.Add (Tokens.DIVASSIGN, "/=");
            _tokens.Add (Tokens.ASSIGN, "\\=");
            _tokens.Add (Tokens.ADD, "\\+");
            _tokens.Add (Tokens.SUB, "\\-");
            _tokens.Add (Tokens.MUL, "\\*");
            _tokens.Add (Tokens.DIV, "/");
            _tokens.Add (Tokens.WHITESPACE, "[ \\t]+");
            _tokens.Add (Tokens.NEWLINE, "\\r\\n|[\\r\\n]");
        }

        // This function preloads the matches based on our rules and the input string
        /// <summary>
        /// PrepareRegex prepares the regex for parsing by pre-matching the Regex tokens.
        /// </summary>
        private void PrepareRegex () {
            _regExMatchCollection.Clear ();
            foreach (KeyValuePair<Tokens, string> pair in _tokens) {
                _regExMatchCollection.Add (pair.Key, Regex.Matches (_inputString, pair.Value));
            }
        }

        // ResetParser() will reset the parser.
        // Keep in mind that you must set the input string again
        /// <summary>
        /// ResetParser resets the parser to its inital state. Reloading InputString is required.
        /// </summary>
        /// <seealso cref="InputString"/>
        public void ResetParser () {
            _index = 0;
            _inputString = string.Empty;
            _regExMatchCollection.Clear ();
        }

        // GetToken() retrieves the next token and returns a token object
        /// <summary>
        /// GetToken gets the next token in queue
        /// </summary>
        /// <remarks>
        /// GetToken attempts to the match the next character(s) using the
        /// Regex rules defined in the dictionary. If a match can not be
        /// located, then an Undefined token will be created with an empty
        /// string value. In addition, the token pointer will be incremented
        /// by one so that this token doesn't attempt to get identified again by
        /// GetToken()
        /// </remarks>
        public Token GetToken () {
            // If we are at the end of our input string then
            // we return null to signify the end of our input string.
            // While parsing tokens, you will undoubtedly be in a loop.
            // Having your loop check for a null token is a good way to end that
            // loop
            if (_index >= _inputString.Length)
                return null;

            // Iterate through our prepared matches/Tokens dictionary
            foreach (KeyValuePair<Tokens, MatchCollection> pair in _regExMatchCollection) {
                // Iterate through each prepared match
                foreach (Match match in pair.Value) {
                    // If we find a match, update our index pointer and return a new Token object
                    if (match.Index == _index) {
                        _index += match.Length;

                        if (pair.Key == Tokens.LCOMMENT)
                            _comment = true;

                        Token t = null;

                        if (!_comment)
                            t = new Token (pair.Key, match.Value, _index, _line, _column);
                        else
                            t = new Token (Tokens.WHITESPACE, "", _index, _line, _column);

                        if (pair.Key == Tokens.NEWLINE) {
                            _comment = false;
                            _line++;
                            _column = 1;
                        } else
                            _column += match.Length;

                        return t;
                    }

                    if (match.Index > _index) {
                        break;
                    }
                }
            }
            // If execution got here, then we increment our index pointer
            // and return an Undefined token. 
            _index++;
            Token t2 = null;
            if (!_comment)
                t2 = new Token (Tokens.UNDEFINED, string.Empty, _index, _line, _column);
            else
                t2 = new Token (Tokens.WHITESPACE, "", _index, _line, _column);
            return t2;
        }

        public void Seek (Token t) {
            _index = t.TokenIndex;
            _line = t.TokenLine;
            _column = t.TokenColumn;
        }

        // Peek() will retrieve a PeekToken object and will allow you to see the next token
        // that GetToken() will retrieve.
        /// <summary>
        /// Returns the next token that GetToken() will return.
        /// </summary>
        /// <seealso cref="Peek(PeekToken)"/>
        public PeekToken Peek () {
            return Peek (new PeekToken (_index, new Token (Tokens.UNDEFINED, string.Empty, _index, _line, _column)));
        }

        // This is an overload for Peek(). By passing in the last PeekToken object
        // received from Peek(), you can peek ahead to the next token, and the token after that, etc...
        /// <summary>
        /// Returns the next token after the Token passed here
        /// </summary>
        /// <param name="peekToken">The PeekToken token returned from a previous Peek() call</param>
        /// <seealso cref="Peek()"/>
        public PeekToken Peek (PeekToken peekToken) {
            int oldIndex = _index;
            int oldLine = _line;
            int oldColumn = _column;
            bool oldComment = _comment;

            _index = peekToken.TokenIndex;

            if (_index >= _inputString.Length) {
                _index = oldIndex;
                return null;
            }

            foreach (KeyValuePair<Tokens, string> pair in _tokens) {
                Regex r = new Regex (pair.Value);
                Match m = r.Match (_inputString, _index);

                if (m.Success && m.Index == _index) {
                    _index += m.Length;

                    if (pair.Key == Tokens.LCOMMENT)
                        _comment = true;

                    Token t = null;

                    if (!_comment)
                        t = new Token (pair.Key, m.Value, _index, _line, _column);
                    else
                        t = new Token (Tokens.WHITESPACE, "", _index, _line, _column);

                    PeekToken pt = new PeekToken (_index, t);

                    if (pair.Key == Tokens.NEWLINE) {
                        _comment = false;
                        _line++;
                        _column = 1;
                    } else
                        _column += m.Length;

                    _index = oldIndex;
                    _line = oldLine;
                    _column = oldColumn;
                    _comment = oldComment;
                    return pt;
                }
            }
            Token t2 = null;
            if (!_comment)
                t2 = new Token (Tokens.UNDEFINED, string.Empty, _index + 1, _line, _column);
            else
                t2 = new Token (Tokens.WHITESPACE, "", _index, _line, _column);

            PeekToken pt2 = new PeekToken (_index + 1, t2);

            _index = oldIndex;
            _line = oldLine;
            _column = oldColumn;
            _comment = oldComment;
            return pt2;
        }
    }

    // This defines the PeekToken object
    /// <summary>
    /// A PeekToken object class
    /// </summary>
    /// <remarks>
    /// A PeekToken is a special pointer object that can be used to Peek() several
    /// tokens ahead in the GetToken() queue.
    /// </remarks>
    public class PeekToken {
        public int TokenIndex { get; set; }

        public Token TokenPeek { get; set; }

        public PeekToken (int index, Token value) {
            TokenIndex = index;
            TokenPeek = value;
        }
    }

    // This defines the Token object
    /// <summary>
    /// a Token object class
    /// </summary>
    /// <remarks>
    /// A Token object holds the token and token value.
    /// </remarks>
    public class Token {
        public int TokenLine;

        public int TokenColumn;

        public int TokenIndex;

        public Tokenizer.Tokens TokenName { get; set; }

        public string TokenValue { get; set; }

        public Token (Tokenizer.Tokens name, string value, int index, int line, int column) {
            TokenName = name;
            TokenValue = value;
            TokenIndex = index;
            TokenLine = line;
            TokenColumn = column;
        }
    }
}
