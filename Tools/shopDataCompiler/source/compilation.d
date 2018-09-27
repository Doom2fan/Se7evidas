module compilation;

// From the standard library
import std.stdio;
import std.path;
import std.file;
import std.array;
import std.string;
import std.format : formattedWrite;
import std.ascii : newline;
import std.typecons : Nullable;
import std.algorithm.iteration;
// From the package
import functions;
import dataTypes;

const string baseCode = "extend class S7_ShopData {
\tS7_SSShop ##ShopName##;
}

extend class S7_ShopDataEventHandler {
\tvoid ##ShopName##_Populate (S7_ServerData serverData) {
\t\tif (!serverData || (serverData.shopData && serverData.shopData.##ShopName##))
\t\t\treturn;

##PageDefs##

##PageFuncCalls##

##ShopDef##
\t}

##PageFuncs##
}";
const string baseShopDef =
"\t\tlet shop = new (\"S7_SSShop\");
\t\tshop.name = \"%s\";
\t\tshop.cashLabelFormat = \"%s\";
\t\tshop.cashTypeShown = \"%s\";
\t\tshop.mainPage = %s;
\t\tserverData.shopData.##ShopName## = shop;";

string compileShop (ShopDef shop) {
    string code = baseCode;

    if (shop.intName is null)
        throw new CompilationException ("Encountered a shop definition with no internal name");
    if (shop.pages is null || !shop.pages.length)
        throw new CompilationException ("Encountered a shop definition with no pages");
    if (shop.mainPage is null || !(shop.mainPage.strip ().length))
        throw new CompilationException ("Encountered a shop definition with no main page");

    string [] pageDefs = new string [shop.pages.length];
    string [] pageFuncs = new string [shop.pages.length];
    string [] pageFuncCalls = new string [shop.pages.length];
    string pageFuncArgs = null;

    bool mainPageFound = false;
    for (int i = 0; i < shop.pages.length; i++) {
        ShopPage page = shop.pages [i];

        if (page.intName == shop.mainPage)
            mainPageFound = true;

        if (pageFuncArgs != null)
            pageFuncArgs ~= format (", S7_SSPage %s", page.intName);
        else
            pageFuncArgs = format ("S7_SSPage %s", page.intName);

        pageDefs [i] = format ("\t\tS7_SSPage %s = new (\"S7_SSPage\");", page.intName);
        pageFuncCalls [i] = format ("\t\t##ShopName##_Populate_%s (##PageFuncCallArgs##);", page.intName);
        compilePage (shop, page, pageFuncs [i]);
    }

    code = code.replace ("##PageDefs##", pageDefs.join (newline))
        .replace ("##PageFuncs##", pageFuncs.join (newline))
        .replace ("##PageFuncCalls##", pageFuncCalls.join (newline))
        .replace ("##PageFuncArgs##", pageFuncArgs)
        .replace ("##PageFuncCallArgs##", pageFuncArgs.replace ("S7_SSPage ", ""))
        .replace ("##ShopDef##", format (baseShopDef, shop.name, shop.cashLabelFormat, shop.cashTypeShown, shop.mainPage))
        .replace ("##ShopName##", shop.intName).replace ("\t", "    "); // Replace ##ShopName## and tabs last so other things can use them

    return code;
}

void compilePage (ShopDef shop, ShopPage page, out string pageFunc) {
    string [] tmpData;
    tmpData.reserve ((page.items.length * 14) + 2);

    tmpData ~= format ("\t/* %s */", page.intName);
    tmpData ~= format ("\tvoid ##ShopName##_Populate_%s (##PageFuncArgs##) {", page.intName);
    tmpData ~= format ("\t\t%s.name = \"%s\";", page.intName, page.name);
    tmpData ~= format ("\t\t%s.cashLabelFormat = \"%s\";", page.intName, page.cashLabelFormat);
    tmpData ~= format ("\t\t%s.cashTypeShown = \"%s\";", page.intName, page.cashTypeShown);
    tmpData ~= format ("\t\t%s.backPage = %s;", page.intName, page.backPage);

    for (int i = 0; i < page.items.length; i++) {
        ShopItem item = page.items [i];
        string [] itemData; itemData.reserve (14);

        tmpData ~= format ("\t\t%s.Create (", item.itemClass);

        itemData ~= format ("\t\t\tS7_Utils.MakeUID (\"%c\", \"%c\", \"%c\", \"%c\")", item.id [0], item.id [1], item.id [2], item.id [3]);

        if (item.name !is null)
            itemData ~= format ("\t\t\tname:          \"%s\"", item.name);

        if (item.description !is null)
            itemData ~= format ("\t\t\tdesc:          \"%s\"", item.description);

        if (item.info !is null)
            itemData ~= format ("\t\t\tinfo:          \"%s\"", item.info);

        if (item.icon !is null)
            itemData ~= format ("\t\t\ticon:          \"%s\"", item.icon);

        if (item.inventoryName !is null)
            itemData ~= format ("\t\t\tinventoryName: \"%s\"", item.inventoryName);

        if (item.itemType != cast (ItemType) -1) {
            string itemType;
            final switch (item.itemType) {
                case ItemType.PageLink:    itemType = "IT_PageLink";    break;
                case ItemType.BuyItem:     itemType = "IT_BuyItem";     break;
                case ItemType.SellItem:    itemType = "IT_SellItem";    break;
                case ItemType.BuySellItem: itemType = "IT_BuySellItem"; break;
            }
            itemData ~= format ("\t\t\titemType:      %s", itemType);
        }

        if (item.link !is null)
            itemData ~= format ("\t\t\tlink:          %s", item.link);

        string cashItem;
        if      (item.cashItem    !is null) cashItem = item.cashItem;
        else if (page.defCashItem !is null) cashItem = page.defCashItem;
        else if (shop.defCashItem !is null) cashItem = shop.defCashItem;
        if (cashItem !is null)
            itemData ~= format ("\t\t\tcashItem:      %s", cashItem);

        if (!item.maxAmount.isNull)
            itemData ~= format ("\t\t\tmaxAmount:     %s", item.maxAmount);

        if (!item.buyPrice.isNull)
            itemData ~= format ("\t\t\tbuyPrice:      %s", item.buyPrice);

        if (!item.buyAmount.isNull)
            itemData ~= format ("\t\t\tbuyAmount:     %s", item.buyAmount);

        if (!item.sellPrice.isNull)
            itemData ~= format ("\t\t\tsellPrice:     %s", item.sellPrice);

        if (!item.sellAmount.isNull)
            itemData ~= format ("\t\t\tsellAmount:    %s", item.sellAmount);

        if (item.descShowType != cast (DescShowType) -1) {
            string showType;
            final switch (item.descShowType) {
                case DescShowType.Select: showType = "DS_Select"; break;
                case DescShowType.Hover:  showType = "DS_Hover";  break;
                case DescShowType.Both:   showType = "DS_Both";   break;
            }
            itemData ~= format ("\t\t\tdescShowType:  %s", showType);
        }

        for (int j = 0; j < itemData.length; j++)
            tmpData ~= (j != itemData.length - 1) ? itemData [j] ~ "," : itemData [j];

        tmpData ~= format ("\t\t).AddToPage (%s, %s);", page.intName, !(item.global));
        itemData = null;
    }

    tmpData ~= "\t}";

    pageFunc = tmpData.join (newline);
    tmpData = null;
}