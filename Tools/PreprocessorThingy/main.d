module main;

import std.stdio;
import std.file;
import std.path;
import std.array;
import std.regex;
import std.typecons;
import stack;

enum ExitCodes {
    Success = 0,
    ArgumentError = 1,
}

enum Options {
    NoStdOut = 1 << 1,
    //OutputStdOut = 1 << 2,
}

string[] HelpLines = [
    "Usage: ppthingy.exe [OPTIONS]",
    "\tOptions:",
    "\t-h\t--help: Show this help page.",
    "\t-f\t--file: The file to process.",
    "\t-o\t--out: The output file.",
    "\t-q\t--quiet: No STDOUT output."
];

int main (string [] args) {
    BitFlags!Options options;
    string inputFilePath = null;
    string outputFilePath = null;
    auto argsStack = new Stack!(string) (150);

    foreach (arg; args)
        argsStack.Push (arg);

    while (!argsStack.isEmpty) {
        string arg = argsStack.Pop ();

        switch (arg) {
            case "--file":
            case "-f":
                inputFilePath = argsStack.Pop ();
                break;
            case "--out":
            case "-o":
                outputFilePath = argsStack.Pop ();
                break;
            case "--quiet":
            case "--q":
                options |= Options.NoStdOut;
                break;
            case "--help":
            case "-h":
                foreach (line; HelpLines)
                    writeln (line);
                return ExitCodes.Success;
                break;
            default:
                writeln ("Error: Improperly constructed command line: " ~ arg ~ " is not a valid argument.");
                stderr.writeln ("ARG|Improperly constructed command line|" ~ arg);
                return ExitCodes.ArgumentError;
                break;
        }
    }

    File stream = null;
    if (inputFilePath == null || inputFilePath == "") {
        stdoutWrite ("Error: No input file specified.", options);
        stderr.writeln ("ARG|No input file specified", options);
    }

    string tmpInputPath;
    tmpInputPath = cast(string) asAbsolutePath (asNormalizedPath (inputFilePath).array).array;
    inputFilePath = tmpInputPath;

    if (!exists (inputFilePath)) {
    } else if (!isFile (inputFilePath)) {
    }

    ParseStream (stream, options);

	return ExitCodes.Success;
}

void ParseStream (File stream, BitFlags!Options options) {

}

void stdoutWrite (lazy string msg, BitFlags!(Options) options) {
    if (!(options & Options.NoStdOut))
        stdout.write (msg);
}
void stdoutWriteln (lazy string msg, BitFlags!(Options) options) {
    if (!(options & Options.NoStdOut))
        stdout.writeln (msg);
}
