AS = gdcc-as
CC = gdcc-cc
LD = gdcc-ld

SOURCEDIRECTORY = C_Source
INCDIR = $(SOURCEDIRECTORY)/inc
SRCDIR = $(SOURCEDIRECTORY)/src
OBJDIR = $(SOURCEDIRECTORY)/obj
ZDACSDIR = PK3_Source_GZDoom/acs
ZANDROACSDIR = PK3_Source_Zandronum/acs

all: $(OBJDIR) $(OBJDIR)/Common $(OBJDIR)/ZDoom $(OBJDIR)/Zandronum $(OBJDIR)/libGDCC $(OBJDIR)/libC $(ZDACSDIR) $(ZANDROACSDIR) $(ZDACSDIR)/Se7evidas.bin

clean:
	rm -rf $(OBJDIR) $(ZDACSDIR) $(ZANDROACSDIR)

$(OBJDIR):
	@mkdir "$(OBJDIR)"

$(OBJDIR)/Common:
	@mkdir "$(OBJDIR)/Common"

$(OBJDIR)/ZDoom:
	@mkdir "$(OBJDIR)/ZDoom"

$(OBJDIR)/Zandronum:
	@mkdir "$(OBJDIR)/Zandronum"

$(OBJDIR)/libGDCC:
	@mkdir "$(OBJDIR)/libGDCC"

$(OBJDIR)/libC:
	@mkdir "$(OBJDIR)/libC"

$(ZDACSDIR):
	@mkdir "$(ZDACSDIR)"

$(ZANDROACSDIR):
	@mkdir "$(ZANDROACSDIR)"

Common_INC = -i$(INCDIR)/Common
Common_O = \
   $(OBJDIR)/Common/commonFuncs.o \
   $(OBJDIR)/Common/hud.o \
   $(OBJDIR)/Common/health.o \
   $(OBJDIR)/Common/misc.o \
   $(OBJDIR)/Common/sprint_system.o \
   $(OBJDIR)/Common/stamina.o \
   $(OBJDIR)/Common/util_math.o \
   $(OBJDIR)/Common/weapon_stuff.o

ZDoom_INC = -i$(INCDIR)/ZDoom $(Common_INC)
ZDoom_O = \
   $(OBJDIR)/ZDoom/main.o

$(Common_O) : $(OBJDIR)/Common/%.o : $(SRCDIR)/Common/%.c
	$(CC) --bc-target=ZDoom $(Common_INC) $< $@

$(ZDoom_O) : $(OBJDIR)/ZDoom/%.o : $(SRCDIR)/ZDoom/%.c
	$(CC) --bc-target=ZDoom $(ZDoom_INC) $< $@

$(OBJDIR)/Common.ir: $(Common_O)
	$(LD) -co$@ $^

$(OBJDIR)/ZDoom.ir: $(ZDoom_O)
	$(LD) -co$@ $^

# $(OBJDIR)/Zandro $(OBJDIR)/libGDCC $(OBJDIR)/libC $(INCDIR)/ZDoom/%.h

$(ZDACSDIR)/Se7evidas.bin: $(OBJDIR)/libGDCC.ir $(OBJDIR)/libC.ir $(OBJDIR)/Common.ir $(OBJDIR)/ZDoom.ir
	$(LD) --bc-target=ZDoom -o$@ $^

#$(OBJDIR) $(ZDACSDIR) $(ZANDROACSDIR)
##
## libGDCC
##

libGDCC_IR_AS = \
   $(OBJDIR)/libGDCC/libGDCC_AddF.ir \
   $(OBJDIR)/libGDCC/libGDCC_CmpF.ir \
   $(OBJDIR)/libGDCC/libGDCC_CmpI.ir \
   $(OBJDIR)/libGDCC/libGDCC_CmpU.ir \
   $(OBJDIR)/libGDCC/libGDCC_DivF.ir \
   $(OBJDIR)/libGDCC/libGDCC_DivI.ir \
   $(OBJDIR)/libGDCC/libGDCC_DivU.ir \
   $(OBJDIR)/libGDCC/libGDCC_MulF.ir \
   $(OBJDIR)/libGDCC/libGDCC_MulU.ir \
   $(OBJDIR)/libGDCC/libGDCC_Sh.ir \
   $(OBJDIR)/libGDCC/libGDCC_SubF.ir

libGDCC_IR_CC = \
   $(OBJDIR)/libGDCC/libGDCC_alloc.ir \
   $(OBJDIR)/libGDCC/libGDCC_format.ir

libGDCC_IR = $(libGDCC_IR_AS) $(libGDCC_IR_CC)

$(OBJDIR)/libGDCC.ir: $(libGDCC_IR)
	$(LD) -co$@ $^

$(libGDCC_IR_AS) : $(OBJDIR)/libGDCC/libGDCC_%.ir :
	$(AS) --bc-target=ZDoom -o$@ --sys-source libGDCC/ZDACS/$*.asm

$(libGDCC_IR_CC) : $(OBJDIR)/libGDCC/libGDCC_%.ir :
	$(CC) --bc-target=ZDoom -o$@ --sys-source libGDCC/$*.c

##
## libc
##

libc_IR_AS = \
   $(OBJDIR)/libC/libc_approx.ir \
   $(OBJDIR)/libC/libc_fpclassify.ir

libc_IR_CC = \
   $(OBJDIR)/libC/libc_ctype.ir \
   $(OBJDIR)/libC/libc_errno.ir \
   $(OBJDIR)/libC/libc_exp.ir \
   $(OBJDIR)/libC/libc_locale.ir \
   $(OBJDIR)/libC/libc_math.ir \
   $(OBJDIR)/libC/libc_printf.ir \
   $(OBJDIR)/libC/libc_round.ir \
   $(OBJDIR)/libC/libc_sort.ir \
   $(OBJDIR)/libC/libc_stdfix.ir \
   $(OBJDIR)/libC/libc_stdio.ir \
   $(OBJDIR)/libC/libc_stdlib.ir \
   $(OBJDIR)/libC/libc_string.ir \
   $(OBJDIR)/libC/libc_trig.ir

libc_IR = $(libc_IR_AS) $(libc_IR_CC)

$(OBJDIR)/libc.ir: $(libc_IR)
	$(LD) --bc-target=ZDoom -co$@ $^

$(libc_IR_AS) : $(OBJDIR)/libC/libc_%.ir :
	$(AS) --bc-target=ZDoom -o$@ --sys-source libc/ZDACS/$*.asm

$(libc_IR_CC) : $(OBJDIR)/libC/libc_%.ir :
	$(CC) --bc-target=ZDoom -o$@ --sys-source libc/$*.c