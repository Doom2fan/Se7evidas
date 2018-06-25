## Change this as needed
## Executables and flags ##
CC = gdcc-cc
LD = gdcc-ld
ML = gdcc-makelib
ShopData_Compiler = ./Tools/shopdatacompiler
COM_FLAGS = --bc-target=ZDoom
CC_FLAGS = $(COM_FLAGS) -DDEBUG
LD_LIB_FLAGS = $(COM_FLAGS) -lS7Stuff
## Directories ##
SOURCEDIRECTORY = C_Source
INCDIR = $(SOURCEDIRECTORY)/inc
SRCDIR = $(SOURCEDIRECTORY)/src
OBJDIR = $(SOURCEDIRECTORY)/obj
LIBDIR = $(OBJDIR)/lib
#SHELL = C:/Windows/System32/cmd.exe
## Commands ##
rwildcardInt = $(wildcard $(1)) $(foreach d, $(wildcard $(1)*), $(call rwildcardInt, $(d)/))
rwildcard = $(filter $(2), $(call rwildcardInt, $(1)/))

.PHONY: all
all: ShopData

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
	@mkdir -p "$(@D)"
	"$(ShopData_Compiler)" --file $< --out "$(ShopData_OUTDIR)"
	@touch $@

.PHONY: ShopData
ShopData: $(ShopData_OBJ)