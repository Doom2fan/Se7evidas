## Change this as needed
## Executables and flags ##
CC = gdcc-cc
LD = gdcc-ld
ML = gdcc-makelib
MenuGUI_Compiler = Tools/playermenuCompiler/playermenucompiler
MKDIRCMD = gmkdir
COM_FLAGS = --bc-target=ZDoom
CC_FLAGS = $(COM_FLAGS) -DDEBUG
LD_LIB_FLAGS = $(COM_FLAGS) -lS7Stuff
## Directories ##
SOURCEDIRECTORY = C_Source
INCDIR = $(SOURCEDIRECTORY)/inc
SRCDIR = $(SOURCEDIRECTORY)/src
OBJDIR = $(SOURCEDIRECTORY)/obj
LIBDIR = $(OBJDIR)/lib
ZDACSDIR = PK3_Source_GZDoom/acs
ZANDROACSDIR = PK3_Source_Zandronum/acs
SHELL = C:/Windows/System32/cmd.exe
## Commands ##
rwildcardInt = $(wildcard $(1)) $(foreach d, $(wildcard $(1)*), $(call rwildcardInt, $(d)/))
rwildcard = $(filter $(2), $(call rwildcardInt, $(1)/))

.PHONY: all
all: MenuGUI $(ZDACSDIR)/S7Stuff.bin $(ZANDROACSDIR)/S7Stuff.bin

.PHONY: cleanall
cleanall:
	-rm -rf "$(OBJDIR)" "$(ZDACSDIR)" "$(ZANDROACSDIR)" "$(MenuGUI_OBJDIR)"

## ===========================================
##
## Libs
##
## ===========================================

$(LIBDIR)/libc.ir:
	@$(MKDIRCMD) -p "$(@D)"
	$(ML) $(COM_FLAGS) -c -o $@ libc

$(LIBDIR)/libGDCC.ir:
	@$(MKDIRCMD) -p "$(@D)"
	$(ML) $(COM_FLAGS) -c -o $@ libGDCC

## ===========================================
##
## S7Stuff.bin
##
## ===========================================

## Playermenu GUI ##
MenuGUI_SRCDIR = $(SOURCEDIRECTORY)/guiSrc
MenuGUI_OBJDIR = $(SRCDIR)/Common/guiSrc
MenuGUI_SRC = $(call rwildcard, $(MenuGUI_SRCDIR), %.json)
MenuGUI_OBJ = $(MenuGUI_SRC:$(MenuGUI_SRCDIR)/%.json=$(MenuGUI_OBJDIR)/%.c)

$(MenuGUI_OBJDIR)/%.c: $(MenuGUI_SRCDIR)/%.json
	@$(MKDIRCMD) -p "$(@D)"
	$(MenuGUI_Compiler)  --file $< --out $(MenuGUI_OBJDIR)

.PHONY: MenuGUI
MenuGUI: $(MenuGUI_OBJ)

## Common ##
Common_INCDIR = $(INCDIR)/Common
Common_SRCDIR = $(SRCDIR)/Common
Common_OBJDIR = $(OBJDIR)/Common
Common_SRC = $(sort $(call rwildcard, $(Common_SRCDIR), %.c) $(MenuGUI_OBJ))
Common_OBJ = $(Common_SRC:$(Common_SRCDIR)/%.c=$(Common_OBJDIR)/%.ir)

$(Common_OBJ): $(Common_OBJDIR)/%.ir: $(Common_SRCDIR)/%.c
	@$(MKDIRCMD) -p "$(@D)"
	$(CC) $(CC_FLAGS) -i$(Common_INCDIR) -i$(Common_SRCDIR) -c $< -o $@

$(OBJDIR)/Common.ir: $(Common_OBJ)
	@$(MKDIRCMD) -p "$(@D)"
	$(LD) $(COM_FLAGS) $^ -co $@

## ZDoom ##
ZDoom_INCDIR = $(INCDIR)/ZDoom
ZDoom_SRCDIR = $(SRCDIR)/ZDoom
ZDoom_OBJDIR = $(OBJDIR)/ZDoom
ZDoom_SRC = $(call rwildcard, $(ZDoom_SRCDIR), %.c)
ZDoom_OBJ = $(ZDoom_SRC:$(ZDoom_SRCDIR)/%.c=$(ZDoom_OBJDIR)/%.ir)

$(ZDoom_OBJ): $(ZDoom_OBJDIR)/%.ir: $(ZDoom_SRCDIR)/%.c
	@$(MKDIRCMD) -p "$(@D)"
	$(CC) $(CC_FLAGS) -i$(ZDoom_INCDIR) -i$(Common_INCDIR) -i$(ZDoom_SRCDIR) -c $< -o $@

$(OBJDIR)/ZDoom.ir: $(ZDoom_OBJ)
	@$(MKDIRCMD) -p "$(@D)"
	$(LD) $(COM_FLAGS) $^ -co $@

$(ZDACSDIR)/S7Stuff.bin: $(LIBDIR)/libc.ir $(LIBDIR)/libGDCC.ir $(OBJDIR)/Common.ir $(OBJDIR)/ZDoom.ir
	@$(MKDIRCMD) -p "$(@D)"
	$(LD) $(LD_LIB_FLAGS) $^ -o $@

## Zandronum ##
Zandronum_INCDIR = $(INCDIR)/Zandronum
Zandronum_SRCDIR = $(SRCDIR)/Zandronum
Zandronum_OBJDIR = $(OBJDIR)/Zandronum
Zandronum_SRC = $(call rwildcard, $(Zandronum_SRCDIR), %.c)
Zandronum_OBJ = $(Zandronum_SRC:$(Zandronum_SRCDIR)/%.c=$(Zandronum_OBJDIR)/%.ir)

$(Zandronum_OBJ): $(Zandronum_OBJDIR)/%.ir: $(Zandronum_SRCDIR)/%.c
	@$(MKDIRCMD) -p "$(@D)"
	$(CC) $(CC_FLAGS) -i$(Zandronum_INCDIR) -i$(Common_INCDIR) -i$(Zandronum_SRCDIR) -c $< -o $@

$(OBJDIR)/Zandronum.ir: $(Zandronum_OBJ)
	@$(MKDIRCMD) -p "$(@D)"
	$(LD) $(COM_FLAGS) $^ -co $@

$(ZANDROACSDIR)/S7Stuff.bin: $(LIBDIR)/libc.ir $(LIBDIR)/libGDCC.ir $(OBJDIR)/Common.ir $(OBJDIR)/Zandronum.ir
	@$(MKDIRCMD) -p "$(@D)"
	$(LD) $(LD_LIB_FLAGS) $^ -o $@