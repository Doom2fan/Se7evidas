## Change this as needed
## Executables and flags ##
CC = gdcc-cc
LD = gdcc-ld
ML = gdcc-makelib
ShopData_Compiler = Tools/shopDataCompiler
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
SHELL = C:/Windows/System32/cmd.exe
## Commands ##
rwildcardInt = $(wildcard $(1)) $(foreach d, $(wildcard $(1)*), $(call rwildcardInt, $(d)/))
rwildcard = $(filter $(2), $(call rwildcardInt, $(1)/))

.PHONY: all
all: ShopData $(OBJDIR)/S7Stuff.bin

.PHONY: cleanall
cleanall:
	-rm -rf "$(OBJDIR)"

## ===========================================
##
## Shop Data
##
## ===========================================
ShopData_SRCDIR = ShopDataSources
ShopData_OBJDIR = $(ShopData_SRCDIR)/fuck._ignore_.Make
ShopData_OUTDIR = PK3 Source/S7ZScript/RPG Systems/ShopData/
ShopData_SRC = $(call rwildcard, $(ShopData_SRCDIR), %.json)
ShopData_OBJ = $(ShopData_SRC:$(ShopData_SRCDIR)/%.json=$(ShopData_OBJDIR)/%.fuckMake)

$(ShopData_OBJDIR)/%.fuckMake: $(ShopData_SRCDIR)/%.json
	@$(MKDIRCMD) -p "$(@D)"
	"$(ShopData_Compiler)" --file $< --out "$(ShopData_OUTDIR)"
	@touch $@

.PHONY: ShopData
ShopData: $(ShopData_OBJ)

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

S7Stuff_OBJDIR = $(OBJDIR)/S7Stuff
S7Stuff_SRC = $(call rwildcard, $(SRCDIR), %.c)
S7Stuff_OBJ = $(S7Stuff_SRC:$(SRCDIR)/%.c=$(S7Stuff_OBJDIR)/%.ir)

$(S7Stuff_OBJ): $(S7Stuff_OBJDIR)/%.ir: $(SRCDIR)/%.c
	@$(MKDIRCMD) -p "$(@D)"
	$(CC) $(CC_FLAGS) -i$(INCDIR) -i$(SRCDIR) -c $< -o $@

$(OBJDIR)/S7Stuff.ir: $(S7Stuff_OBJ)
	@$(MKDIRCMD) -p "$(@D)"
	$(LD) $(COM_FLAGS) $^ -co $@

$(OBJDIR)/S7Stuff.bin: $(LIBDIR)/libc.ir $(LIBDIR)/libGDCC.ir $(OBJDIR)/S7Stuff.ir
	@$(MKDIRCMD) -p "$(@D)"
	$(LD) $(LD_LIB_FLAGS) $^ -o $@
	@$(MKDIRCMD) -p "PK3 Source/acs"
	-cp --reply=yes "$@" "PK3 Source/acs/S7Stuff.bin"