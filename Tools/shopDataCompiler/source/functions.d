module functions;

// From the standard library
import std.json;
import std.format : format;
import std.conv : text;
import std.traits : Unqual, isAssociativeArray, KeyType, ValueType;

/** Exceptions **/
public mixin template ExceptionCtorMixin () {
    this (string msg = null, Throwable next = null) { super (msg, next); }
    this (string msg, string file, size_t line, Throwable next = null) {
        super (msg, file, line, next);
    }
}

class ParsingException : Exception { mixin ExceptionCtorMixin; }
class CompilationException : Exception { mixin ExceptionCtorMixin; }

/** Functions **/
const (JSONValue)* tryParseValue (T) (in T d, string name, JSON_TYPE type, bool fatalType = true, bool fatalMissing = true)
    if ((isAssociativeArray!T && is (KeyType!T == string) && is (ValueType!T == JSONValue)) || is (Unqual!T == JSONValue)) {
    if (const (JSONValue)* val = name in d) {
        if (val.type == type)
            return val;
        else if (fatalType)
            throw new ParsingException (format ("\"%s\" must be %s", name, text (type)));
        else
            return null;
    } else if (fatalMissing)
        throw new ParsingException (format ("Could not find required value \"%s\"", name));
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
            throw new ParsingException (format ("\"%s\" must be %s", name, text (type)));
        else {
            output = def;
            return null;
        }
    } else if (fatalMissing)
        throw new ParsingException (format ("Could not find required value \"%s\"", name));
    else {
        output = def;
        return null;
    }
}