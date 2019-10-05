/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

class S7_S7DP_TempShopData {
    string defCashItem;
    bool defCashItemSet;

    S7_Hashmap_StrObj pages;
    S7_Hashmap_StrObj fakePages;

    static S7_S7DP_TempShopData Create () {
        let ret = new ('S7_S7DP_TempShopData');

        ret.pages = S7_Hashmap_StrObj.Create ();
        ret.fakePages = S7_Hashmap_StrObj.Create ();

        return ret;
    }
}

// Used as placeholders for page links
class S7_S7DP_ShopDataFakePage : S7_SSPage {
    string linkName;
}

extend class S7_S7DataParser {
    protected void ParseShop_AssignFakePage (S7_S7DP_TempShopData tmpShopData, out S7_SSPage pageLink, string varName) {
        string valStr;
        ParseAssignment (valStr, VT_String);

        if (valStr == "") {
            m_ParsingException = S7_ParsingException.Create (String.Format ("\"%s\" cannot be an empty string", varName), "S7_S7DataParser.ParseShop_AssignFakePage");
            return;
        }

        S7_S7DP_ShopDataFakePage page = S7_S7DP_ShopDataFakePage (tmpShopData.fakePages.Get (valStr));

        if (!page) {
            page = new ('S7_S7DP_ShopDataFakePage');
            page.linkName = valStr;
        }

        pageLink = page;
    }

    protected void ParseShop () {
        string shopName;
        let shopData = new ('S7_SSShop');
        let tmpShopData = S7_S7DP_TempShopData.Create ();

        S7_TZK_Token t;

        // We expect the name and an opening brace '{' to immediately follow
        ParseValue (shopName, VT_String);
        if ((t = m_Tokenizer.Next ()).type != TOK_BraceO) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop", TOK_BraceO, t);
            shopData.Destroy ();
            tmpShopData.Destroy ();
            return;
        }

        bool nameParsed            = false,
             mainPageParsed        = false,
             cashLabelFormatParsed = false,
             cashTypeShownParsed   = false,
             buyCostLabelParsed    = false,
             sellCostLabelParsed   = false,
             pageListParsed        = false;

        // We're going to keep reading tokens until we hit a closing brace '}'
        for (; (t = m_Tokenizer.Next ()).type != TOK_BraceC;) {
            if (t.type != TOK_Identifier) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop", TOK_Identifier, t);
                shopData.Destroy ();
                tmpShopData.Destroy ();
                return;
            }

            if (t.value ~== "name") {
                if (nameParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"name\" was encountered twice", "S7_S7DataParser.ParseShop", m_ParsingException);
                    shopData.Destroy ();
                    tmpShopData.Destroy ();
                    return;
                } else {
                    ParseAssignment (shopData.name, VT_String);
                    nameParsed = true;
                }
            }  else if (t.value ~== "mainPage") {
                if (mainPageParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"mainPage\" was encountered twice", "S7_S7DataParser.ParseShop", m_ParsingException);
                    shopData.Destroy ();
                    tmpShopData.Destroy ();
                    return;
                } else {
                    ParseShop_AssignFakePage (tmpShopData, shopData.mainPage, "mainPage");
                    mainPageParsed = true;
                }
            } else if (t.value ~== "cashLabelFormat") {
                if (cashLabelFormatParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"cashLabelFormat\" was encountered twice", "S7_S7DataParser.ParseShop", m_ParsingException);
                    shopData.Destroy ();
                    tmpShopData.Destroy ();
                    return;
                } else {
                    ParseAssignment (shopData.cashLabelFormat, VT_String);
                    cashLabelFormatParsed = true;
                }
            } else if (t.value ~== "cashTypeShown") {
                if (cashTypeShownParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"cashTypeShown\" was encountered twice", "S7_S7DataParser.ParseShop", m_ParsingException);
                    shopData.Destroy ();
                    tmpShopData.Destroy ();
                    return;
                } else {
                    ParseAssignment (shopData.cashTypeShown, VT_String);
                    cashTypeShownParsed = true;
                }
            }  else if (t.value ~== "buyCostLabel") {
                if (buyCostLabelParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"buyCostLabel\" was encountered twice", "S7_S7DataParser.ParseShop", m_ParsingException);
                    shopData.Destroy ();
                    tmpShopData.Destroy ();
                    return;
                } else {
                    ParseAssignment (shopData.buyCostLabel, VT_String);
                    buyCostLabelParsed = true;
                }
            }  else if (t.value ~== "sellCostLabel") {
                if (sellCostLabelParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"sellCostLabel\" was encountered twice", "S7_S7DataParser.ParseShop", m_ParsingException);
                    shopData.Destroy ();
                    tmpShopData.Destroy ();
                    return;
                } else {
                    ParseAssignment (shopData.sellCostLabel, VT_String);
                    sellCostLabelParsed = true;
                }
            } else if (t.value ~== "defCashItem") {
                ParseAssignment (tmpShopData.defCashItem, VT_String);
                tmpShopData.defCashItemSet = true;
            } else if (t.value ~== "pages") {
                ParseShop_PagesList (shopData, tmpShopData);
                pageListParsed = true;
            } else {
                m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseShop", tkn: t);
                shopData.Destroy ();
                tmpShopData.Destroy ();
                return;
            }

            if (m_ParsingException != null)
                break;
        }

        if (m_ParsingException != null) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_S7DataParser.ParseShop", m_ParsingException);
            shopData.Destroy ();
            tmpShopData.Destroy ();
            return;
        }

        if (!mainPageParsed) {
            m_ParsingException = S7_ParsingException.Create ("Shop \"" .. shopName .. "\" has no main page", "S7_S7DataParser.ParseShop", m_ParsingException);
            shopData.Destroy ();
            tmpShopData.Destroy ();
            return;
        } else if (!pageListParsed) {
            m_ParsingException = S7_ParsingException.Create ("Shop \"" .. shopName .. "\" has no pages", "S7_S7DataParser.ParseShop", m_ParsingException);
            shopData.Destroy ();
            tmpShopData.Destroy ();
            return;
        }

        ParseShop_PostProcessing (shopData, tmpShopData);
        parsedData.shopData.shops.Push (shopName, shopData);
    }

    protected void ParseShop_PagesList (S7_SSShop shopData, S7_S7DP_TempShopData tmpShopData) {
        S7_TZK_Token t;

        // We expect an opening brace '{' to immediately follow
        if ((t = m_Tokenizer.Next ()).type != TOK_BraceO) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop_PagesList", TOK_BraceO, t);
            return;
        }

        // We're going to keep reading tokens until we hit a closing brace '}'
        for (; (t = m_Tokenizer.Next ()).type != TOK_BraceC;) {
            if (t.type != TOK_Identifier) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop_PagesList", TOK_Identifier, t);
                return;
            }

            name valAsName = t.value;
            switch (valAsName) {
            case 'page':
                ParseShop_Page (shopData, tmpShopData);
            break;

            default:
                m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseShop_PagesList", tkn: t);
                return;
            }

            if (m_ParsingException != null)
                break;

            t = m_Tokenizer.Next ();
            if (t.type == TOK_BraceC)
                break;

            if (t.type != TOK_Comma) {
                m_ParsingException = S7_ParsingException.Create (String.Format ("Expected ','' or '{', got \"%s\"", t.value), "S7_BaseParser.ParseShop_Page_ItemsList", tkn: t);
                return;
            }
        }

        if (m_ParsingException != null) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_S7DataParser.ParseShop_PagesList", m_ParsingException);
            return;
        }
    }
}