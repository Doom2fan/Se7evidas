//-------------------------------------------------------------------------------------------
//
// Cash
//
//-------------------------------------------------------------------------------------------
class S7_Cash : S7_Counter { default { inventory.maxAmount 0x7FFFFFFF; +inventory.keepDepleted } }

// Constants
enum SS_ItemType {
    IT_PageLink    = 1,
    IT_BuyItem     = 1 <<  1,
    IT_SellItem    = 1 <<  2,
    IT_BuySellItem = IT_BuyItem | IT_SellItem,
}

enum SS_DescShowType {
    DS_Select = 1,
    DS_Hover  = 1 << 1,
    DS_Both   = DS_Select | DS_Hover,
}

enum SS_BuyCode {
    BC_Success        =   0,
    BC_NotEnoughMoney =   1,
    BC_InventoryFull  =   2,
    BC_InvalidPlayer  = 254,
    BC_Unknown        = 255,
}

enum SS_SellCode {
    SC_Success         =   0,
    SC_NotEnoughOfItem =   1,
    SC_TooMuchMoney    =   2, // Should be very, VERY hard to get, since the maximum amount of cash is 0x7FFFFFFF...
    SC_InvalidPlayer   = 254,
    SC_Unknown         = 255,
}

// Classes
class S7_SSShop {
    string name;
    S7_SSPage mainPage;
}

class S7_SSPage {
    string name;
    Array<S7_SSItem> items;
}

class S7_SSItemInfo {
    int maxAmount;
    int buyPrice;
    int buyAmount;
    int sellPrice;
    int sellAmount;
    S7_SSItemInfo Copy () {
        let ret = new ("S7_SSItemInfo");
        ret.maxAmount = self.maxAmount;
        ret.buyPrice  = self.buyPrice;  ret.buyAmount  = self.buyAmount;
        ret.sellPrice = self.sellPrice; ret.sellAmount = self.sellAmount;
        return ret;
    }
}
class S7_SSItem {
    int id;
    string name;
    string description;
    string infoText;
    string icon;
    string inventoryName;
    SS_ItemType itemType;
    S7_SSPage link;
    S7_SSItemInfo info;
    SS_DescShowType descShowType;

    static S7_SSItem Create (int id, string name = "", string desc = "", string info = "", string icon = "", string inventoryName = "", SS_ItemType itemType = 0,
        S7_SSPage link = NULL, int maxAmount = 0, int buyPrice = 0, int buyAmount = 0, int sellPrice = 0, int sellAmount = 0, SS_DescShowType descShowType = DS_Both
    ) {
        S7_SSItem ret = new ("S7_SSItem");

        ret.id              = id;
        ret.name            = name;
        ret.description     = desc;
        ret.infoText        = info;
        ret.icon            = icon;
        ret.inventoryName   = inventoryName;
        ret.itemType        = itemType;
        ret.link            = link;
        ret.info            = new ("S7_SSItemInfo");
        ret.info.maxAmount  = maxAmount;
        ret.info.buyPrice   = buyPrice;
        ret.info.buyAmount  = buyAmount;
        ret.info.sellPrice  = sellPrice;
        ret.info.sellAmount = sellAmount;
        ret.descShowType    = descShowType;

        return ret;
    }

    virtual S7_SSItemInfo GetInfo (S7_BasePlayer player, int amount) {
        let ret = self.info.Copy ();

        ret.buyPrice *= amount;
        ret.buyAmount *= amount;
        ret.sellPrice *= amount;
        ret.sellAmount *= amount;

        return info.Copy ();
    }

    virtual play SS_BuyCode BuyItem (S7_BasePlayer player, int amount, double discount = 0.0) {
        if (!player)
            return BC_InvalidPlayer;

        let itemInfo = self.GetInfo (player, amount);
        int finalPrice = (itemInfo.buyPrice * amount) - ((itemInfo.buyPrice * amount) * discount);
        int finalAmount = itemInfo.buyAmount * amount;

        if (player.CountInv (self.inventoryName) + finalAmount > itemInfo.maxAmount)
            return BC_InventoryFull;
        if (player.CountInv ("S7_Cash") < finalPrice)
            return BC_NotEnoughMoney;

        player.TakeInventory ("S7_Cash", finalPrice);
        player.GiveInventory (self.inventoryName, finalAmount);

        return BC_Success;
    }

    virtual play SS_SellCode SellItem (S7_BasePlayer player, int amount, double bonus = 0.0) {
        if (!player)
            return SC_InvalidPlayer;

        let itemInfo = self.GetInfo (player, amount);
        int finalPrice = (itemInfo.sellPrice * amount) + ((itemInfo.sellPrice * amount) * bonus);
        int finalAmount = itemInfo.sellAmount * amount;

        if (player.CountInv (self.inventoryName) < finalAmount)
            return SC_NotEnoughOfItem;
        if (player.CountInv ("S7_Cash") + finalPrice >= player.FindInventory ("S7_Cash").maxAmount)
            return SC_TooMuchMoney;

        player.GiveInventory ("S7_Cash", finalPrice);
        player.TakeInventory (self.inventoryName, finalAmount);

        return SC_Success;
    }

    virtual play bool AddToPage (S7_SSPage page, bool notGlobal) {
        if (!page)
            return false;

        if (notGlobal) {
            uint idx = page.items.Push (self);
            if (idx < 0)
                return false;

            return true;
        }

        let serverData = S7_ServerData.Get ();
        if (!serverData)
            return false;
        if (!serverData.shopData)
            serverData.shopData = new ("S7_ShopData");

        uint idx = page.items.Push (self);
        if (idx < 0)
            return false;

        if (serverData.shopData.allItems.Push (self) < 0) {
            page.items.Delete (idx, 1);
            return false;
        }

        return true;
    }
}

class S7_SSItem_Ammo : S7_SSItem {
    static S7_SSItem_Ammo Create (int id, string name = "", string desc = "", string info = "", string icon = "", string inventoryName = "", SS_ItemType itemType = 0,
        S7_SSPage link = NULL, int maxAmount = -1, int buyPrice = 0, int buyAmount = 0, int sellPrice = 0, int sellAmount = 0, SS_DescShowType descShowType = DS_Both
    ) {
        S7_SSItem_Ammo ret = new ("S7_SSItem_Ammo");

        ret.id              = id;
        ret.name            = name;
        ret.description     = desc;
        ret.infoText        = info;
        ret.icon            = icon;
        ret.inventoryName   = inventoryName;
        ret.itemType        = itemType;
        ret.link            = link;
        ret.info            = new ("S7_SSItemInfo");
        ret.info.maxAmount  = maxAmount;
        ret.info.buyPrice   = buyPrice;
        ret.info.buyAmount  = buyAmount;
        ret.info.sellPrice  = sellPrice;
        ret.info.sellAmount = sellAmount;
        ret.descShowType    = descShowType;

        return ret;
    }

    override S7_SSItemInfo GetInfo (S7_BasePlayer player, int amount) {
        let ret = super.GetInfo (player, amount);

        if (ret.maxAmount < 0) {
            Inventory inv;

            if (player && (inv = player.FindInventory (self.inventoryName)))
                ret.maxAmount = inv.maxAmount;
            else {
                let defaults = GetDefaultByType ((Class<Ammo>) (self.inventoryName));
                ret.maxAmount = defaults ? defaults.maxAmount : 0;
            }
        }

        return ret;
    }
}