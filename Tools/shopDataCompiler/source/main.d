module main;

// From the standard library
import std.stdio;
import std.path;
import std.file;
import std.getopt;
import std.regex;
import std.json;
/*import std.typecons;
import std.array;
import std.conv;*/
import std.format : formattedWrite;
// From the package
import dataTypes;
import functions;
import parsing;
import compilation;

int main (string [] args) {
    string [] inputFiles;
    string outputFolder;

    try {
        auto helpInformation = getopt (
            args,
            std.getopt.config.required,
            "file|f", "Adds a file for compilation", &inputFiles,
            std.getopt.config.required,
            "out|output|o", "Sets the output path", &outputFolder
        );

        if (helpInformation.helpWanted) {
            defaultGetoptPrinter ("", helpInformation.options);
            return 255;
        }
    } catch (GetOptException e) {
        writeln (e.msg);
        return 255;
    }

    // Check for errors
    if (!isValidPath (outputFolder)) {
        writeln ("Error: Invalid output path.");
        return 255;
    }
    if (exists (outputFolder) && !isDir (outputFolder)) {
        writeln ("Error: The output path may not point to a file.");
        return 255;
    } else if (!exists (outputFolder))
        mkdir (outputFolder);

    // Parse files
    foreach (string file; inputFiles) {
        string outFile = buildPath (outputFolder, setExtension (baseName (stripExtension (file)), ".ZS"));

        // Check for errors
        if (!isValidPath (file)) {
            writeln ("Error: Invalid file path \"" ~ file ~ "\"");
            continue;
        }
        if (!exists (file)) {
            
            writeln ("Error: File \"", file, "\" does not exist");
            continue;
        }
        if (!isFile (file)) {
            writeln ("Error: Path \"", file, "\" does not point to a file");
            continue;
        }

        try {
            auto fileText = readText (file);
            fileText = replaceAll (fileText, ctRegex!(r"(\/\/.*)|(\/\*(.|\n)*\*\/)"), "");

            ShopDef shop = parseShop (parseJSON (fileText));
            string outputCode = compileShop (shop);
            std.file.write (outFile, outputCode);
        } catch (ParsingException e) {
            writeln ("JSON parsing error: ", e.msg);
            continue;
        } catch (CompilationException e) {
            writeln ("Compilation error: ", e.msg);
            continue;
        }
    }

    return 0;
}