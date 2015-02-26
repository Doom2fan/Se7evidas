#DEFINE S7_BS_MAXSLOTS 15
global int 4:S7_BS_Inventory [];

#DEFINE S7_INVENTORYMAX 5
str S7_InventoryName [S7_INVENTORYMAX] = { "S7_Raptor", "S7_Shotgun", "S7_TEC9", "S7_Medikit", "S7_Stimpack" };

function int readInventory (int first, int second, int third) {
    return S7_BS_Inventory [third * S7_BS_MAXSLOTS * MAXPLAYERS + second * MAXPLAYERS + first]; // My brain hurts ;-;
}

function void writeInventory (int first, int second, int third, int value) {
    S7_BS_Inventory [third * S7_BS_MAXSLOTS * MAXPLAYERS + second * MAXPLAYERS + first] = value; //;-;
}

function str classifyInventory (int index) {
    return S7_InventoryName [index];
}

/*script "retard" (int HUE, int HURR, int DURR, int BURR) {
    if (HUE == 1) {
        print (s:classifyInventory (readInventory (playerNumber (), HURR, DURR)));
    } else {
        writeInventory (playerNumber (), HURR, DURR, BURR);
    }
}*/