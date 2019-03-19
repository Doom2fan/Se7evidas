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

extend class S7_S7DataParser {
    protected S7_SSItem ParseShop_Item_ParseHeader (bool noClassType = false) {
        string itemID;
        string itemClass = "S7_SSItem";
        S7_TZK_Token t;

        // We expect the name and an opening brace '{' to immediately follow
        ParseValue (itemID, VT_String);
        if (itemID.Length () != 4) {
            m_ParsingException = S7_ParsingException.Create (String.Format ("Invalid item id \"%s\". Id must be 4 characters long.", itemID), "S7_S7DataParser.ParseShop_Item_ParseHeader");
            return NULL;
        }

        if (!noClassType) {
            if ((t = m_Tokenizer.Peek ()).type == TOK_Colon) {
                m_Tokenizer.Next ();
                ParseValue (itemClass, VT_String);
            }
        }

        if ((t = m_Tokenizer.Next ()).type != TOK_BraceO) {
            m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop_Item_ParseHeader", TOK_BraceO, t);
            return NULL;
        }

        S7_SSItem item = S7_SSItem (new (itemClass));

        if (!item) {
            m_ParsingException = S7_ParsingException.Create (String.Format ("Item class \"%s\" does not exist", itemClass), "S7_S7DataParser.ParseShop_Item_ParseHeader");
            return NULL;
        }

        item.Init ();
        item.id = S7_Utils.MakeUIDStr (itemID);

        return item;
    }

    protected void ParseShop_Item_PageLink (S7_SSShop shopData, S7_S7DP_TempShopData tmpShopData, S7_SSPage pageData) {
        S7_TZK_Token t;

        let itemData = ParseShop_Item_ParseHeader (true);

        if (!itemData)
            return;

        itemData.itemType = IT_PageLink;

        bool nameParsed = false,
             descParsed = false,
             iconParsed = false,
             linkParsed = false;

        // We're going to keep reading tokens until we hit a closing brace '}'
        for (; (t = m_Tokenizer.Next ()).type != TOK_BraceC;) {
            if (t.type != TOK_Identifier) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop_Item_PageLink", TOK_Identifier, t);
                itemData.Destroy ();
                return;
            }

            name valAsName = t.value;
            switch (valAsName) {
            case 'name':
                if (nameParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"name\" was encountered twice", "S7_S7DataParser.ParseShop_Item_PageLink", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    ParseAssignment (itemData.name, VT_String);
                    nameParsed = true;
                }
            break;

            case 'desc':
                if (descParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"desc\" was encountered twice", "S7_S7DataParser.ParseShop_Item_PageLink", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    ParseAssignment (itemData.description, VT_String);
                    descParsed = true;
                }
            break;

            case 'icon':
                if (iconParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"icon\" was encountered twice", "S7_S7DataParser.ParseShop_Item_PageLink", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    ParseAssignment (itemData.icon, VT_String);
                    iconParsed = true;
                }
            break;

            case 'link':
                if (linkParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"link\" was encountered twice", "S7_S7DataParser.ParseShop_Item_PageLink", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    ParseShop_AssignFakePage (tmpShopData, itemData.link, "link");
                    linkParsed = true;
                }
            break;

            default:
                m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseShop_Item_PageLink", tkn: t);
                itemData.Destroy ();
                return;
            }

            if (m_ParsingException != NULL)
                break;
        }

        if (m_ParsingException != NULL) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_S7DataParser.ParseShop_Item_PageLink", m_ParsingException);
            itemData.Destroy ();
            return;
        }

        if (!nameParsed) {
            m_ParsingException = S7_ParsingException.Create ("Missing name", "S7_S7DataParser.ParseShop_Item_PageLink", m_ParsingException);
            itemData.Destroy ();
            return;
        } else if (!linkParsed) {
            m_ParsingException = S7_ParsingException.Create ("Missing link", "S7_S7DataParser.ParseShop_Item_PageLink", m_ParsingException);
            itemData.Destroy ();
            return;
        }

        itemData.PostProcess ();
        pageData.items.Push (itemData);
    }

    protected void ParseShop_Item_BuySellItem (S7_SSShop shopData, S7_S7DP_TempShopData tmpShopData, S7_SSPage pageData, bool canBuy, bool canSell) {
        S7_TZK_Token t;

        let itemData = ParseShop_Item_ParseHeader (false);

        if (!itemData)
            return;

        if (canBuy)
            itemData.itemType |= IT_BuyItem;
        if (canSell)
            itemData.itemType |= IT_SellItem;

        bool nameParsed          = false,
             descParsed          = false,
             infoParsed          = false,
             iconParsed          = false,
             inventoryNameParsed = false,
             cashItemParsed      = false,
             maxAmountParsed     = false,
             buyPriceParsed      = false,
             buyAmountParsed     = false,
             sellPriceParsed     = false,
             sellAmountParsed    = false;

        // We're going to keep reading tokens until we hit a closing brace '}'
        for (; (t = m_Tokenizer.Next ()).type != TOK_BraceC;) {
            if (t.type != TOK_Identifier) {
                m_ParsingException = S7_BadTokenPE.Create ("S7_S7DataParser.ParseShop_Item_BuySellItem", TOK_Identifier, t);
                itemData.Destroy ();
                return;
            }

            name valAsName = t.value;
            switch (valAsName) {
            case 'name':
                if (nameParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"name\" was encountered twice", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    ParseAssignment (itemData.name, VT_String);
                    nameParsed = true;
                }
            break;

            case 'desc':
                if (descParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"desc\" was encountered twice", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    ParseAssignment (itemData.description, VT_String);
                    descParsed = true;
                }
            break;

            case 'info':
                if (infoParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"info\" was encountered twice", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    ParseAssignment (itemData.infoText, VT_String);
                    infoParsed = true;
                }
            break;

            case 'icon':
                if (iconParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"icon\" was encountered twice", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    ParseAssignment (itemData.icon, VT_String);
                    iconParsed = true;
                }
            break;

            case 'inventoryName':
                if (inventoryNameParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"inventoryName\" was encountered twice", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    ParseAssignment (itemData.inventoryName, VT_String);
                    inventoryNameParsed = true;
                }
            break;

            case 'cashItem':
                if (cashItemParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"cashItem\" was encountered twice", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    ParseAssignment (itemData.cashItem, VT_String);
                    cashItemParsed = true;
                }
            break;

            case 'maxAmount':
                if (maxAmountParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"maxAmount\" was encountered twice", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    string valStr;
                    ParseAssignment (valStr, VT_Integer);
                    itemData.info.maxAmount = valStr.ToInt ();
                    maxAmountParsed = true;
                }
            break;

            case 'buyPrice':
                if (!canBuy) {
                    m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseShop_Item_BuySellItem", tkn: t);
                    itemData.Destroy ();
                    return;
                }

                if (buyPriceParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"buyPrice\" was encountered twice", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    string valStr;
                    ParseAssignment (valStr, VT_Integer);
                    itemData.info.buyPrice = valStr.ToInt ();
                    buyPriceParsed = true;
                }
            break;

            case 'buyAmount':
                if (!canBuy) {
                    m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseShop_Item_BuySellItem", tkn: t);
                    itemData.Destroy ();
                    return;
                }

                if (buyAmountParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"buyAmount\" was encountered twice", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    string valStr;
                    ParseAssignment (valStr, VT_Integer);
                    itemData.info.buyAmount = valStr.ToInt ();
                    buyAmountParsed = true;
                }
            break;

            case 'sellPrice':
                if (!canSell) {
                    m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseShop_Item_BuySellItem", tkn: t);
                    itemData.Destroy ();
                    return;
                }

                if (sellPriceParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"sellPrice\" was encountered twice", "S7_S7DataParser.ParseShop_Item_sellSellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    string valStr;
                    ParseAssignment (valStr, VT_Integer);
                    itemData.info.sellPrice = valStr.ToInt ();
                    sellPriceParsed = true;
                }
            break;

            case 'sellAmount':
                if (!canSell) {
                    m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseShop_Item_BuySellItem", tkn: t);
                    itemData.Destroy ();
                    return;
                }

                if (sellAmountParsed) {
                    m_ParsingException = S7_ParsingException.Create ("\"sellAmount\" was encountered twice", "S7_S7DataParser.ParseShop_Item_sellSellItem", m_ParsingException);
                    itemData.Destroy ();
                    return;
                } else {
                    string valStr;
                    ParseAssignment (valStr, VT_Integer);
                    itemData.info.sellAmount = valStr.ToInt ();
                    sellAmountParsed = true;
                }
            break;

            default:
                m_ParsingException = S7_ParsingException.Create (String.Format ("Unknown keyword %s", t.value), "S7_S7DataParser.ParseShop_Item_BuySellItem", tkn: t);
                itemData.Destroy ();
                return;
            }

            if (m_ParsingException != NULL)
                break;
        }

        if (m_ParsingException != NULL) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
            itemData.Destroy ();
            return;
        }

        if (!cashItemParsed && tmpShopData.defCashItemSet)
            itemData.cashItem = tmpShopData.defCashItem;

        if (!nameParsed) {
            m_ParsingException = S7_ParsingException.Create ("Missing name", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
            itemData.Destroy ();
            return;
        } else if (canBuy && !buyPriceParsed) {
            m_ParsingException = S7_ParsingException.Create ("Missing buying price", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
            itemData.Destroy ();
            return;
        } else if (canSell && !sellPriceParsed) {
            m_ParsingException = S7_ParsingException.Create ("Missing selling price", "S7_S7DataParser.ParseShop_Item_BuySellItem", m_ParsingException);
            itemData.Destroy ();
            return;
        }

        itemData.PostProcess ();
        pageData.items.Push (itemData);
    }
}