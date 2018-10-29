/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

//-------------------------------------------------------------------------------------------
//
// Cash
//
//-------------------------------------------------------------------------------------------
class S7_Cash : S7_Counter { default { Inventory.MaxAmount 0x7FFFFFFE; +inventory.keepDepleted } }

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
    string cashLabelFormat;
    string cashTypeShown;
    S7_SSPage mainPage;
}

class S7_SSPage {
    string name;
    string cashLabelFormat;
    string cashTypeShown;
    S7_SSPage backPage;
    Array<S7_SSItem> items;
}

class S7_SSItemInfo {
    uint maxAmount;
    uint buyPrice;
    uint buyAmount;
    uint sellPrice;
    uint sellAmount;
    S7_SSItemInfo Copy () {
        let ret = new ('S7_SSItemInfo');
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
    string cashItem;
    S7_SSItemInfo info;
    SS_DescShowType descShowType;

    virtual void Init () {
        self.name       = "";
        description     = "";
        infoText        = "";
        icon            = "";
        inventoryName   = "";
        itemType        = 0;
        link            = NULL;
        cashItem        = "S7_Cash";
        info            = new ('S7_SSItemInfo');
        info.maxAmount  = -1;
        info.buyPrice   = 0;
        info.buyAmount  = 1;
        info.sellPrice  = 0;
        info.sellAmount = 1;
        descShowType    = DS_Both;
    }

    virtual void PostProcess () { }

    virtual int GetAmount (S7_BasePlayer player) {
        return player.CountInv (inventoryName);
    }

    virtual bool CanBuy (S7_BasePlayer player, int amount) {
        S7_SSItemInfo info = GetInfo (player, amount);

        return (GetAmount (player) + info.buyAmount) <= info.maxAmount &&
                player.CountInv (cashItem) >= info.buyPrice;
    }

    virtual bool CanSell (S7_BasePlayer player, int amount) {
        S7_SSItemInfo info = GetInfo (player, amount);

        int maxCashAmount = 0;

        let cashInv = player.FindInventory (cashItem);
        let defCashInv = GetDefaultByType ((class<Inventory>) (cashItem));
        if (cashInv)
            maxCashAmount = cashInv.MaxAmount;
        else if (defCashInv)
            maxCashAmount = defCashInv.MaxAmount;
        else
            return false;


        return GetAmount (player) >= info.sellAmount &&
                info.sellPrice <= maxCashAmount;
    }

    virtual S7_SSItemInfo GetInfo (S7_BasePlayer player, int amount) {
        let ret = self.info.Copy ();

        if (ret.maxAmount < 0) {
            Inventory inv;

            if (player && (inv = player.FindInventory (self.inventoryName)))
                ret.maxAmount = inv.maxAmount;
            else if (self.inventoryName != "") {
                let defaults = GetDefaultByType ((Class<Inventory>) (self.inventoryName));
                ret.maxAmount = defaults ? defaults.maxAmount : 0;
            }
        }

        ret.buyPrice *= amount;
        ret.buyAmount *= amount;
        ret.sellPrice *= amount;
        ret.sellAmount *= amount;

        return ret;
    }

    virtual play SS_BuyCode BuyItem (S7_BasePlayer player, int amount, double discount = 0.0) {
        if (!player)
            return BC_InvalidPlayer;

        let itemInfo = self.GetInfo (player, amount);
        int finalPrice = int ((itemInfo.buyPrice) - ((itemInfo.buyPrice) * discount));
        int finalAmount = itemInfo.buyAmount;

        if (player.CountInv (self.inventoryName) + finalAmount > itemInfo.maxAmount)
            return BC_InventoryFull;
        if (player.CountInv (self.cashItem) < finalPrice)
            return BC_NotEnoughMoney;
        if (!CanBuy (player, amount))
            return BC_Unknown;

        player.TakeInventory (self.cashItem, finalPrice);
        player.GiveInventory (self.inventoryName, finalAmount);

        return BC_Success;
    }

    virtual play SS_SellCode SellItem (S7_BasePlayer player, int amount, double bonus = 0.0) {
        if (!player)
            return SC_InvalidPlayer;

        let itemInfo = self.GetInfo (player, amount);
        int finalPrice = int ((itemInfo.sellPrice) + ((itemInfo.sellPrice) * bonus));
        int finalAmount = itemInfo.sellAmount;

        if (player.CountInv (self.inventoryName) < finalAmount)
            return SC_NotEnoughOfItem;
        if (uint (uint (player.CountInv (self.cashItem)) + uint (finalPrice)) >= player.FindInventory (self.cashItem).maxAmount)
            return SC_TooMuchMoney;
        if (!CanSell (player, amount))
            return SC_Unknown;

        S7_BaseWeapon weap;
        if (weap = S7_BaseWeapon (player.FindInventory (inventoryName)))
            weap.SS_PreSell (amount);

        player.GiveInventory (self.cashItem, finalPrice);
        player.TakeInventory (self.inventoryName, finalAmount);

        if (weap = S7_BaseWeapon (player.FindInventory (inventoryName)))
            weap.SS_OnSell (amount);

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
        if (!serverData.S7Data.shopData)
            serverData.S7Data.shopData = new ('S7_ShopData');

        uint idx = page.items.Push (self);
        if (idx < 0)
            return false;

        if (serverData.S7Data.shopData.allItems.Push (self) < 0) {
            page.items.Delete (idx, 1);
            return false;
        }

        return true;
    }
}

class S7_SSItem_Armor : S7_SSItem {
    override bool CanBuy (S7_BasePlayer player, int amount) {
        let basicArmor = S7_BasicArmor (player.FindInventory ('S7_BasicArmor'));

        if (!basicArmor || basicArmor.ArmorType != inventoryName || basicArmor.Amount < basicArmor.ActualSaveAmount)
            return Super.CanBuy (player, amount);
        else
            return false;
    }
}

class S7_SSItem_Upgrade : S7_SSItem {
    Array<string> requiredUpgrades;

    override void PostProcess () {
        Array<string> strings;
        inventoryName.Split (strings, ";");

        if (strings.Size () > 1)
            inventoryName = strings [0];
        if (strings.Size () > 0)
            strings.Delete (0, 1);

        requiredUpgrades.Copy (strings);
    }

    override bool CanBuy (S7_BasePlayer player, int amount) {
        for (int i = 0; i < requiredUpgrades.Size (); i++) {
            string reqItemName = requiredUpgrades [i];
            int reqItemAmount = 1;

            int sepIndex = requiredUpgrades [i].IndexOf (",");
            if (sepIndex != -1) {
                reqItemName = requiredUpgrades [i].Left (sepIndex);
                reqItemAmount = requiredUpgrades [i].Mid (sepIndex + 1).ToInt ();
            }
            
            if (player.CountInv (reqItemName) < reqItemAmount)
                return false;
        }

        return Super.CanBuy (player, amount);
    }

    override bool CanSell (S7_BasePlayer player, int amount) {
        return false;
    }
}

class S7_SSItem_ThumperGrenade : S7_SSItem {
    const UnifiedPoolName = "S7_Thumper_PUnified";

    override S7_SSItemInfo GetInfo (S7_BasePlayer player, int amount) {
        let ret = self.info.Copy ();

        Inventory unifiedPool;

        if (player && (unifiedPool = player.FindInventory (UnifiedPoolName)))
            ret.maxAmount = unifiedPool.maxAmount;
        else {
            let defaults = GetDefaultByType ((Class<Inventory>) (UnifiedPoolName));
            ret.maxAmount = defaults ? defaults.maxAmount : 0;
        }

        ret.buyPrice *= amount;
        ret.buyAmount *= amount;
        ret.sellPrice *= amount;
        ret.sellAmount *= amount;

        return ret;
    }

    override int GetAmount (S7_BasePlayer player) {
        if (!player)
            return 0;

        return S7_Thumper_PUnified.CalculateUnifiedAmount (player);
    }
}