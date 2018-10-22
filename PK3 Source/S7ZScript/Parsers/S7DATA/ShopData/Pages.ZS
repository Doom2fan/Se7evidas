/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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

extend class S7_S7DataParser {
    protected void ParseShop_Page (S7_SSShop shopData, S7_S7DP_TempShopData tmpShopData) {
        string pageName;
        let pageData = new ("S7_SSPage");

        TZK_Token t;

        // We expect the name and an opening brace '{' to immediately follow
        ParseValue (pageName, VT_String);
        if ((t = m_Tokenizer.Next ()).type != TOK_BraceO) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop_Page", TOK_BraceO, t);
            pageData.Destroy ();
            return;
        }

        bool nameParsed            = false,
             cashLabelFormatParsed = false,
             cashTypeShownParsed   = false,
             backPageParsed        = false;

        // We're going to keep reading tokens until we hit a closing brace '}'
        for (; (t = m_Tokenizer.Next ()).type != TOK_BraceC;) {
            if (t.type != TOK_Identifier) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop_Page", TOK_Identifier, t);
                pageData.Destroy ();
                return;
            }

            name valAsName = t.value;
            switch (valAsName) {
            case 'name':
                if (nameParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"name\" was encountered twice", "S7_S7DataParser.ParseShop_Page", m_ParsingException);
                    pageData.Destroy ();
                    return;
                } else {
                    ParseAssignment (pageData.name, VT_String);
                    nameParsed = true;
                }
            break;

            case 'cashLabelFormat':
                if (cashLabelFormatParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"cashLabelFormat\" was encountered twice", "S7_S7DataParser.ParseShop_Page", m_ParsingException);
                    pageData.Destroy ();
                    return;
                } else {
                    ParseAssignment (pageData.cashLabelFormat, VT_String);
                    cashLabelFormatParsed = true;
                }
            break;

            case 'cashTypeShown':
                if (cashTypeShownParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"cashTypeShown\" was encountered twice", "S7_S7DataParser.ParseShop_Page", m_ParsingException);
                    pageData.Destroy ();
                    return;
                } else {
                    ParseAssignment (pageData.cashTypeShown, VT_String);
                    cashTypeShownParsed = true;
                }
            break;

            case 'backPage':
                if (backPageParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"backPage\" was encountered twice", "S7_S7DataParser.ParseShop_Page", m_ParsingException);
                    pageData.Destroy ();
                    return;
                } else {
                    ParseShop_AssignFakePage (tmpShopData, pageData.backPage, "backPage");
                    backPageParsed = true;
                }
            break;

            case 'items':
                ParseShop_Page_ItemsList (shopData, tmpShopData, pageData);
            break;

            default:
                m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseShop_Page", tkn: t);
                pageData.Destroy ();
                return;
            }

            if (m_ParsingException != NULL)
                break;
        }

        if (m_ParsingException != NULL) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_S7DataParser.ParseShop_Page", m_ParsingException);
            pageData.Destroy ();
            return;
        }

        tmpShopData.pages.Push (pageName, pageData);
    }

    protected void ParseShop_Page_ItemsList (S7_SSShop shopData, S7_S7DP_TempShopData tmpShopData, S7_SSPage pageData) {
        TZK_Token t;

        // We expect the name and an opening brace '{' to immediately follow
        if ((t = m_Tokenizer.Next ()).type != TOK_BraceO) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop_Page_ItemsList", TOK_BraceO, t);
            return;
        }

        // We're going to keep reading tokens until we hit a closing brace '}'
        for (; (t = m_Tokenizer.Next ()).type != TOK_BraceC;) {
            if (t.type != TOK_Identifier) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop_Page_ItemsList", TOK_Identifier, t);
                return;
            }

            if (t.value ~== "pageLink")
                ParseShop_Item_PageLink (shopData, tmpShopData, pageData);
            else if (t.value ~== "buySellItem")
                ParseShop_Item_BuySellItem (shopData, tmpShopData, pageData, true, true);
            else if (t.value ~== "buyItem")
                ParseShop_Item_BuySellItem (shopData, tmpShopData, pageData, true, false);
            else if (t.value ~== "sellItem")
                ParseShop_Item_BuySellItem (shopData, tmpShopData, pageData, false, true);
            else {
                m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseShop_Page_ItemsList", tkn: t);
                return;
            }

            if (m_ParsingException != NULL)
                break;

            t = m_Tokenizer.Next ();
            if (t.type == TOK_BraceC)
                break;

            if (t.type != TOK_Comma) {
                m_ParsingException = S7_ParsingException.Create (String.Format ("Expected ','' or '{', got \"%s\"", t.value), "S7_BaseParser.ParseShop_Page_ItemsList", tkn: t);
                return;
            }
        }

        if (m_ParsingException != NULL) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_S7DataParser.ParseShop_Page_ItemsList", m_ParsingException);
            return;
        }
    }
}