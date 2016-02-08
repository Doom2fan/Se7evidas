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
    FromStdIn = 1 << 2,
    //OutputStdOut = 1 << 3,
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
            case "--stdin":
                options |= Options.FromStdIn;
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

    if (!(options & Options.FromStdIn) && inputFilePath == null || inputFilePath == "") {
        stdoutWrite ("Error: No input file specified.", options);
        stderr.writeln ("ARG|No input file specified", options);
        return ExitCodes.ArgumentError;
    }

    if (outputFilePath == null || outputFilePath == "") {
        stdoutWrite ("Error: No output file specified.", options);
        stderr.writeln ("ARG|No output file specified", options);
        return ExitCodes.ArgumentError;
    }

    string tmpInputPath;
    tmpInputPath = cast(string) asAbsolutePath (asNormalizedPath (inputFilePath).array).array;
    inputFilePath = tmpInputPath;

    string tmpOutputPath;
    tmpOutputPath = cast(string) asAbsolutePath (asNormalizedPath (outputFilePath).array).array;
    outputFilePath = tmpOutputPath;

    if (!(options & Options.FromStdIn) && !exists (inputFilePath)) {
        stdoutWrite ("Error: Input file does not exist.", options);
        stderr.writeln ("ARG|Input file does not exist", options);
        return ExitCodes.ArgumentError;
    } else if (!(options & Options.FromStdIn) && !isFile (inputFilePath)) {
        stdoutWrite ("Error: Input file specified is not a file.", options);
        stderr.writeln ("ARG|Input file specified is not a file", options);
        return ExitCodes.ArgumentError;
    }
    if (exists (outputFilePath)) {
        stdoutWrite ("Error: Output file already exists.", options);
        stderr.writeln ("ARG|Output file already exists", options);
        return ExitCodes.ArgumentError;
    }

    File input;
    if (!(options & Options.FromStdIn)) {
        input = File (inputFilePath, "r");
    } else {
        input = stdin;
    }
    auto output = File (outputFilePath, "w");

    ParseStream (input, output, options);

	return ExitCodes.Success;
}

void ParseStream (File input, File output, BitFlags!Options options) {
    auto includeR = Regex!(r"#include \"(.+)\"", "g");
    auto writer = output.lockingTextWriter ();

    foreach (string line; lines (input)) {
        foreach (matchStr; matchAll (line, includeR)) {

        }
    }
}

void stdoutWrite (lazy string msg, BitFlags!(Options) options) {
    if (!(options & Options.NoStdOut))
        stdout.write (msg);
}
void stdoutWriteln (lazy string msg, BitFlags!(Options) options) {
    if (!(options & Options.NoStdOut))
        stdout.writeln (msg);
}
