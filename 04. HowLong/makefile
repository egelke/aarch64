APP_NAME = HowLong
OBJECTS =  $(OBJ_DIR)main.obj

DEPLOY_TARGET = \\$(REMOTE_AARCH64_COMPUTER)\Data

TARGET = aarch64-pc-windows-msvc
MACHINE = ARM64
ASM_DEBUG = 
ASM_FLAGS = 

LINK_LIB = "kernel32.lib" "User32.lib" "Shell32.lib" "egelke.lib" "Shlwapi.lib"
LINK_DEBUG = /DEBUG
LINK_ENTRY = "_start"

OBJ_DIR = obj\ 
BIN_DIR = bin\ 


default: $(BIN_DIR)$(APP_NAME).exe

deploy: $(BIN_DIR)$(APP_NAME).exe
	xcopy /Y $** $(DEPLOY_TARGET)

unwindinfo: $(BIN_DIR)$(APP_NAME).exe
	dumpbin /UNWINDINFO $**

.asm{$(OBJ_DIR)}.obj:
	clang -I "..\incl" $(ASM_DEBUG) $(ASM_FLAGS) -c -target $(TARGET) -o $*.obj $< 

$(BIN_DIR)$(APP_NAME).exe: $(OBJECTS)
	link /OUT:$*.exe $(LINK_LIB) $(LINK_DEBUG) /LIBPATH:..\lib\bin /MACHINE:$(MACHINE) /SUBSYSTEM:CONSOLE /NOLOGO /NODEFAULTLIB /ENTRY:$(LINK_ENTRY) $**
	
clean:
	del /Q $(OBJ_DIR)*
	del /Q $(BIN_DIR)*

