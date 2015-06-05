script "S7_GetCasingDelay" (void) net clientside {
    int result = getUserCVar (consolePlayerNumber (), "S7_CasingDelay");
    setResultValue (result);
}