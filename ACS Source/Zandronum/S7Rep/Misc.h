script "S7_GetCasingDelay" (void) {//net clientside {
    int result = getUserCVar (consolePlayerNumber (), "S7_CasingDelay");
    printBold (d:result);
    printBold (s:"S7_GetCasingDelay: Zandronum");
    setResultValue (result);
}