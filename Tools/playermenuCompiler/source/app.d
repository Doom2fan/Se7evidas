import std.stdio;
import std.path;
import std.file;
import std.json;
import std.getopt;
import std.typecons;
import std.array;
import std.conv;
import std.traits : Unqual, isAssociativeArray, KeyType, ValueType;
import std.format : formattedWrite;

public mixin template ExceptionCtorMixin () {
    this (string msg = null, Throwable next = null) { super (msg, next); }
    this (string msg, string file, size_t line, Throwable next = null) {
        super (msg, file, line, next);
    }
}

enum MenuFlags : int {
    NoAutoIDs = 1,
}

enum MenuControlType {
    Label = 0,
    Link,
    Use,
}

struct Icon {
    float [2] offsets = 0f;
    string image;
}

class MenuControl {
    MenuControlType type;
    Nullable!int id;
    float [2] pos = 0f;
    Icon icon;
    string iconCallback;
    string text;
    string textCallback;
    string visibleCallback;
    Nullable!int nextId, prevId;
    // Link and Use
    string enabledCallback;
    // Link
    string dest;
    // Use
    string useCallback;
}

class MenuPage {
    string name;
    BitFlags!MenuFlags flags;
    int [2] hudSize;
    int initialID;
    MenuControl [] controls;
}

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
        string outFile = buildPath (outputFolder, setExtension (baseName (stripExtension (file)), ".c"));

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
            MenuPage menu = parseMenu (parseJSON (readText (file)));
            string outputCode = compileMenu (menu);
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

class ParsingException : Exception { mixin ExceptionCtorMixin; }
const (JSONValue)* tryParseValue (T) (in T d, string name, JSON_TYPE type, bool fatalType = true, bool fatalMissing = true)
    if ((isAssociativeArray!T && is (KeyType!T == string) && is (ValueType!T == JSONValue)) || is (Unqual!T == JSONValue)) {
    if (const (JSONValue)* val = name in d) {
        if (val.type == type)
            return val;
        else if (fatalType)
            throw new ParsingException (name ~ " must be " ~ text (type));
        else
            return null;
    } else if (fatalMissing)
        throw new ParsingException ("Could not find " ~ name);
    else
        return null;
}
const (JSONValue)* tryParseValueOut (T, byte type, dataType) (in dataType d, string name, out T output, T def, bool fatalType = true, bool fatalMissing = true)
    if ((isAssociativeArray!dataType && is (KeyType!dataType == string) && is (ValueType!dataType == JSONValue)) || is (Unqual!dataType == JSONValue)) {
    if (const (JSONValue)* val = name in d) {
        if (val.type == type) {
            static if (type == JSON_TYPE.STRING) {
                output = cast (T) val.str;
            } else static if (type == JSON_TYPE.INTEGER) {
                output = cast (T) val.integer;
            } else static if (type == JSON_TYPE.UINTEGER) {
                output = cast (T) val.uinteger;
            } else static if (type == JSON_TYPE.OBJECT) {
                output = cast (T) val.object;
            } else static if (type == JSON_TYPE.FLOAT) {
                output = cast (T) val.floating;
            }

            return val;
        } else if (fatalType)
            throw new ParsingException (name ~ " must be " ~ text (type));
        else {
            output = def;
            return null;
        }
    } else if (fatalMissing)
        throw new ParsingException ("Could not find " ~ name);
    else
        return null;
}
MenuPage parseMenu (JSONValue data) {
    MenuPage menu = new MenuPage ();
    MenuControl [] labels;
    MenuControl [] buttons;
    MenuControl lastControlWithId;
    int prevId = 0, id = 0, firstId;

    if (tryParseValueOut!(string, JSON_TYPE.STRING) (data, "name", menu.name, null, true, false) == null)
        throw new ParsingException ("Menu definitions must specify a name");

    if (auto initialID = tryParseValue (data, "initialID", JSON_TYPE.INTEGER, true, false)) {
        menu.initialID = cast (uint) initialID.integer;
        id = menu.initialID;
    }

    if (auto flags = tryParseValue (data, "flags", JSON_TYPE.ARRAY, true, false)) {
        foreach (val; flags.array) {
            if (val.type == JSON_TYPE.STRING) {
                switch (val.str) {
                    case "noAutoIDs":
                        menu.flags |= MenuFlags.NoAutoIDs;
                        break;
                    default:
                        throw new ParsingException ("Unknown flag \"" ~ val.str ~ "\" encountered");
                }
            } else
                throw new ParsingException ("Invalid value encountered when parsing flags");
        }
    }

    if (auto hudSize = tryParseValue (data, "hudSize", JSON_TYPE.ARRAY, true, false)) {
        if (hudSize.array.length != 2 || hudSize.array [0].type != JSON_TYPE.INTEGER || hudSize.array [1].type != JSON_TYPE.INTEGER)
            throw new ParsingException ("Invalid hudSize parameter. hudSize must be an array containing two integers");

        menu.hudSize [0] = cast (uint) (hudSize.array [0].integer);
        menu.hudSize [1] = cast (uint) (hudSize.array [1].integer);
    }

    if (const (JSONValue)* items = tryParseValue (data, "items", JSON_TYPE.ARRAY, true, true)) {
        int i;
        foreach (item; items.array) {
            MenuControl control = parseControl (item, menu.flags, prevId, id, lastControlWithId);
            if (!control.id.isNull)
                lastControlWithId = control;
            if (control.type == MenuControlType.Label)
                labels ~= control;
            else
                buttons ~= control;

            if (i == 0 && !control.id.isNull)
                firstId = control.id;

            i++;
        }
        if (!(menu.flags & MenuFlags.NoAutoIDs) && lastControlWithId && !lastControlWithId.nextId.isNull) {
            lastControlWithId.nextId = firstId;
        }
    }

    menu.controls = labels ~ buttons;

    return menu;
}

MenuControl parseControl (JSONValue data, BitFlags!MenuFlags menuFlags, ref int prevId, ref int curId, ref MenuControl prevControl) {
    MenuControl control = new MenuControl ();
    if (data.type != JSON_TYPE.OBJECT)
        throw new ParsingException ("Encountered an invalid control definition");

    if (auto t = tryParseValue (data, "type", JSON_TYPE.STRING, true, true)) {
        switch (t.str) {
            case "label":
                control.type = MenuControlType.Label;
                break;
            case "use":
                control.type = MenuControlType.Use;
                break;
            case "link":
                control.type = MenuControlType.Link;
                break;
            default:
                throw new ParsingException ("Item type must be label, use or link");
        }
    }

    int cId, cNextId, cPrevId;
    if (tryParseValueOut!(int, JSON_TYPE.INTEGER) (data, "id", cId, 0, true, false)) {
        control.id = cId;
        prevId = cId;
        curId = cId + 1;
    }
    if (tryParseValueOut!(int, JSON_TYPE.INTEGER) (data, "nextId", cNextId, 0, true, false))
        control.nextId = cNextId;
    if (tryParseValueOut!(int, JSON_TYPE.INTEGER) (data, "prevId", cPrevId, 0, true, false))
        control.prevId = cPrevId;

    tryParseValueOut!(float, JSON_TYPE.FLOAT) (data, "x", control.pos [0], 0f, true, false);
    tryParseValueOut!(float, JSON_TYPE.FLOAT) (data, "y", control.pos [1], 0f, true, false);

    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "text", control.text, null, true, false);
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "textCallback", control.textCallback, null, true, false);
    
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "iconCallback", control.iconCallback, null, true, false);
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "visibleCallback", control.visibleCallback, null, true, false);
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "enabledCallback", control.enabledCallback, null, true, false);
    if (tryParseValueOut!(string, JSON_TYPE.STRING) (data, "dest", control.dest, null, true, false) && control.type != MenuControlType.Link)
        writeln ("JSON parsing warning: dest is useless with a non-link control");
    if (tryParseValueOut!(string, JSON_TYPE.STRING) (data, "useCallback", control.useCallback, null, true, false) && control.type != MenuControlType.Use)
        writeln ("JSON parsing warning: useCallback is useless with a non-use control");

    if (!(menuFlags & MenuFlags.NoAutoIDs) && control.type == MenuControlType.Use || control.type == MenuControlType.Link) {
        if (control.prevId.isNull)
            control.prevId = prevId;

        if (control.id.isNull) {
            prevId = curId;
            control.id = curId;
        } else {
            prevId = control.id;
            curId = control.id + 1;
        }

        if (prevControl && prevControl.nextId.isNull)
            prevControl.nextId = control.id;
    }

    if (const (JSONValue)* icon = tryParseValue (data, "icon", JSON_TYPE.OBJECT, true, false))
        control.icon = parseIcon!(JSONValue [string]) (icon.object);

    return control;
}

Icon parseIcon (T) (in T data)
    if ((isAssociativeArray!T && is (KeyType!T == string) && is (ValueType!T == JSONValue)) || is (Unqual!T == JSONValue)) {
    Icon ret;

    tryParseValueOut!(string, JSON_TYPE.STRING, JSONValue [string]) (data, "image", ret.image, null, true, true);
    tryParseValueOut!(float, JSON_TYPE.FLOAT, JSONValue [string]) (data, "xOff", ret.offsets [0], 0f, true, false);
    tryParseValueOut!(float, JSON_TYPE.FLOAT, JSONValue [string]) (data, "yOff", ret.offsets [1], 0f, true, false);

    return ret;
}

const string baseCCode = "// Automatically generated from a playermenu JSON definition
#include \"includes.h\"
#include \"systems/playerMenu.h\"\n";

class CompilationException : Exception { mixin ExceptionCtorMixin; }
string compileMenu (MenuPage menu) {
    auto app = appender (baseCCode);

    if (menu.name == null)
        throw new CompilationException ("Encountered a menu definition with no menu name");

    // Items/Controls list
    formattedWrite (app, "\nPM_Item %s_Items [] = {", menu.name);
    foreach (MenuControl control; menu.controls) {
        app.put ("\n    {");
        app.put ("\n        .type = ");
        switch (control.type) {
            case MenuControlType.Label: app.put ("PM_Label,"); break;
            case MenuControlType.Link: app.put ("PM_Link,"); break;
            case MenuControlType.Use: app.put ("PM_Use,"); break;
            default: throw new CompilationException ("Encountered a MenuControl with an invalid type");
        }
        formattedWrite (app, "\n        .id = %d,", (!control.id.isNull ? control.id : -1));
        formattedWrite (app, "\n        .pos = { %fk, %fk },", control.pos [0], control.pos [1]);
        formattedWrite (app, "\n        .icon = { .offsets = { %fk, %fk }, .image = s\"%s\" },", control.icon.offsets [0], control.icon.offsets [1], control.icon.image);
        formattedWrite (app, "\n        .iconCallback = %s,", (control.iconCallback != null) ? control.iconCallback : "NULL");

        if (control.text != null)
            formattedWrite (app, "\n        .text = s\"%s\",", control.text);
        else
            app.put ("\n        .text = NULL,");

        formattedWrite (app, "\n        .textCallback = %s,", (control.textCallback != null) ? control.textCallback : "NULL");
        formattedWrite (app, "\n        .visibleCallback = %s,", (control.visibleCallback != null) ? control.visibleCallback : "NULL");
        formattedWrite (app, "\n        .nextId = %s,", (!control.nextId.isNull) ? control.nextId : -1);
        formattedWrite (app, "\n        .prevId = %s,", (!control.prevId.isNull) ? control.prevId : -1);
        formattedWrite (app, "\n        .enabledCallback = %s,", (control.enabledCallback != null) ? control.enabledCallback : "NULL");
        formattedWrite (app, "\n        .dest = %s,", (control.dest != null) ? control.dest : "NULL");
        formattedWrite (app, "\n        .useCallback = %s,", (control.useCallback != null) ? control.useCallback : "NULL");
        app.put ("\n    },");
    }
    app.put ("\n    { .type = PM_ListEnd, },");
    app.put ("\n};");

    // Menu definition
    formattedWrite (app, "\n\nPM_Page %s = {", menu.name);
    formattedWrite (app, "\n    .hudSize = { %d, %d },", menu.hudSize [0], menu.hudSize [1]);
    formattedWrite (app, "\n    .initialId = %d,", menu.initialID);
    formattedWrite (app, "\n    .items = &%s_Items [0],", menu.name);
    app.put ("\n};");
    
    return app.data;
}