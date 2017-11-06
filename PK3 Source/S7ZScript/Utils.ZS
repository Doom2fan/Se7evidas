struct S7_Utils {
    static string GenName_Male_Eng () {
        int fore = random [nameGen] (0, S7_NamesList.NL_Male_Eng_Fore.Size () - 1);
        int sur  = random [nameGen] (0, S7_NamesList.NL_Male_Eng_Sur.Size ()  - 1);

        for (int i = 0; i < 50; i++) {
            if (S7_NamesList.NL_Male_Eng_Fore [fore] ~== S7_NamesList.NL_Male_Eng_Sur [sur])
                sur = random [nameGen] (0, S7_NamesList.NL_Male_Eng_Sur.Size () - 1);
            else
                break;
        }

        return String.Format ("%s %s", S7_NamesList.NL_Male_Eng_Fore [fore], S7_NamesList.NL_Male_Eng_Sur [sur]);
    }
}