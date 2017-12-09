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

    static int MakeUID (string a, string b, string c, string d) {
        if (a.Length () + b.Length () + c.Length () + d.Length () != 4)
            return 0;

        return (a.CharCodeAt (0) << 24 | b.CharCodeAt (0) << 16 | c.CharCodeAt (0) << 8 | d.CharCodeAt (0));
    }
}