// ========================================================
//
//  The code in this file was made by Marrub
//
// ========================================================

#ifndef DEFS_H
#define DEFS_H

#define ACS_SHORT_NAMES
#include <ACS_ZDoom.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdfix.h>
#include <inttypes.h>
#include <stdint.h>
#include <string.h>
#include <stddef.h>
#include <stdbool.h>
#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <math.h>

#define I_SCRIPT(n) [[address(n), call("ScriptI")]]
#define S_SCRIPT [[call("ScriptS")]]
#define EXTACS [[extern("ACS")]]
#define ACS_I_SCRIPT(n) EXTACS I_SCRIPT(n)
#define ACS_S_SCRIPT EXTACS S_SCRIPT
#define ACS_SCRIPT EXTACS S_SCRIPT

#define OPEN [[script("Open")]]
#define ENTER [[script("Enter")]]
#define DISCONNECT [[script("Disconnect")]]
#define DEATH [[script("Death")]]
#define NET [[script("Net")]]
#define CLIENTSIDE [[script("Clientside")]]

#define ALLOC(n) [[alloc_Loc(n)]]
#define OPT_ARGS(n) [[optional_args(n)]]

#define Script_C ACS_SCRIPT
#define Script_L S_SCRIPT

#define COL_BRICK     "\Ca"
#define COL_TAN       "\Cb"
#define COL_GRAY      "\Cc"
#define COL_GREEN     "\Cd"
#define COL_BROWN     "\Ce"
#define COL_GOLD      "\Cf"
#define COL_RED       "\Cg"
#define COL_BLUE      "\Ch"
#define COL_ORANGE    "\Ci"
#define COL_WHITE     "\Cj"
#define COL_YELLOW    "\Ck"
#define COL_RETURN    "\Cl"
#define COL_BLACK     "\Cm"
#define COL_LBLUE     "\Cn"
#define COL_CREAM     "\Co"
#define COL_OLIVE     "\Cp"
#define COL_DARKGREEN "\Cq"
#define COL_DARKRED   "\Cr"
#define COL_DARKBROWN "\Cs"
#define COL_PURPLE    "\Ct"
#define COL_DARKGRAY  "\Cu"
#define COL_CYAN      "\Cv"
#define COL_DEFPRINT  "\C-"
#define COL_DEFPRINTB "\C+"
#define COL_DEFCHAT   "\C*"
#define COL_DEFTCHAT  "\C!"

#ifndef off
#define off 0
#endif

#ifndef false
#define false 0
#endif

#ifndef on
#define on 1
#endif

#ifndef true
#define true 1
#endif

#define MAX_PLAYERS 64

#define lerp(a, b, t) (((1.0 - t) * a) + (t * b))
#define norm(a, min, max) (1.0 / (max - min) * (a - max) + max)

#define HudMessage(flags, id, color, x, y, hold, opt1, opt2, opt3, ...) \
  ( \
   BeginHudMessage(), \
   __nprintf(__VA_ARGS__), \
   MoreHudMessage(), \
   OptHudMessage(flags, id, color, x, y, hold), \
   EndHudMessageXXX(opt1, opt2, opt3) \
  )
#define PrintBold(...) \
  ( \
   BeginPrintBold(), \
   __nprintf(__VA_ARGS__), \
   EndPrint() \
  )
#define Print(...) \
  ( \
   BeginPrint(), \
   __nprintf(__VA_ARGS__), \
   EndPrint() \
  )
#define StrParam(...) \
  ( \
   BeginStrParam(), \
   __nprintf(__VA_ARGS__), \
   EndStrParam() \
  )
#define PrintSprite(spr, id, x, y, delay) \
  ( \
   SetFont(spr), \
   HudMessage(HUDMSG_PLAIN, id, CR_UNTRANSLATED, x, y, delay, 0.0, 0.0, 0.0, "A") \
  )
#define ClearMessage(id) \
  ( \
   HudMessage(HUDMSG_PLAIN, id, CR_UNTRANSLATED, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, "") \
  )
#define Log(...) \
  ( \
   BeginLog(), \
   __nprintf(__VA_ARGS__), \
   EndLog() \
  )
// PlayerName fixed by Chronos "phantombeta" Ouroboros
#define PlayerName(num) \
  ( \
   ACS_BeginPrint(), \
   ACS_PrintName(num), \
   EndPrint() \
  )
// StrToACS fixed by Chronos "phantombeta" Ouroboros
#define StrToACS(s) \
  ( \
   BeginStrParam(), \
   __nprintf("%s", s), \
   EndStrParam() \
  )

// [CO] Added str versions of the above macros
#define HudMessage_Str(flags, id, color, x, y, hold, opt1, opt2, opt3, ...) \
  ( \
   BeginHudMessage(), \
   __nprintf_str(__VA_ARGS__), \
   MoreHudMessage(), \
   OptHudMessage(flags, id, color, x, y, hold), \
   EndHudMessageXXX(opt1, opt2, opt3) \
  )
#define PrintBold_Str(...) \
  ( \
   BeginPrintBold(), \
   __nprintf_str(__VA_ARGS__), \
   EndPrint() \
  )
#define Print_Str(...) \
  ( \
   BeginPrint(), \
   __nprintf_str(__VA_ARGS__), \
   EndPrint() \
  )
#define StrParam_Str(...) \
  ( \
   BeginStrParam(), \
   __nprintf_str(__VA_ARGS__), \
   EndStrParam() \
  )
#define PrintSprite_Str(spr, id, x, y, delay) \
  ( \
   SetFont(spr), \
   HudMessage_Str(HUDMSG_PLAIN, id, CR_UNTRANSLATED, x, y, delay, 0.0, 0.0, 0.0, s"A") \
  )
#define ClearMessage_Str(id) \
  ( \
   HudMessage_Str(HUDMSG_PLAIN, id, CR_UNTRANSLATED, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, s"") \
  )
#define Log_Str(...) \
  ( \
   BeginLog(), \
   __nprintf_str(__VA_ARGS__), \
   EndLog() \
  )

typedef __str string;

#endif