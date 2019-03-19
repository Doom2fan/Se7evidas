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
    protected void ParseShop_PostProc_ReplaceFakePage (out S7_SSPage page, S7_S7DP_TempShopData tmpShopData) {
        if (!page)
            return;
        if (!(page is 'S7_S7DP_ShopDataFakePage')) // Uhh... Okay...
            return;

        let fakePage = S7_S7DP_ShopDataFakePage (page);

        if (fakePage.linkName == "") {
            ThrowAbortException ("Encountered an empty string while replacing a link placeholder");
            return;
        }

        page = S7_SSPage (tmpShopData.pages.Get (fakePage.linkName));

        if (!page) {
            m_ParsingException = S7_ParsingException.Create (String.Format ("Page \"%s\" does not exist", fakePage.linkName), "S7_S7DataParser.ParseShop_PostProc_ReplaceFakePage");
            return;
        }
    }

    protected void ParseShop_PostProcessing (S7_SSShop shopData, S7_S7DP_TempShopData tmpShopData) {
        ParseShop_PostProc_ReplaceFakePage (shopData.mainPage, tmpShopData);

        if (m_ParsingException != NULL) {
            m_ParsingException = S7_ParsingException.Create ("", "S7_S7DataParser.ParseShop_PostProcessing", m_ParsingException);
            return;
        }

        let pages = new ('S7_TZK_ArrayObj');
        pages.Clear ();

        tmpShopData.pages.GetValues (pages);

        for (int i = 0; i < pages.Size (); i++) {
            let page = S7_SSPage (pages.Values [i]);

            if (!page)
                continue;

            ParseShop_PostProc_ReplaceFakePage (page.backPage, tmpShopData);

            for (int i = 0; i < page.items.Size (); i++) {
                let item = page.items [i];

                if (!item)
                    continue;

                ParseShop_PostProc_ReplaceFakePage (item.link, tmpShopData);
                if ((item.itemType & IT_BuySellItem) != 0)
                    parsedData.shopData.allItems.Push (item);
            }
        }
    }
}