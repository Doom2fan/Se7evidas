module dataTypes;

import std.typecons : Nullable;

enum ItemType {
    PageLink    = 1,
    BuyItem     = 1 <<  1,
    SellItem    = 1 <<  2,
    BuySellItem = BuyItem | SellItem,
}

enum DescShowType {
    Select = 1,
    Hover  = 1 << 1,
    Both   = Select | Hover,
}

class ShopDef {
    string intName;

    string name;
    string cashLabelFormat;
    string cashTypeShown;
    string mainPage;
    string defCashItem;
    ShopPage [] pages;
}

class ShopPage {
    string intName;

    string name;
    string cashLabelFormat;
    string cashTypeShown;
    string defCashItem;
    string backPage;
    ShopItem [] items;
}

class ShopItem {
    bool global;
    string itemClass;

    char [4] id;
    string name;
    string description;
    string info;
    string icon;
    string inventoryName;
    ItemType itemType;
    string link;
    string cashItem;
    Nullable!int maxAmount;
    Nullable!int buyPrice;
    Nullable!int buyAmount;
    Nullable!int sellPrice;
    Nullable!int sellAmount;
    DescShowType descShowType;
}