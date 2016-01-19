module main;

import std.stdio;
import stack;

enum ExitCodes {
    Success = 0
}

int main (string [] args) {
    string inputFilePath = null;
    string outputFilePath = null;
    bool noStdOut = false;
    bool noStdErr = false;
    bool readStdIn = false;
    auto argsStack = new Stack!(string) (150);

    for (int i = args.length - 1; i >= 1; i--)
        argsStack.Push (args [i]);

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
                noStdOut = true;
                break;
            case "--nostderr":
                noStdErr = true;
                break;
            default:
                writeln ("Error: Improperly constructed command line: " ~ arg ~ " is not a valid argument.");
                stderr.writeln ("Improperly constructed command line|" ~ arg);
                break;
        }
    }



	return ExitCodes.Success;
}
