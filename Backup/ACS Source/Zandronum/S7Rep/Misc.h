script "S7_GetEffectsStayTime" (void) NET CLIENTSIDE {
    int result = getUserCVar (CPLN, "S7_EffectStayTime");
    setResultValue (result);
}

script "S7_GetEffectsFadeSpeed" (void) NET CLIENTSIDE {
    int result = getUserCVar (CPLN, "S7_EffectFadeSpeed");
    setResultValue (result);
}