class S7_ZF_Handler ui {
	virtual void buttonClickCommand(S7_ZF_Button caller, string command) {
	}
	
	virtual void buttonHeldCommand(S7_ZF_Button caller, string command) {
	}

	virtual void radioButtonChanged(S7_ZF_RadioButton caller, string command, S7_ZF_RadioController variable) {
	}

	virtual void toggleButtonChanged(S7_ZF_ToggleButton caller, string command, bool on) {
	}

	virtual void textInputExit(S7_ZF_TextInput caller, string command) {
	}

	virtual void textInputChanged(S7_ZF_TextInput caller, string command) {
	}

	virtual void sliderChanged(S7_ZF_Slider caller, string command) {
	}

	virtual void dropdownChanged(S7_ZF_DropdownList caller, string command) {
	}

	virtual void elementHoverChanged(S7_ZF_Element caller, string command, bool unhovered) {
	}
}
