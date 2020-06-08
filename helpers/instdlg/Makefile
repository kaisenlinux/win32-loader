# Licensed under the zlib/libpng license (same as NSIS)

AS = i686-w64-mingw32-as
LD = i686-w64-mingw32-ld
ASFLAGS = -march=i486
LDFLAGS = --image-base 0x400000 --strip-all --subsystem windows

TARGET = instdlg.exe
instdlg_OBJS = instdlg.o

.PHONY: clean

all:: $(TARGET)

clean::
	rm -f $(TARGET) $(instdlg_OBJS)

$(TARGET): $(instdlg_OBJS)
	$(LD) $(LDFLAGS) $^ -o $@
