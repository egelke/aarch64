APP_NAME = egelke
OBJECTS =  $(OBJ_DIR)start.obj $(OBJ_DIR)print.obj

TARGET = aarch64-pc-windows-msvc
MACHINE = ARM64
ASM_DEBUG = 
ASM_FLAGS = 

OBJ_DIR = obj\ 
BIN_DIR = bin\ 


default: $(BIN_DIR)$(APP_NAME).lib

.asm{$(OBJ_DIR)}.obj:
	clang -I "..\incl" $(ASM_DEBUG) $(ASM_FLAGS) -c -target $(TARGET) -o $*.obj $< 

$(BIN_DIR)$(APP_NAME).lib: $(OBJECTS)
	lib /OUT:$*.lib /MACHINE:$(MACHINE) /NOLOGO /NODEFAULTLIB $**
	
clean:
	del /Q $(OBJ_DIR)*
	del /Q $(BIN_DIR)*

