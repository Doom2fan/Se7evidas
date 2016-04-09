using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;

namespace Compilation_tools {
    public class Program {
        private static Dictionary<string, Rule> _rules;
        private static Dictionary<string, int> _globalIntegers;
        private static Dictionary<string, string> _globalStrings;
        private static Token _token;
        private static Tokenizer _tokenizer;
        private static Rule _currentRule = null;
        /*public class CStuff {
            #region Variables

            public string CSourcePath = "C Source\\";
            public string IncludesPath = "inc\\";
            public string SourcePath = "src\\";
            public string IRFilesPath = "obj\\";
            public string CommonFilesFolder = "Common\\";
            public string ZDoomFilesFolder = "ZDoom\\";
            public string ZandronumFilesFolder = "Zandro\\";
            public string GDCCPath = "GDCC\\";
            public string GDCC_ASPath = "gdcc-as.exe";
            public string GDCC_CCPath = "gdcc-cc.exe";
            public string GDCC_LDPath = "gdcc-ld.exe";

            #endregion

            #region Constructor(s)

            /// <summary>
            /// C Compilation Stuff
            /// </summary>
            /// <param name="cSource">The main folder that holds all other folders.</param>
            /// <param name="incPath">The folder for the include/header/.h files.</param>
            /// <param name="srcPath">The folder for the source/.c files.</param>
            /// <param name="irFiles">The folder for the IR files.</param>
            /// <param name="commonFolder">(optional) The name of the folder for common files.</param>
            /// <param name="zdoomFolder">(optional) The name of the folder for ZDoom only files.</param>
            /// <param name="zandronumFolder">(optional) The name of the folder for Zandronum only files.</param>
            /// <param name="gdccPath"></param>
            /// <param name="asPath"></param>
            /// <param name="ccPath"></param>
            /// <param name="ldPath"></param>
            public CStuff (string cSource, string incPath, string srcPath, string irFiles,
                string commonFolder = "Common\\", string zdoomFolder = "ZDoom\\", string zandronumFolder = "Zandro\\",
                string gdccPath = "GDCC\\", string asPath = "gdcc-as.exe", string ccPath = "gdcc-cc.exe", string ldPath = "gdcc-ld.exe") {
                CSourcePath = cSource;
                IncludesPath = incPath;
                SourcePath = srcPath;
                IRFilesPath = irFiles;

                CommonFilesFolder = commonFolder;
                ZDoomFilesFolder = zdoomFolder;
                ZandronumFilesFolder = zandronumFolder;

                GDCCPath = gdccPath;
                GDCC_ASPath = asPath;
                GDCC_CCPath = ccPath;
                GDCC_LDPath = ldPath;
            }

            #endregion
        }*/

        public static int Main (string [] args) {
            MemoryStream stream = new MemoryStream ();
            BinaryWriter writer = new BinaryWriter (stream);

            writer.Write (1163084609);
            writer.Close ();
            writer.Dispose ();

            byte [] shite = stream.ToArray ();

            stream.Close ();
            stream.Dispose ();

            Console.WriteLine (1163084609);
            for (int i = 0; i < shite.Length; i++) {
                Console.Write (shite [i]);
                Console.Write (" ");
            }
            Console.ReadKey ();

            /*byte errorLevel = 0;

            string compilefileFilename = "Compilefile";
            string ruleToRun = "_main";

            for (int i = 0; i < args.Length; i++) {
                if (args [i].Equals ("-f") || args [i].Equals ("--file"))
                    if (i + 1 < args.Length) {
                        compilefileFilename = args [i + 1];
                        i += 1;
                    }

                if (args [i].Equals ("-r") || args [i].Equals ("--rule"))
                    if (i + 1 < args.Length) {
                        ruleToRun = args [i + 1];
                        i += 1;
                    }
            }

            try {
                errorLevel = ParseCompilefile (compilefileFilename);
            } catch (FileNotFoundException) {
                Console.WriteLine ("No Compilefile found.");
            }

            foreach (KeyValuePair<string, Rule> pair in _rules) {
                pair.Value.Processing (_rules);
            }

            if (!string.IsNullOrEmpty (ruleToRun) && !string.IsNullOrWhiteSpace (ruleToRun))
                if (_rules.ContainsKey (ruleToRun))
                    _rules [ruleToRun].Run ();*/

            return 0;// errorLevel;
        }

        private static byte ParseCompilefile (string file) {
            if (!File.Exists (file))
                throw new FileNotFoundException ();

            _rules = new Dictionary<string, Rule> ();
            _globalIntegers = new Dictionary<string, int> ();
            _globalStrings = new Dictionary<string, string> ();

            _tokenizer = new Tokenizer ();
            _tokenizer.InputString = File.ReadAllText (file);

            _token = _tokenizer.GetToken ();

            while (_token != null) {
                switch (_token.TokenName) {
                    case Tokenizer.Tokens.WHITESPACE:
                        break;

                    case Tokenizer.Tokens.IDENTIFIER:
                        ParseIdentifier ();
                        break;

                    case Tokenizer.Tokens.INTIDENTIFIER:
                        switch (_token.TokenValue) {
                            case "rule":
                                ParseRuleIdentifier ();
                                break;

                            case "string":
                                ParseStringIdentifier ();
                                break;

                            case "int":
                                ParseIntegerIdentifier ();
                                break;

                            case "Execute":
                                ParseExecute ();
                                break;

                            default:
                                Error ("Error: {0}:{1} Expected identifier, got '{2}'", new object [] {
                                    _token.TokenLine,
                                    _token.TokenColumn,
                                    _token.TokenValue
                                });
                                break;
                        }
                        break;
                    case Tokenizer.Tokens.RBRACE:
                        if (_currentRule == null) {
                            Error ("Error: {0}:{1} Expected identifier, got '}'");
                        } else {
                            _rules.Add (_currentRule.Name, _currentRule);
                            _currentRule = null;
                        }
                        break;
                }

                _token = _tokenizer.GetToken ();
            }

            #region Dump variables

#if DEBUG
            Console.Write ("global {\n");

            Console.Write ("strings:\n");
            foreach (KeyValuePair<string, string> pairStrings in _globalStrings)
                Console.Write ("    " + pairStrings.Key + " : " + pairStrings.Value + "\n");

            Console.Write ("\n\nintegers:\n");
            foreach (KeyValuePair<string, int> pairIntegers in _globalIntegers)
                Console.Write ("    " + pairIntegers.Key + " : " + pairIntegers.Value + "\n");

            Console.Write ("}\n\n");

            foreach (KeyValuePair<string, Rule> pair in _rules) {
                Console.Write (pair.Key + " {\nstrings:\n");

                foreach (KeyValuePair<string, string> pairStrings in pair.Value.Strings)
                    Console.Write ("    " + pairStrings.Key + " : " + pairStrings.Value + "\n");
                Console.Write ("\n\nintegers:\n");

                foreach (KeyValuePair<string, int> pairIntegers in pair.Value.Integers)
                    Console.Write ("    " + pairIntegers.Key + " : " + pairIntegers.Value + "\n");

                Console.Write ("}\n\n");
            }
#endif

            #endregion

            Console.ReadKey ();

            return 0;
        }

        #region Methods - Identifier parsing

        public static void ParseIdentifier () {
            Tokenizer.Tokens tokenType = Tokenizer.Tokens.UNDEFINED;
            Token t = _token;

            if (IsStringVar (ref t))
                tokenType = Tokenizer.Tokens.STRING;
            else if (IsIntegerVar (ref t))
                tokenType = Tokenizer.Tokens.INTEGER;

            if (tokenType == Tokenizer.Tokens.STRING) {
                _token = GetToken (Tokenizer.Tokens.ANY);

                string stringValue = null;

                if (_token.TokenName == Tokenizer.Tokens.ASSIGN)
                    stringValue = string.Empty;
                else if (_token.TokenName == Tokenizer.Tokens.ADDASSIGN) {
                    stringValue = GetString (ref t);
                }

                _token = GetToken (Tokenizer.Tokens.ANY);
                stringValue += GetString (ref _token);
                _token = GetToken (Tokenizer.Tokens.ANY);

                while (true) {
                    if (_token.TokenName == Tokenizer.Tokens.SEMICOLON)
                        break;
                    else if (_token.TokenName == Tokenizer.Tokens.ADD) {
                        _token = GetToken (Tokenizer.Tokens.ANY);

                        if (!IsString (ref _token))
                            TokenError (ref _token, Tokenizer.Tokens.STRING);

                        stringValue += GetString (ref _token);
                    } else
                        TokenError (ref t, Tokenizer.Tokens.STRING);
                    _token = GetToken (Tokenizer.Tokens.ANY);
                }

                var dict = GetStringDictionary (ref t);
                dict [t.TokenValue] = stringValue;
            }
        }

        public static void ParseRuleIdentifier () {
            if (_currentRule == null) {
                _token = GetToken (Tokenizer.Tokens.IDENTIFIER);

                string ruleName = _token.TokenValue;
                List<Token> inputFileList = new List<Token> ();
                List<Token> outputFileList = new List<Token> ();

                _token = GetToken (Tokenizer.Tokens.LPAREN);
                _token = GetToken (Tokenizer.Tokens.ANY);
                while (true) {
                    if (IsString (ref _token)) {
                        inputFileList.Add (_token);
                        _token = GetToken (Tokenizer.Tokens.ANY);
                        if (_token.TokenName == Tokenizer.Tokens.COMMA) {

                        } else if (_token.TokenName == Tokenizer.Tokens.RPAREN)
                            break;
                        else
                            TokenError (ref _token, Tokenizer.Tokens.COMMA | Tokenizer.Tokens.RPAREN);
                    } else if (_token.TokenName == Tokenizer.Tokens.RPAREN)
                        break;
                    else
                        TokenError (ref _token, Tokenizer.Tokens.COMMA | Tokenizer.Tokens.RPAREN);
                    _token = GetToken (Tokenizer.Tokens.ANY);
                }

                _token = GetToken (Tokenizer.Tokens.LPAREN);
                _token = GetToken (Tokenizer.Tokens.ANY);
                string inputDirectory = GetString (ref _token);

                _token = GetToken (Tokenizer.Tokens.COMMA);
                _token = GetToken (Tokenizer.Tokens.ANY);
                string inputFileMask = GetString (ref _token);

                _token = GetToken (Tokenizer.Tokens.COMMA);
                _token = GetToken (Tokenizer.Tokens.ANY);
                string outputDirectory = GetString (ref _token);
                _token = GetToken (Tokenizer.Tokens.RPAREN);

                _token = GetToken (Tokenizer.Tokens.LBRACE);
                _currentRule = new Rule (ruleName, new List<RunAction> (), new Dictionary<string, int> (), new Dictionary<string, string> (), new List<Token> (), inputDirectory, inputFileMask, outputDirectory);
            } else
                Error ("Error: {0}:{1} Rules cannot be defined inside other rules", new object [] { _token.TokenLine, _token.TokenColumn, _token.TokenValue });
        }

        public static void ParseStringIdentifier () {
            Dictionary<string, string> dictionary;
            if (_currentRule == null)
                dictionary = _globalStrings;
            else
                dictionary = _currentRule.Strings;

            _token = GetToken (Tokenizer.Tokens.IDENTIFIER);
            string stringName = _token.TokenValue;

            if (dictionary.ContainsKey (stringName))
                Error ("Error: {0}:{1} Cannot redefine variables", new object [] {
                                                    _token.TokenLine,
                                                    _token.TokenColumn
                                                }, ExitCode.InvalidIdentifier);

            _token = GetToken (Tokenizer.Tokens.ASSIGN);
            _token = GetToken (Tokenizer.Tokens.ANY);

            string stringValue = GetString (ref _token);

            if (stringValue == null)
                TokenError (ref _token, Tokenizer.Tokens.STRING);

            dictionary.Add (stringName, stringValue);
            _token = GetToken (Tokenizer.Tokens.SEMICOLON);
        }

        public static void ParseIntegerIdentifier () {
            Dictionary<string, int> dictionary;
            if (_currentRule == null)
                dictionary = _globalIntegers;
            else
                dictionary = _currentRule.Integers;

            _token = GetToken (Tokenizer.Tokens.IDENTIFIER);
            string stringName = _token.TokenValue;

            if (dictionary.ContainsKey (stringName))
                Error ("Error: {0}:{1} Cannot redefine variables", new object [] {
                                                    _token.TokenLine,
                                                    _token.TokenColumn
                                                }, ExitCode.InvalidIdentifier);

            _token = GetToken (Tokenizer.Tokens.ASSIGN);
            _token = GetToken (Tokenizer.Tokens.ANY);

            int integerValue = GetInteger (ref _token);

            dictionary.Add (stringName, integerValue);
            _token = GetToken (Tokenizer.Tokens.SEMICOLON);
        }

        public static void ParseExecute () {
            if (_currentRule == null)
                Error ("Error: {0}:{1} Execute cannot be called outside a rule");

            _token = GetToken (Tokenizer.Tokens.LPAREN);
            _token = GetToken (Tokenizer.Tokens.ANY);

            string cmd = GetString (ref _token);
            string args = null;
            bool noWindow = true;

            _token = GetToken (Tokenizer.Tokens.ANY);
            if (_token.TokenName == Tokenizer.Tokens.COMMA) {
                _token = GetToken (Tokenizer.Tokens.ANY);
                args = GetString (ref _token);
                _token = GetToken (Tokenizer.Tokens.ANY);
                if (_token.TokenName == Tokenizer.Tokens.COMMA) {
                    _token = GetToken (Tokenizer.Tokens.ANY);
                    args = GetString (ref _token);
                    _token = GetToken (Tokenizer.Tokens.RPAREN);
                } else if (_token.TokenName == Tokenizer.Tokens.RPAREN) {
                } else
                    TokenError (ref _token, Tokenizer.Tokens.COMMA | Tokenizer.Tokens.RPAREN);
            } else if (_token.TokenName == Tokenizer.Tokens.RPAREN) {
            } else
                TokenError (ref _token, Tokenizer.Tokens.COMMA | Tokenizer.Tokens.RPAREN);

            _token = GetToken (Tokenizer.Tokens.SEMICOLON);

            if (string.IsNullOrWhiteSpace (cmd))
                cmd = string.Empty;
            if (string.IsNullOrWhiteSpace (args))
                args = string.Empty;
            _currentRule.ActionList.Add (new Execute (cmd, args, noWindow));
        }

        public static bool IsString (ref Token t, bool searchCurrentRule = true) {
            if (IsStringLiteral (ref t))
                return true;
            else if (IsStringVar (ref t, searchCurrentRule))
                return true;
            else
                return false;
        }
        public static bool IsStringLiteral (ref Token t) {
            if (t.TokenName == Tokenizer.Tokens.STRING)
                return true;
            else
                return false;
        }
        public static bool IsStringVar (ref Token t, bool searchCurrentRule = true) {
            if (_globalStrings.ContainsKey (t.TokenValue) || (searchCurrentRule && _currentRule != null && _currentRule.Strings.ContainsKey (t.TokenValue))) {
                return true;
            } else if (t.TokenName == Tokenizer.Tokens.INTIDENTIFIER) {
                if (t.TokenValue.Equals ("InputFile") || t.TokenValue.Equals ("OutputFile"))
                    return true;
                else
                    return false;
            } else
                return false;
        }
        public static Dictionary<string, string> GetStringDictionary (ref Token t) {
            if (_currentRule != null && _currentRule.Strings.ContainsKey (t.TokenValue))
                return _currentRule.Strings;
            else if (_globalStrings.ContainsKey (t.TokenValue))
                return _globalStrings;
            else
                return null;
        }
        public static string GetString (ref Token t, bool searchCurrentRule = true) {
            string stringValue = string.Empty;

            if (t.TokenName == Tokenizer.Tokens.STRING)
                stringValue = t.TokenValue.Remove (t.TokenValue.Length - 1, 1).Remove (0, 1);
            else if (t.TokenName == Tokenizer.Tokens.IDENTIFIER) {
                if (_globalStrings.ContainsKey (t.TokenValue))
                    stringValue = _globalStrings [t.TokenValue];
                else if (searchCurrentRule && _currentRule.Strings.ContainsKey (t.TokenValue))
                    stringValue = _currentRule.Strings [t.TokenValue];
                else
                    TokenError (ref _token, Tokenizer.Tokens.STRING);
            } else if (t.TokenName == Tokenizer.Tokens.INTIDENTIFIER) {
                if (t.TokenValue.Equals ("InputFile"))
                    return "%$%#%@iNPutFiLenAmE%$%#%@";
                else if (t.TokenValue.Equals ("OutputFile"))
                    return "%$%#%@OuTPUTFiLenAmE%$%#%@";
            }

            return stringValue;
        }

        public static bool IsInteger (ref Token t, bool searchCurrentRule = true) {
            if (IsIntegerLiteral (ref t))
                return true;
            else if (IsIntegerVar (ref t, searchCurrentRule))
                return true;
            else
                return false;
        }
        public static bool IsIntegerLiteral (ref Token t) {
            int intValue;

            if (t.TokenName == Tokenizer.Tokens.INTEGER) {
                if (int.TryParse (t.TokenValue, out intValue))
                    return true;
                else
                    return false;
            }

            return false;
        }
        public static bool IsIntegerVar (ref Token t, bool searchCurrentRule = true) {
            if (_globalIntegers.ContainsKey (t.TokenValue) || (searchCurrentRule && _currentRule != null && _currentRule.Integers.ContainsKey (t.TokenValue))) {
                return true;
            } else
                return false;
        }
        public static Dictionary<string, int> GetIntegerDictionary (ref Token t) {
            if (_currentRule != null && _currentRule.Integers.ContainsKey (t.TokenValue))
                return _currentRule.Integers;
            else if (_globalIntegers.ContainsKey (t.TokenValue))
                return _globalIntegers;
            else
                return null;
        }
        public static int GetInteger (ref Token t, bool searchCurrentRule = true) {
            int intValue = 0;

            if (t.TokenName == Tokenizer.Tokens.INTEGER) {
                if (!int.TryParse (t.TokenValue, out intValue))
                    TokenError (ref _token, Tokenizer.Tokens.INTEGER);
            } else if (t.TokenName == Tokenizer.Tokens.IDENTIFIER) {
                if (_globalIntegers.ContainsKey (t.TokenValue))
                    intValue = _globalIntegers [t.TokenValue];
                else if (searchCurrentRule && _currentRule.Integers.ContainsKey (t.TokenValue))
                    intValue = _currentRule.Integers [t.TokenValue];
                else
                    TokenError (ref _token, Tokenizer.Tokens.INTEGER);
            }

            return intValue;
        }

        #endregion

        #region Methods - Token reading

        public static Token GetToken (Tokenizer.Tokens TokenType, bool errorCheck = true, bool alwaysReturnToken = false) {
            if (TokenType == Tokenizer.Tokens.WHITESPACE || TokenType == Tokenizer.Tokens.NEWLINE)
                throw new ArgumentException ("Token type cannot be newline, whitespace or undefined.");

            Token token;

            token = _tokenizer.GetToken ();

            token = EatWhitespace (token);

            if (TokenType == Tokenizer.Tokens.ANY || alwaysReturnToken || token.TokenName == TokenType)
                return token;
            else if (errorCheck && TokenType != Tokenizer.Tokens.ANY) {
                string tokenTypeString;

                #region Token type checking

                switch (TokenType) {
                    case Tokenizer.Tokens.IDENTIFIER:
                        tokenTypeString = "identifier";
                        break;
                    case Tokenizer.Tokens.INTIDENTIFIER:
                        tokenTypeString = "identifier";
                        break;
                    case Tokenizer.Tokens.LBRACE:
                        tokenTypeString = "'{'";
                        break;
                    case Tokenizer.Tokens.RBRACE:
                        tokenTypeString = "'}'";
                        break;
                    case Tokenizer.Tokens.LPAREN:
                        tokenTypeString = "'('";
                        break;
                    case Tokenizer.Tokens.RPAREN:
                        tokenTypeString = "')'";
                        break;
                    case Tokenizer.Tokens.SEMICOLON:
                        tokenTypeString = "';'";
                        break;
                    case Tokenizer.Tokens.STRING:
                        tokenTypeString = "string constant";
                        break;
                    case Tokenizer.Tokens.DECIMAL:
                        tokenTypeString = "decimal constant";
                        break;
                    case Tokenizer.Tokens.INTEGER:
                        tokenTypeString = "integer constant";
                        break;
                    case Tokenizer.Tokens.COMMA:
                        tokenTypeString = "','";
                        break;
                    case Tokenizer.Tokens.ADDASSIGN:
                        tokenTypeString = "'+='";
                        break;
                    case Tokenizer.Tokens.SUBASSIGN:
                        tokenTypeString = "'-='";
                        break;
                    case Tokenizer.Tokens.MULASSIGN:
                        tokenTypeString = "'*='";
                        break;
                    case Tokenizer.Tokens.DIVASSIGN:
                        tokenTypeString = "'/='";
                        break;
                    case Tokenizer.Tokens.ASSIGN:
                        tokenTypeString = "'='";
                        break;
                    case Tokenizer.Tokens.ADD:
                        tokenTypeString = "'+'";
                        break;
                    case Tokenizer.Tokens.SUB:
                        tokenTypeString = "'-'";
                        break;
                    case Tokenizer.Tokens.MUL:
                        tokenTypeString = "'*'";
                        break;
                    case Tokenizer.Tokens.DIV:
                        tokenTypeString = "'/'";
                        break;
                    default:
                        tokenTypeString = "UNKNOWN";
                        break;
                }

                #endregion

                Error ("Error: {0}:{1} Expected {3}, got '{2}'", new object [] { token.TokenLine, token.TokenColumn, token.TokenValue, tokenTypeString }, ExitCode.InvalidToken);
            }

            return null;
        }

        public static Token EatWhitespace (Token token) {
            while (token.TokenName == Tokenizer.Tokens.WHITESPACE || token.TokenName == Tokenizer.Tokens.NEWLINE)
                token = _tokenizer.GetToken ();

            return token;
        }

        #endregion

        #region Methods - Error reporting

        public static void Error (string error, ExitCode exitCode = ExitCode.GenericError, bool line = true) {
            if (line)
                Console.WriteLine (error);
            else
                Console.Write (error);

            Console.ReadKey ();
            Environment.Exit ((int) exitCode);
        }

        public static void Error (string error, object [] args, ExitCode exitCode = ExitCode.GenericError, bool line = true) {
            if (line)
                Console.WriteLine (error, args);
            else
                Console.Write (error, args);

            Console.ReadKey ();
            Environment.Exit ((int) exitCode);
        }

        public static void TokenError (ref Token t, Tokenizer.Tokens tokenType, bool line = true) {
            string error = string.Empty;

            if (tokenType == Tokenizer.Tokens.IDENTIFIER || tokenType == Tokenizer.Tokens.INTIDENTIFIER)
                error = "Error: {0}:{1} Expected identifier, got '{2}'";
            else if (tokenType == Tokenizer.Tokens.STRING)
                error = "Error: {0}:{1} Expected string constant or identifier, got '{2}'";
            else if (tokenType == Tokenizer.Tokens.INTEGER)
                error = "Error: {0}:{1} Expected integer literal or identifier, got '{2}'";
            /*else if (tokenType == Tokenizer.Tokens.DECIMAL)
                error = "Error: {0}:{1} Expected decimal literal or identifier, got '{2}'";*/
            else if (tokenType == Tokenizer.Tokens.LBRACE)
                error = "Error: {0}:{1} Expected '{', got '{2}'";
            else if (tokenType == Tokenizer.Tokens.LPAREN)
                error = "Error: {0}:{1} Expected '(', got '{2}'";
            else if (tokenType == Tokenizer.Tokens.ASSIGN)
                error = "Error: {0}:{1} Expected '=', got '{2}'";
            else if (tokenType == Tokenizer.Tokens.SEMICOLON)
                error = "Error: {0}:{1} Expected ';', got '{2}'";
            else if (tokenType == Tokenizer.Tokens.RBRACE)
                error = "Error: {0}:{1} Expected '}', got '{2}'";
            else if (tokenType == Tokenizer.Tokens.RPAREN)
                error = "Error: {0}:{1} Expected ')', got '{2}'";
            else if (tokenType == Tokenizer.Tokens.COMMA)
                error = "Error: {0}:{1} Expected argument, got '{2}'";
            else if (tokenType == (Tokenizer.Tokens.RPAREN | Tokenizer.Tokens.COMMA))
                error = "Error: {0}:{1} Expected argument or ')', got '{2}'";
            else if (tokenType == Tokenizer.Tokens.UNDEFINED)
                error = "Error: {0}:{1} Expected UNDEFINED, got '{2}'";
            else
                throw new Exception ("Token type invalid or not implemented yet.", null);

            Error (error, new object [] {
                t.TokenLine,
                t.TokenColumn,
                t.TokenValue
            }, ExitCode.InvalidToken, line);
        }

        #endregion
    }

    public enum ExitCode : int {
        Success = 0,
        GenericError = 1,
        InvalidToken = 2,
        InvalidIdentifier = 3,
        ProcessingError = 4,
        FileNotFound = 5,
    }

    public class Rule {
        #region Fields

        public string Name;
        public List<Rule> Dependencies;
        public List<Token> DependencyTokens;
        public List<RunAction> ActionList;
        public Dictionary<string, int> Integers;
        public Dictionary<string, string> Strings;
        public string InputDirectory;
        public string InputFileMask;
        public string OutputDirectory;

        #endregion

        #region Constructors

        /// <summary>
        /// Creates a rule with the specified name, action list and variable dictionaries.
        /// </summary>
        /// <param name="newName">The name of the rule.</param>
        /// <param name="newActionList">The rule's actions.</param>
        /// <param name="newIntegerDictionary">The rule's integers</param>
        /// <param name="newStringDictionary">The rule's strings</param>
        public Rule (string newName, List<RunAction> newActionList, Dictionary<string, int> newIntegerDictionary, Dictionary<string, string> newStringDictionary) {
            Name = newName;
            ActionList = newActionList;
            Integers = newIntegerDictionary;
            Strings = newStringDictionary;
            DependencyTokens = new List<Token> ();
            InputDirectory = string.Empty;
            OutputDirectory = string.Empty;
            InputFileMask = string.Empty;
        }

        /// <summary>
        /// Creates a rule with the specified name, action list, variable dictionaries and dependencies.
        /// </summary>
        /// <param name="newName">The name of the rule.</param>
        /// <param name="newActionList">The rule's actions.</param>
        /// <param name="newIntegerDictionary">The rule's integers</param>
        /// <param name="newStringDictionary">The rule's strings</param>
        /// <param name="dependencies">The rule's dependencies</param>
        public Rule (string newName, List<RunAction> newActionList, Dictionary<string, int> newIntegerDictionary, Dictionary<string, string> newStringDictionary, List<Token> newDependencies, string newInputDirectory, string newInputFileMask, string newOutputDirectory) {
            Name = newName;
            ActionList = newActionList;
            Integers = newIntegerDictionary;
            Strings = newStringDictionary;
            DependencyTokens = newDependencies;
            InputDirectory = newInputDirectory;
            OutputDirectory = newOutputDirectory;
            InputFileMask = newInputFileMask;
        }

        #endregion

        #region Methods

        public void Processing (Dictionary<string, Rule> rulesDict) {
            Dependencies = new List<Rule> ();

            if (DependencyTokens != null) {
                for (int i = 0; i < DependencyTokens.Count; i++) {
                    Token t = DependencyTokens [i];
                    string rule = Program.GetString (ref t);

                    if (!rulesDict.ContainsKey (rule))
                        Program.Error ("Processing error: Unknown dependency '{0}' in rule '{1}'", new object [] {
                        rule,
                        this.Name
                    }, ExitCode.ProcessingError);
                    else
                        Dependencies.Add (rulesDict [rule]);
                }
            }
        }

        public bool ShouldRun () {
            List<string> inputFiles = new List<string> (Directory.GetFiles (InputDirectory, InputFileMask));
            List<string> outputFiles = new List<string> (Directory.GetFiles (OutputDirectory, InputFileMask));

            foreach (string file in inputFiles) {
                if (!(outputFiles.Contains (Path.GetFileNameWithoutExtension (file))))
                    return true;
                else {
                    string ofile = outputFiles.Find (o => o.Equals (file));
                }
            }

            return false;
        }

        public void Run () {
            foreach (Rule dependency in Dependencies)
                if (dependency.ShouldRun ())
                    dependency.Run ();

            //for (int i = 0; i < InputList.Count; i++) {

            //    bool run = false;

            //    if (!File.Exists (OutputList [i]))
            //        run = true;
            //    else if (File.GetLastWriteTimeUtc (InputList [i]).Ticks > File.GetLastWriteTimeUtc (OutputList [i]).Ticks)
            //        run = true;

            //    if (run) {
            //        foreach (RunAction act in ActionList)
            //            act.Run (InputList [i], OutputList [i]);
            //    }
            //}
        }

        #endregion
    }

    #region Classes - Actions

    /// <summary>
    /// The base class for actions.
    /// </summary>
    public abstract class RunAction {
        #region Methods

        /// <summary>
        /// Runs the action.
        /// </summary>
        public abstract int Run (string inputFileName, string outputFileName);

        #endregion

        #region Properties

        /// <summary>
        /// The action's name
        /// </summary>
        public abstract string ActionName { get; }
        /// <summary>
        /// The action's parameters
        /// </summary>
        public abstract object [] Parameters { get; }

        #endregion
    }

    /// <summary>
    /// Executes a program.
    /// </summary>
    public class Execute : RunAction {
        #region Fields

        private ProcessStartInfo startInfo;

        #endregion

        #region Properties

        /// <summary>
        /// The action's name
        /// </summary>
        public override string ActionName { get { return "Execute"; } }
        /// <summary>
        /// The action's parameters
        /// </summary>
        public override object [] Parameters { get { return new object [] { Command, Arguments }; } }

        public string Command {
            get {
                return startInfo.FileName;
            }
            set {
                startInfo.FileName = value;
            }
        }
        public string Arguments {
            get {
                return startInfo.Arguments;
            }
            set {
                startInfo.Arguments = value;
            }
        }
        public bool NoWindow {
            get {
                return startInfo.CreateNoWindow;
            }
            set {
                startInfo.CreateNoWindow = value;
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Executes a program.
        /// </summary>
        /// <param name="cmd">The program to be executed.</param>
        /// <param name="args">The arguments to be passed to the program.</param>
        public Execute (string cmd, string args, bool noWindow) {
            startInfo = new ProcessStartInfo (cmd, args);
            startInfo.UseShellExecute = true;
            startInfo.CreateNoWindow = noWindow;
        }

        #endregion

        #region Methods

        /// <summary>
        /// Executes a program or command
        /// </summary>
        /// <returns>Returns the program's exit code. Returns int.MinValue if the program could not be started.</returns>
        public override int Run (string inputFileName, string outputFileName) {
            Command = Command.Replace ("%$%#%@iNPutFiLenAmE%$%#%@", inputFileName).Replace ("%$%#%@OuTPUTFiLenAmE%$%#%@", outputFileName);
            Arguments = Arguments.Replace ("%$%#%@iNPutFiLenAmE%$%#%@", inputFileName).Replace ("%$%#%@OuTPUTFiLenAmE%$%#%@", outputFileName);

            Process process = null;
            try {
                process = Process.Start (startInfo);
            } catch (Exception e) {
                return int.MinValue;
            }
            if (process == null)
                return int.MinValue;

            process.WaitForExit ();
            return process.ExitCode;
        }

        #endregion
    }

    #endregion
}