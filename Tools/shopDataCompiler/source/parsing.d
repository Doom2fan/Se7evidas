module parsing;

// From the standard library
import std.stdio;
import std.json;
import std.uni : toLower;
// From the package
import dataTypes;
import functions;

ShopDef parseShop (JSONValue data) {
    ShopDef shop = new ShopDef ();

    if (!tryParseValueOut!(string, JSON_TYPE.STRING) (data, "intName", shop.intName, null, true, false))
        throw new ParsingException ("Shop definitions must specify an internal name");

    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "name", shop.name, "", true, false);
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "mainPage", shop.mainPage, null, true, true);

    auto pages = tryParseValue (data, "pages", JSON_TYPE.ARRAY, true, true).array;
    ShopPage [] pageDefs = new ShopPage [pages.length];
    for (int i = 0; i < pages.length; i++)
        pageDefs [i] = parsePage (pages [i]);
    shop.pages = pageDefs;

    return shop;
}

ShopPage parsePage (JSONValue data) {
    ShopPage page = new ShopPage ();

    if (!tryParseValueOut!(string, JSON_TYPE.STRING) (data, "intName", page.intName, null, true, false))
        throw new ParsingException ("Shop definitions must specify an internal name");

    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "name", page.name, "", true, false);

    auto items = tryParseValue (data, "items", JSON_TYPE.ARRAY, true, true).array;
    ShopItem [] itemDefs = new ShopItem [items.length];
    for (int i = 0; i < items.length; i++)
        itemDefs [i] = parseItem (items [i]);
    page.items = itemDefs;

    return page;
}

ShopItem parseItem (JSONValue data) {
    ShopItem item = new ShopItem ();
    string itemType;
    string descShowType;

    auto idChars = tryParseValue (data, "id", JSON_TYPE.ARRAY, true, false).array;
    if (!idChars)
        throw new ParsingException ("Items must specify an ID");
    if (idChars.length != 4)
        throw new ParsingException ("Item IDs must be exactly 4 characters");
    for (int i = 0; i < 4; i++)
        item.id [i] = idChars [i].str [0];

    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "name", item.name, null, true, false);
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "desc", item.description, null, true, false);
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "info", item.info, null, true, false);
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "icon", item.icon, null, true, false);
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "inventoryName", item.inventoryName, null, true, false);
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "itemType", itemType, "", true, false);
    switch (itemType.toLower ()) {
        case "pagelink":    item.itemType = ItemType.PageLink;    break;
        case "buyitem":     item.itemType = ItemType.BuyItem;     break;
        case "sellitem":    item.itemType = ItemType.SellItem;    break;
        case "buysellitem": item.itemType = ItemType.BuySellItem; break;
        default: item.itemType = cast (ItemType) -1; break;
    }
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "link", item.link, null, true, false);

    int maxAmount, buyPrice, buyAmount, sellPrice, sellAmount;
    if (tryParseValueOut!(int, JSON_TYPE.INTEGER) (data, "maxAmount",  maxAmount,  -1, true, false) !is null) item.maxAmount = maxAmount;
    else item.maxAmount.nullify ();
    if (tryParseValueOut!(int, JSON_TYPE.INTEGER) (data, "buyPrice",   buyPrice,   -1, true, false) !is null) item.buyPrice = buyPrice;
    else item.buyPrice.nullify ();
    if (tryParseValueOut!(int, JSON_TYPE.INTEGER) (data, "buyAmount",  buyAmount,  -1, true, false) !is null) item.buyAmount = buyAmount;
    else item.buyAmount.nullify ();
    if (tryParseValueOut!(int, JSON_TYPE.INTEGER) (data, "sellPrice",  sellPrice,  -1, true, false) !is null) item.sellPrice = sellPrice;
    else item.sellPrice.nullify ();
    if (tryParseValueOut!(int, JSON_TYPE.INTEGER) (data, "sellAmount", sellAmount, -1, true, false) !is null) item.sellAmount = sellAmount;
    else item.sellAmount.nullify ();

    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "descShowType", descShowType, null, true, false);
    switch (descShowType.toLower ()) {
        case "select": item.descShowType = DescShowType.Select; break;
        case "hover":  item.descShowType = DescShowType.Hover;  break;
        case "both":   item.descShowType = DescShowType.Both;   break;
        default: item.descShowType = cast (DescShowType) -1; break;
    }
    tryParseValueOut!(string, JSON_TYPE.STRING) (data, "itemClass", item.itemClass, "S7_SSItem", true, false);
    if (const (JSONValue)* val = "global" in data) {
        if (val.type == JSON_TYPE.TRUE)
            item.global = true;
        else if (val.type == JSON_TYPE.FALSE)
            item.global = false;
        else
            throw new ParsingException ("\"global\" must be a boolean");
    } else
        throw new ParsingException ("Could not find required value \"global\"");

    return item;
}