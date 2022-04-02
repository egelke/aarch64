APP_NAME = HelloWorld
DEPLOY_TARGET = \\$(REMOTE_AARCH64_COMPUTER)\Data

TARGET = aarch64-pc-windows-msvc
MACHINE = ARM64
ASM_DEBUG = -g
ASM_FLAGS = 

LINK_LIB = "kernel32.lib"
LINK_DEBUG = /DEBUG
LINK_ENTRY = "_start"

OBJ_DIR = obj\ 
BIN_DIR = bin\ 


default: $(BIN_DIR)$(APP_NAME).exe

deploy: $(BIN_DIR)$(APP_NAME).exe
	xcopy /Y $** $(DEPLOY_TARGET)

.asm{$(OBJ_DIR)}.obj:
	clang $(ASM_DEBUG) $(ASM_FLAGS) -c -target $(TARGET) -o $*.obj $< 

$(BIN_DIR)$(APP_NAME).exe: $(OBJ_DIR)main.obj
	link /OUT:$*.exe $(LINK_LIB) $(LINK_DEBUG) /MACHINE:$(MACHINE) /SUBSYSTEM:CONSOLE /NOLOGO /NODEFAULTLIB /ENTRY:$(LINK_ENTRY) $**
	
clean:
	del /Q $(OBJ_DIR)*
	del /Q $(BIN_DIR)*

