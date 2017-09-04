//-------------------------------------------------------------------------------------------
//
// Cash
//
//-------------------------------------------------------------------------------------------
class S7_CashCounter : S7_Counter { default { +inventory.keepDepleted } }
class S7_CashLesser  : S7_Counter { default { inventory.maxAmount 999;   +inventory.keepDepleted } }
class S7_CashGreater : S7_Counter { default { inventory.maxAmount 30000; +inventory.keepDepleted } }