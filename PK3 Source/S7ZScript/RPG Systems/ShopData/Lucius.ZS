extend class S7_ShopData {
    S7_SSShop mainShop;
}

extend class S7_ShopDataEventHandler {
    void mainShop_Populate (S7_ServerData serverData) {
        if (!serverData || (serverData.shopData && serverData.shopData.mainShop))
            return;

        S7_SSPage mainPage = new ("S7_SSPage");
        S7_SSPage ammoPage = new ("S7_SSPage");
        S7_SSPage cartridgesPage = new ("S7_SSPage");
        S7_SSPage batteriesPage = new ("S7_SSPage");
        S7_SSPage thumperGrenadesPage = new ("S7_SSPage");
        S7_SSPage weaponsPage = new ("S7_SSPage");

        /* mainPage */
        mainPage.name = "";
        S7_SSItem.Create (
            S7_Utils.MakeUID ("M", "P", "A", "M"),
            name:          "$SS_AMMO",
            desc:          "$SS_AMMO_DESC",
            icon:          "graphics/Menu/Shop/Icons/AmmoPage.png",
            itemType:      IT_PageLink,
            link:          ammoPage
        ).AddToPage (mainPage, true);
        S7_SSItem.Create (
            S7_Utils.MakeUID ("M", "P", "W", "P"),
            name:          "$SS_WEAPONS",
            desc:          "$SS_WEAPONS_DESC",
            icon:          "graphics/Menu/Shop/Icons/WeapsPage.png",
            itemType:      IT_PageLink,
            link:          weaponsPage
        ).AddToPage (mainPage, true);
        /* ammoPage */
        ammoPage.name = "$SS_AMMO";
        S7_SSItem.Create (
            S7_Utils.MakeUID ("B", "A", "C", "K"),
            name:          "$SS_BACK",
            desc:          "$SS_BACK_DESC",
            icon:          "M_BACK_D",
            itemType:      IT_PageLink,
            link:          mainPage
        ).AddToPage (ammoPage, true);
        S7_SSItem.Create (
            S7_Utils.MakeUID ("A", "B", "L", "T"),
            name:          "$SS_BULLETS",
            desc:          "$SS_BULLETS_DESC",
            icon:          "graphics/Menu/Shop/Icons/BulletsPage.png",
            itemType:      IT_PageLink,
            link:          cartridgesPage
        ).AddToPage (ammoPage, true);
        S7_SSItem.Create (
            S7_Utils.MakeUID ("A", "B", "T", "R"),
            name:          "$SS_BATTERIES",
            desc:          "$SS_BATTERIES_DESC",
            icon:          "graphics/Menu/Shop/Icons/BattPage.png",
            itemType:      IT_PageLink,
            link:          batteriesPage
        ).AddToPage (ammoPage, true);
        S7_SSItem.Create (
            S7_Utils.MakeUID ("A", "T", "H", "G"),
            name:          "$SS_THGRENADES",
            desc:          "$SS_THGRENADES_DESC",
            icon:          "graphics/Menu/Shop/Icons/ThmpGrenPage.png",
            itemType:      IT_PageLink,
            link:          thumperGrenadesPage
        ).AddToPage (ammoPage, true);
        /* cartridgesPage */
        cartridgesPage.name = "$SS_BULLETS";
        S7_SSItem.Create (
            S7_Utils.MakeUID ("B", "A", "C", "K"),
            name:          "$SS_BACK",
            desc:          "$SS_BACK_DESC",
            icon:          "M_BACK_D",
            itemType:      IT_PageLink,
            link:          ammoPage
        ).AddToPage (cartridgesPage, true);
        S7_SSItem_Ammo.Create (
            S7_Utils.MakeUID ("A", "9", "M", "M"),
            name:          "$9MM",
            desc:          "$SS_9MMDESC",
            info:          "$SS_9MMINFO",
            icon:          "graphics/Menu/Shop/Icons/9mmCartridges.png",
            inventoryName: "S7_9mmCartridges",
            itemType:      IT_BuySellItem,
            buyPrice:      240,
            buyAmount:     30,
            sellPrice:     120,
            sellAmount:    30
        ).AddToPage (cartridgesPage, false);
        /* batteriesPage */
        batteriesPage.name = "$SS_BATTERIES";
        /* thumperGrenadesPage */
        thumperGrenadesPage.name = "$SS_THGRENADES";
        /* weaponsPage */
        weaponsPage.name = "$SS_WEAPONS";

        let shop = new ("S7_SSShop");
        shop.name = "$SS_MAINSHOP";
        shop.mainPage = mainPage;
        serverData.shopData.mainShop = shop;
    }
}