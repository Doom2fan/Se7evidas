class S7_ShopData {
    Array<S7_SSItem> allItems;
}

class S7_ShopDataEventHandler : EventHandler {
    override void WorldLoaded (WorldEvent e) {
        let serverData = S7_ServerData.Get ();
        
        Populate (serverData);
    }

    override void WorldTick () {
        let serverData = S7_ServerData.Get ();
        
        Populate (serverData);
    }

    void Populate (S7_ServerData serverData) {
        if (!serverData.shopData) {
            serverData.shopData = new ("S7_ShopData");
            mainShop_Populate (serverData);
        }
    }
}