CC = gdcc-cc
LD = gdcc-ld
ML = gdcc-makelib
COM_FLAGS = --bc-target=ZDoom
CC_FLAGS = $(COM_FLAGS) -DDEBUG

SOURCEDIRECTORY = C_Source

INCDIR = $(SOURCEDIRECTORY)/inc
SRCDIR = $(SOURCEDIRECTORY)/src
OBJDIR = $(SOURCEDIRECTORY)/obj
LIBDIR = $(OBJDIR)/lib

ZDACSDIR = PK3_Source_GZDoom/acs
ZANDROACSDIR = PK3_Source_Zandronum/acs

all: $(OBJDIR) $(ZDACSDIR) $(ZANDROACSDIR) $(ZDACSDIR)/S7Stuff.bin $(ZANDROACSDIR)/S7Stuff.bin

cleanall:
	rm -rf $(OBJDIR) $(ZDACSDIR) $(ZANDROACSDIR)

$(OBJDIR):
	@mkdir "$(OBJDIR)"
	@mkdir "$(OBJDIR)/Common"
	@mkdir "$(OBJDIR)/ZDoom"
	@mkdir "$(OBJDIR)/Zandronum"
	@mkdir "$(OBJDIR)/lib"

$(ZDACSDIR):
	@mkdir "$(ZDACSDIR)"

$(ZANDROACSDIR):
	@mkdir "$(ZANDROACSDIR)"

## ===========================================
##
## Libs
##
## ===========================================

$(LIBDIR)/libc.ir:
	$(ML) $(COM_FLAGS) -c -o $@ libc

$(LIBDIR)/libGDCC.ir:
	$(ML) $(COM_FLAGS) -c -o $@ libGDCC

## ===========================================
##
## S7Stuff.bin
##
## ===========================================

## Common ##
Common_INCDIR = $(INCDIR)/Common
Common_SRCDIR = $(SRCDIR)/Common
Common_OBJDIR = $(OBJDIR)/Common
Common_SRC = $(wildcard $(Common_SRCDIR)/*.c)
Common_OBJ = $(Common_SRC:$(Common_SRCDIR)/%.c=$(Common_OBJDIR)/%.ir)

$(Common_OBJDIR)/%.ir: $(Common_SRCDIR)/%.c
	$(CC) $(CC_FLAGS) -i$(Common_INCDIR) -i$(Common_SRCDIR) -c $< -o $@

$(OBJDIR)/Common.ir: $(Common_OBJ)
	$(LD) $(COM_FLAGS) $^ -co $@

## ZDoom ##
ZDoom_INCDIR = $(INCDIR)/ZDoom
ZDoom_SRCDIR = $(SRCDIR)/ZDoom
ZDoom_OBJDIR = $(OBJDIR)/ZDoom
ZDoom_SRC = $(wildcard $(ZDoom_SRCDIR)/*.c)
ZDoom_OBJ = $(ZDoom_SRC:$(ZDoom_SRCDIR)/%.c=$(ZDoom_OBJDIR)/%.ir)

$(ZDoom_OBJDIR)/%.ir: $(ZDoom_SRCDIR)/%.c
	$(CC) $(CC_FLAGS) -i$(ZDoom_INCDIR) -i$(Common_INCDIR) -i$(ZDoom_SRCDIR) -c $< -o $@

$(OBJDIR)/ZDoom.ir: $(ZDoom_OBJ)
	$(LD) $(COM_FLAGS) $^ -co $@

$(ZDACSDIR)/S7Stuff.bin: $(LIBDIR)/libc.ir $(LIBDIR)/libGDCC.ir $(OBJDIR)/Common.ir $(OBJDIR)/ZDoom.ir
	$(LD) $(COM_FLAGS) $^ -o $@

## Zandronum ##
Zandronum_INCDIR = $(INCDIR)/Zandronum
Zandronum_SRCDIR = $(SRCDIR)/Zandronum
Zandronum_OBJDIR = $(OBJDIR)/Zandronum
Zandronum_SRC = $(wildcard $(Zandronum_SRCDIR)/*.c)
Zandronum_OBJ = $(Zandronum_SRC:$(Zandronum_SRCDIR)/%.c=$(Zandronum_OBJDIR)/%.ir)

$(Zandronum_OBJDIR)/%.ir: $(Zandronum_SRCDIR)/%.c
	$(CC) $(CC_FLAGS) -i$(Zandronum_INCDIR) -i$(Common_INCDIR) -i$(Zandronum_SRCDIR) -c $< -o $@

$(OBJDIR)/Zandronum.ir: $(Zandronum_OBJ)
	$(LD) $(COM_FLAGS) $^ -co $@

$(ZANDROACSDIR)/S7Stuff.bin: $(LIBDIR)/libc.ir $(LIBDIR)/libGDCC.ir $(OBJDIR)/Common.ir $(OBJDIR)/Zandronum.ir
	$(LD) $(COM_FLAGS) $^ -o $@