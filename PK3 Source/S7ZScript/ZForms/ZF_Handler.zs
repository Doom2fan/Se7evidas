class S7_ZF_Handler ui {
	virtual void buttonClickCommand(S7_ZF_Button caller, string command) {
	}
	
	virtual void buttonHeldCommand(S7_ZF_Button caller, string command) {
	}

	virtual void elementHoverChanged(S7_ZF_Element caller, string command, bool unhovered) {
	}
}