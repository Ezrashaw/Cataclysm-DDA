# vim: set expandtab tabstop=4 softtabstop=2 shiftwidth=2:
# Platforms:
# Linux/Cygwin native
#   (don't need to do anything)
# Linux 64-bit
#   make NATIVE=linux64
# Linux 32-bit
#   make NATIVE=linux32
# Linux cross-compile to Win32
#   make CROSS=i686-pc-mingw32-
#   or make CROSS=i586-mingw32msvc-
#   or whichever prefix your crosscompiler uses
#      as long as its name contains mingw32
# Linux cross-compile to OSX with osxcross
#   make CROSS=x86_64-apple-darwin15-
#        NATIVE=osx
#        CLANG=1
#        OSXCROSS=1
#        LIBSDIR=../libs
#        FRAMEWORKSDIR=../Frameworks
# Win32 (non-Cygwin)
#   Run: make NATIVE=win32
# OS X
#   Run: make NATIVE=osx OSX_MIN=10.12
#     It is highly recommended to supply OSX_MIN > 10.11
#     otherwise optimizations are automatically disabled with -O0

# Build types:
# Debug (no optimizations)
#  Default
# ccache (use compilation caches)
#  make CCACHE=1
# Release (turn on optimizations)
#  make RELEASE=1
# Tiles (uses SDL rather than ncurses)
#  make TILES=1
# Sound (requires SDL, so TILES must be enabled)
#  make TILES=1 SOUND=1
# Disable gettext, on some platforms the dependencies are hard to wrangle.
#  make LOCALIZE=0
# Disable backtrace support, not available on all platforms
#  make BACKTRACE=0
# Use libbacktrace. Only has effect if BACKTRACE=1. (currently only for MinGW builds)
#  make LIBBACKTRACE=1
# Compile localization files for specified languages
#  make localization LANGUAGES="<lang_id_1>[ lang_id_2][ ...]"
#  (for example: make LANGUAGES="zh_CN zh_TW" for Chinese)
#  make localization LANGUAGES=all
#  (for every .po file in lang/po)
#  Special note for MinGW: due to a libintl bug (https://savannah.gnu.org/bugs/index.php?58006),
#  using English without a `.mo` file would cause significant slow down on MinGW
#  targets. In such case you can compile a `.mo` file for English using `make LANGUAGES="en"`.
#  `make LANGUAGE="all"` also compiles a `.mo` file for English in addition to other languages.
# Enable sanitizer (address, undefined, etc.)
#  make SANITIZE=address
# Change mapsize (reality bubble size)
#  make MAPSIZE=<size>
# Enable the string id debugging helper
#  make STRING_ID_DEBUG=1
# Adjust names of build artifacts (for example to allow easily toggling between build types).
#  make BUILD_PREFIX="release-"
# Generate a build artifact prefix from the other build flags.
#  make AUTO_BUILD_PREFIX=1
# Install to system directories.
#  make install
# Install to $DIR ($DIR will contain bin and share directories).
#  make PREFIX=$DIR
#  make PREFIX=$DIR install
# Use user's XDG base directories for save files and configs.
#  make USE_XDG_DIR=1
# Use user's home directory for save files.
#  make USE_HOME_DIR=1
# Use dynamic linking (requires system libraries).
#  make DYNAMIC_LINKING=1
# Use MSYS2 as the build environment on Windows
#  make MSYS2=1
# Turn off all optimizations, even debug-friendly optimizations
#  make NOOPT=1
# Astyle all source files.
#  make astyle
# Check if source files are styled properly.
#  make astyle-check
# Style the whitelisted json files (maintain the current level of styling).
#  make style-json
# Style all json files using the current rules (don't PR this, it's too many changes at once).
#  make style-all-json
# Disable astyle of source files.
# make ASTYLE=0
# Disable format check of whitelisted json files.
# make LINTJSON=0
# Disable building and running tests.
# make RUNTESTS=0

# comment these to toggle them as one sees fit.
# DEBUG is best turned on if you plan to debug in gdb -- please do!
# PROFILE is for use with gprof or a similar program -- don't bother generally.
# RELEASE_FLAGS is flags for release builds.
RELEASE_FLAGS =
WARNINGS = \
  -Werror -Wall -Wextra \
  -Wformat-signedness \
  -Wlogical-op \
  -Wmissing-declarations \
  -Wmissing-noreturn \
  -Wnon-virtual-dtor \
  -Wold-style-cast \
  -Woverloaded-virtual \
  -Wpedantic \
  -Wsuggest-override \
  -Wunused-macros \
  -Wzero-as-null-pointer-constant \
  -Wno-unknown-warning-option
# Uncomment below to disable warnings
#WARNINGS = -w
DEBUGSYMS = -g
#PROFILE = -pg
#OTHERS = -O3
#DEFINES = -DNDEBUG

# Tells ccache to keep comments, as they can be meaningful to the compiler (as to suppress warnings).
export CCACHE_COMMENTS=1

# Disable debug. Comment this out to get logging.
#DEFINES = -DENABLE_LOGGING

# Limit debug to level. Comment out all for all levels.
#DEFINES += -DDEBUG_INFO
#DEFINES += -DDEBUG_WARNING
#DEFINES += -DDEBUG_ERROR
#DEFINES += -DDEBUG_PEDANTIC_INFO

# Limit debug to section. Comment out all for all levels.
#DEFINES += -DDEBUG_ENABLE_MAIN
#DEFINES += -DDEBUG_ENABLE_MAP
#DEFINES += -DDEBUG_ENABLE_MAP_GEN
#DEFINES += -DDEBUG_ENABLE_GAME

# Explicitly let 'char' to be 'signed char' to fix #18776
OTHERS += -fsigned-char

VERSION = 0.E

TARGET_NAME = cataclysm
TILES_TARGET_NAME = $(TARGET_NAME)-tiles

TARGET = $(BUILD_PREFIX)$(TARGET_NAME)
TILESTARGET = $(BUILD_PREFIX)$(TILES_TARGET_NAME)
ifeq ($(TILES), 1)
  APPTARGET = $(TILESTARGET)
else
  APPTARGET = $(TARGET)
endif
W32TILESTARGET = $(BUILD_PREFIX)$(TILES_TARGET_NAME).exe
W32TARGET = $(BUILD_PREFIX)$(TARGET_NAME).exe
CHKJSON_BIN = $(BUILD_PREFIX)chkjson
BINDIST_DIR = $(BUILD_PREFIX)bindist
BUILD_DIR = $(CURDIR)
SRC_DIR = src
LOCALIZE = 1
ASTYLE_BINARY = astyle

# Enable debug by default
ifndef RELEASE
  RELEASE = 0
endif

# Enable astyle by default
ifndef ASTYLE
  ASTYLE = 1
endif

# Enable json format check by default
ifndef LINTJSON
  LINTJSON = 1
endif

# Enable running tests by default
ifndef RUNTESTS
  RUNTESTS = 1
endif

ifndef PCH
  PCH = 1
endif

# Auto-detect MSYS2
ifdef MSYSTEM
  MSYS2 = 1
endif

ifneq (,$(findstring clang,$(COMPILER)))
  CLANG = $(COMPILER)
endif

# Default to disabling clang
ifndef CLANG
  CLANG = 0
endif

# Determine JSON formatter binary name
JSON_FORMATTER_BIN=tools/format/json_formatter.cgi
ifeq ($(MSYS2), 1)
  JSON_FORMATTER_BIN=tools/format/json_formatter.exe
endif
ifneq (,$(findstring mingw32,$(CROSS)))
  JSON_FORMATTER_BIN=tools/format/json_formatter.exe
endif

# Enable backtrace by default
ifndef BACKTRACE
  # ...except not on native Windows builds, because the relevant headers are
  # probably not available
  ifneq ($(MSYS2), 1)
    BACKTRACE = 1
  endif
endif
ifeq ($(BACKTRACE), 1)
  # Also enable libbacktrace on cross-compilation to Windows
  ifndef LIBBACKTRACE
    ifneq (,$(findstring mingw32,$(CROSS)))
      LIBBACKTRACE = 1
    endif
  endif
endif

ifeq ($(RUNTESTS), 1)
  TESTS = tests
endif

# tiles object directories are because gcc gets confused
# Appears that the default value of $LD is unsuitable on most systems

# when preprocessor defines change, but the source doesn't
ODIR = $(BUILD_PREFIX)obj
ODIRTILES = $(BUILD_PREFIX)obj/tiles
W32ODIR = $(BUILD_PREFIX)objwin
W32ODIRTILES = $(W32ODIR)/tiles

ifdef AUTO_BUILD_PREFIX
  BUILD_PREFIX = $(if $(RELEASE),release-)$(if $(DEBUG_SYMBOLS),symbol-)$(if $(TILES),tiles-)$(if $(SOUND),sound-)$(if $(LOCALIZE),local-)$(if $(BACKTRACE),back-$(if $(LIBBACKTRACE),libbacktrace-))$(if $(SANITIZE),sanitize-)$(if $(MAPSIZE),map-$(MAPSIZE)-)$(if $(USE_XDG_DIR),xdg-)$(if $(USE_HOME_DIR),home-)$(if $(DYNAMIC_LINKING),dynamic-)$(if $(MSYS2),msys2-)
  export BUILD_PREFIX
endif

OS  = $(shell uname -s)

# if $(OS) contains 'BSD'
ifneq ($(findstring BSD,$(OS)),)
  BSD = 1
endif

ifeq ($(PCH), 1)
	CCACHEBIN = CCACHE_SLOPPINESS=pch_defines,time_macros ccache
else
	CCACHEBIN = ccache
endif

ifeq ($(STRING_ID_DEBUG), 1)
	DEFINES += -DCATA_STRING_ID_DEBUGGING
endif

# This sets CXX and so must be up here
ifneq ($(CLANG), 0)
  # Allow setting specific CLANG version
  ifeq ($(CLANG), 1)
    CLANGCMD = clang++
  else
    CLANGCMD = $(CLANG)
  endif
  ifeq ($(NATIVE), osx)
    USE_LIBCXX = 1
  endif
  ifdef USE_LIBCXX
    OTHERS += -stdlib=libc++
    LDFLAGS += -stdlib=libc++
  else
    # clang with glibc 2.31+ will cause linking error on math functions
    # this is a workaround (see https://github.com/google/filament/issues/2146)
    CXXFLAGS += -fno-builtin
  endif
  ifeq ($(CCACHE), 1)
    CXX = CCACHE_CPP2=1 $(CCACHEBIN) $(CROSS)$(CLANGCMD)
    LD  = CCACHE_CPP2=1 $(CCACHEBIN) $(CROSS)$(CLANGCMD)
  else
    CXX = $(CROSS)$(CLANGCMD)
    LD  = $(CROSS)$(CLANGCMD)
  endif
else
  # Compiler version & target machine - used later for MXE ICE workaround
  ifdef CROSS
    CXXVERSION := $(shell $(CROSS)$(CXX) --version | grep -i gcc | sed 's/^.* //g')
    CXXMACHINE := $(shell $(CROSS)$(CXX) -dumpmachine)
  endif

  # Expand at reference time to avoid recursive reference
  ifneq ($(COMPILER),)
    OS_COMPILER := $(COMPILER)
    OS_LINKER := $(COMPILER)
  else
    OS_COMPILER := $(CXX)
    OS_LINKER := $(CXX)
  endif
  # Appears that the default value of $LD is unsuitable on most systems
  ifeq ($(CCACHE), 1)
    CXX = $(CCACHEBIN) $(CROSS)$(OS_COMPILER)
    LD  = $(CCACHEBIN) $(CROSS)$(OS_LINKER)
  else
    CXX = $(CROSS)$(OS_COMPILER)
    LD  = $(CROSS)$(OS_LINKER)
  endif
endif

STRIP = $(CROSS)strip
RC  = $(CROSS)windres
AR  = $(CROSS)ar

# We don't need scientific precision for our math functions, this lets them run much faster.
CXXFLAGS += -ffast-math
LDFLAGS += $(PROFILE)

ifneq ($(SANITIZE),)
  SANITIZE_FLAGS := -fsanitize=$(SANITIZE) -fno-sanitize-recover=all -fno-omit-frame-pointer
  CXXFLAGS += $(SANITIZE_FLAGS)
  LDFLAGS += $(SANITIZE_FLAGS)
endif

# enable optimizations. slow to build
ifeq ($(RELEASE), 1)
  ifeq ($(NATIVE), osx)
    ifeq ($(shell $(CXX) -E -Os - < /dev/null > /dev/null 2>&1 && echo fos),fos)
      OPTLEVEL = -Os
    else
      OPTLEVEL = -O3
    endif
  else
    # MXE ICE Workaround
    # known bad on 4.9.3 and 4.9.4, if it gets fixed this could include a version test too
    ifeq ($(CXXMACHINE), x86_64-w64-mingw32.static)
      OPTLEVEL = -O3
    else
      OPTLEVEL = -Os
    endif
  endif

  ifeq ($(LTO), 1)
    ifneq ($(CLANG), 0)
      # LLVM's LTO will complain if the optimization level isn't between O0 and
      # O3 (inclusive)
      OPTLEVEL = -O3
    endif
  endif
  CXXFLAGS += $(OPTLEVEL)

  ifeq ($(LTO), 1)
    ifeq ($(NATIVE), osx)
      ifneq ($(CLANG), 0)
        LTOFLAGS += -flto=full
      endif
    else
      LDFLAGS += -fuse-ld=gold # This breaks in OS X because gold can only produce ELF binaries, not Mach
    endif

    ifneq ($(CLANG), 0)
      LTOFLAGS += -flto
    else
      LTOFLAGS += -flto=jobserver -flto-odr-type-merging
    endif
  endif
  LTOFLAGS += -Wodr
  CXXFLAGS += $(LTOFLAGS)

  # OTHERS += -mmmx -m3dnow -msse -msse2 -msse3 -mfpmath=sse -mtune=native
  # OTHERS += -march=native # Uncomment this to build an optimized binary for your machine only

  # Strip symbols, generates smaller executable.
  OTHERS += $(RELEASE_FLAGS)
  DEBUG =
  ifndef DEBUG_SYMBOLS
    DEBUGSYMS =
  endif
  DEFINES += -DRELEASE
  # Check for astyle or JSON regressions on release builds.
  ifeq ($(ASTYLE), 1)
    CHECKS += astyle-check
  endif
  ifeq ($(LINTJSON), 1)
    CHECKS += style-json
  endif
else
  ifeq ($(NOOPT), 1)
    # While gcc claims to include all information required for
    # debugging at -Og, at least with gcc 8.3, control flow
    # doesn't move line-by-line at -Og.  Provide a command-line
    # way to turn off optimization (make NOOPT=1) entirely.
    OPTLEVEL = -O0
  else
    ifeq ($(shell $(CXX) -E -Og - < /dev/null > /dev/null 2>&1 && echo fog),fog)
      OPTLEVEL = -Og
    else
      OPTLEVEL = -O0
    endif
  endif
  CXXFLAGS += $(OPTLEVEL)
endif

ifeq ($(shell sh -c 'uname -o 2>/dev/null || echo not'),Cygwin)
  OTHERS += -std=gnu++14
else
  OTHERS += -std=c++14
endif

ifeq ($(CYGWIN),1)
WARNINGS += -Wimplicit-fallthrough=0
endif

ifeq ($(PCH), 1)
  PCHFLAGS = -Ipch -Winvalid-pch
  PCH_H = pch/main-pch.hpp

  ifeq ($(CLANG), 0)
    PCHFLAGS += -fpch-preprocess -include main-pch.hpp
    PCH_P = $(PCH_H).gch
  else
    PCH_P = $(PCH_H).pch
    PCHFLAGS += -include-pch $(PCH_P)

    # FIXME: dirty hack ahead
    # ccache won't wort with clang unless it supports -fno-pch-timestamp
    ifeq ($(CCACHE), 1)
      CLANGVER := $(shell echo 'int main(void){return 0;}'|$(CXX) -Xclang -fno-pch-timestamp -x c++ -o _clang_ver.o -c - 2>&1 || echo fail)
      ifneq ($(CLANGVER),)
        PCHFLAGS = ""
        PCH_H = ""
        PCH_P = ""
        PCH = 0
        $(warning your clang version does not support -fno-pch-timestamp: $(CLANGVER) ($(.SHELLSTATUS)))
      else
        CXXFLAGS += -Xclang -fno-pch-timestamp
      endif
    endif

  endif
endif

CXXFLAGS += $(WARNINGS) $(DEBUG) $(DEBUGSYMS) $(PROFILE) $(OTHERS) -MMD -MP
TOOL_CXXFLAGS = -DCATA_IN_TOOL

BINDIST_EXTRAS += README.md data doc LICENSE.txt LICENSE-OFL-Terminus-Font.txt VERSION.txt $(JSON_FORMATTER_BIN)
BINDIST    = $(BUILD_PREFIX)cataclysmdda-$(VERSION).tar.gz
W32BINDIST = $(BUILD_PREFIX)cataclysmdda-$(VERSION).zip
BINDIST_CMD    = tar --transform=s@^$(BINDIST_DIR)@cataclysmdda-$(VERSION)@ -czvf $(BINDIST) $(BINDIST_DIR)
W32BINDIST_CMD = cd $(BINDIST_DIR) && zip -r ../$(W32BINDIST) * && cd $(BUILD_DIR)


# Check if called without a special build target
ifeq ($(NATIVE),)
  ifeq ($(CROSS),)
    ifeq ($(shell sh -c 'uname -o 2>/dev/null || echo not'),Cygwin)
      DEFINES += -DCATA_NO_CPP11_STRING_CONVERSIONS
      TARGETSYSTEM=CYGWIN
    else
      TARGETSYSTEM=LINUX
    endif
  endif
endif

# Linux 64-bit
ifeq ($(NATIVE), linux64)
  CXXFLAGS += -m64
  LDFLAGS += -m64
  TARGETSYSTEM=LINUX
  ifdef GOLD
    CXXFLAGS += -fuse-ld=gold
    LDFLAGS += -fuse-ld=gold -Wl,--detect-odr-violations
  endif
else
  # Linux 32-bit
  ifeq ($(NATIVE), linux32)
    CXXFLAGS += -m32
    LDFLAGS += -m32
    TARGETSYSTEM=LINUX
    ifdef GOLD
      CXXFLAGS += -fuse-ld=gold
      LDFLAGS += -fuse-ld=gold -Wl,--detect-odr-violations
    endif
  endif
endif

# OSX
ifeq ($(NATIVE), osx)
  ifeq ($(OSX_MIN),)
    ifneq ($(CLANG), 0)
      OSX_MIN = 10.7
    else
      OSX_MIN = 10.5
    endif
  endif
  DEFINES += -DMACOSX
  CXXFLAGS += -mmacosx-version-min=$(OSX_MIN)
  LDFLAGS += -mmacosx-version-min=$(OSX_MIN) -framework CoreFoundation
  ifdef FRAMEWORK
    ifeq ($(FRAMEWORKSDIR),)
      FRAMEWORKSDIR := $(strip $(if $(shell [ -d $(HOME)/Library/Frameworks ] && echo 1), \
                             $(if $(shell find $(HOME)/Library/Frameworks -name 'SDL2.*'), \
                               $(HOME)/Library/Frameworks,),))
    endif
    ifeq ($(FRAMEWORKSDIR),)
      FRAMEWORKSDIR := $(strip $(if $(shell find /Library/Frameworks -name 'SDL2.*'), \
                                 /Library/Frameworks,))
    endif
    ifeq ($(FRAMEWORKSDIR),)
      $(error "SDL2 framework not found")
    endif
  endif
  ifeq ($(LOCALIZE), 1)
    LDFLAGS += -lintl
    ifdef OSXCROSS
      LDFLAGS += -L$(LIBSDIR)/gettext/lib
      CXXFLAGS += -I$(LIBSDIR)/gettext/include
    endif
    # recent versions of brew will not allow you to link
    ifeq ($(BREWGETTEXT), 1)
      # native ARM Homebrew is installed to /opt/homebrew
      ifneq ("$(wildcard /opt/homebrew)", "")
        LDFLAGS += -L/opt/homebrew/lib
        CXXFLAGS += -I/opt/homebrew/include
      else
        LDFLAGS += -L/usr/local/opt/gettext/lib
        CXXFLAGS += -I/usr/local/opt/gettext/include
      endif
    endif
    ifeq ($(MACPORTS), 1)
      ifneq ($(TILES), 1)
        CXXFLAGS += -I$(shell ncursesw6-config --includedir)
        LDFLAGS += -L$(shell ncursesw6-config --libdir)
      endif
    endif
  endif
  TARGETSYSTEM=LINUX
  ifneq ($(OS), Linux)
    BINDIST_CMD = tar -s"@^$(BINDIST_DIR)@cataclysmdda-$(VERSION)@" -czvf $(BINDIST) $(BINDIST_DIR)
  endif
endif

# Win32 (MinGW32 or MinGW-w64(32bit)?)
ifeq ($(NATIVE), win32)
# Any reason not to use -m32 on MinGW32?
  TARGETSYSTEM=WINDOWS
else
  # Win64 (MinGW-w64?)
  ifeq ($(NATIVE), win64)
    CXXFLAGS += -m64
    LDFLAGS += -m64
    TARGETSYSTEM=WINDOWS
  endif
endif

# MSYS2
ifeq ($(MSYS2), 1)
  TARGETSYSTEM=WINDOWS
endif

# Cygwin
ifeq ($(NATIVE), cygwin)
  TARGETSYSTEM=CYGWIN
endif

# MXE cross-compile to win32
ifneq (,$(findstring mingw32,$(CROSS)))
  DEFINES += -DCROSS_LINUX
  TARGETSYSTEM=WINDOWS
endif

ifneq ($(TARGETSYSTEM),WINDOWS)
  WARNINGS += -Wredundant-decls
endif

# Global settings for Windows targets
ifeq ($(TARGETSYSTEM),WINDOWS)
  CHKJSON_BIN = chkjson.exe
  TARGET = $(W32TARGET)
  BINDIST = $(W32BINDIST)
  BINDIST_CMD = $(W32BINDIST_CMD)
  ODIR = $(W32ODIR)
  ifeq ($(DYNAMIC_LINKING), 1)
    # Windows isn't sold with programming support, these are static to remove MinGW dependency.
    LDFLAGS += -static-libgcc -static-libstdc++
  else
    LDFLAGS += -static
  endif
  ifeq ($(LOCALIZE), 1)
    LDFLAGS += -lintl -liconv
  endif
  W32FLAGS += -Wl,-stack,12000000,-subsystem,windows
  RFLAGS = -J rc -O coff
  ifeq ($(NATIVE), win64)
    RFLAGS += -F pe-x86-64
  endif
endif

ifdef MAPSIZE
    CXXFLAGS += -DMAPSIZE=$(MAPSIZE)
endif

ifeq ($(shell git rev-parse --is-inside-work-tree),true)
  # We have a git repository, use git version
  DEFINES += -DGIT_VERSION
endif

PKG_CONFIG = $(CROSS)pkg-config

ifeq ($(SOUND), 1)
  ifneq ($(TILES),1)
    $(error "SOUND=1 only works with TILES=1")
  endif
  ifeq ($(NATIVE),osx)
    ifdef FRAMEWORK
      CXXFLAGS += -I$(FRAMEWORKSDIR)/SDL2_mixer.framework/Headers
      LDFLAGS += -F$(FRAMEWORKSDIR)/SDL2_mixer.framework/Frameworks \
		 -framework SDL2_mixer -framework Vorbis -framework Ogg
    else # libsdl build
      ifeq ($(MACPORTS), 1)
        LDFLAGS += -lSDL2_mixer -lvorbisfile -lvorbis -logg
      else # homebrew
        CXXFLAGS += $(shell $(PKG_CONFIG) --cflags SDL2_mixer)
        LDFLAGS += $(shell $(PKG_CONFIG) --libs SDL2_mixer)
        LDFLAGS += -lvorbisfile -lvorbis -logg
      endif
    endif
  else # not osx
    CXXFLAGS += $(shell $(PKG_CONFIG) --cflags SDL2_mixer)
    LDFLAGS += $(shell $(PKG_CONFIG) --libs SDL2_mixer)
    LDFLAGS += -lpthread
  endif

  ifeq ($(MSYS2),1)
    LDFLAGS += -lmpg123 -lshlwapi -lvorbisfile -lvorbis -logg -lflac
  endif

  CXXFLAGS += -DSDL_SOUND
endif

ifeq ($(SDL), 1)
  TILES = 1
endif

ifeq ($(TILES), 1)
  SDL = 1
  BINDIST_EXTRAS += gfx
  ifeq ($(NATIVE),osx)
    ifdef FRAMEWORK
      OSX_INC = -F$(FRAMEWORKSDIR) \
		-I$(FRAMEWORKSDIR)/SDL2.framework/Headers \
		-I$(FRAMEWORKSDIR)/SDL2_image.framework/Headers \
		-I$(FRAMEWORKSDIR)/SDL2_ttf.framework/Headers
			ifdef SOUND
				OSX_INC += -I$(FRAMEWORKSDIR)/SDL2_mixer.framework/Headers
			endif
      LDFLAGS += -F$(FRAMEWORKSDIR) \
		 -framework SDL2 -framework SDL2_image -framework SDL2_ttf -framework Cocoa
		 ifdef SOUND
		 	LDFLAGS += -framework SDL2_mixer
		 endif
      CXXFLAGS += $(OSX_INC)
    else # libsdl build
      DEFINES += -DOSX_SDL2_LIBS
      # handle #include "SDL2/SDL.h" and "SDL.h"
      CXXFLAGS += $(shell sdl2-config --cflags) \
		  -I$(shell dirname $(shell sdl2-config --cflags | sed 's/-I\(.[^ ]*\) .*/\1/'))
      LDFLAGS += -framework Cocoa $(shell sdl2-config --libs) -lSDL2_ttf
      LDFLAGS += -lSDL2_image
      ifdef SOUND
        LDFLAGS += -lSDL2_mixer
      endif
    endif
  else # not osx
    CXXFLAGS += $(shell $(PKG_CONFIG) --cflags sdl2 SDL2_image SDL2_ttf)

    ifeq ($(STATIC), 1)
      LDFLAGS += $(shell $(PKG_CONFIG) sdl2 --static --libs)
    else
      LDFLAGS += $(shell $(PKG_CONFIG) sdl2 --libs)
    endif

    LDFLAGS += -lSDL2_ttf -lSDL2_image

    # We don't use SDL_main -- we have proper main()/WinMain()
    CXXFLAGS := $(filter-out -Dmain=SDL_main,$(CXXFLAGS))
    LDFLAGS := $(filter-out -lSDL2main,$(LDFLAGS))
  endif

  DEFINES += -DTILES

  ifeq ($(TARGETSYSTEM),WINDOWS)
    ifndef DYNAMIC_LINKING
      # These differ depending on what SDL2 is configured to use.
      ifneq (,$(findstring mingw32,$(CROSS)))
        # We use pkg-config to find out which libs are needed with MXE
        LDFLAGS += $(shell $(PKG_CONFIG) --libs SDL2_image SDL2_ttf)
      else
        ifeq ($(MSYS2),1)
          LDFLAGS += -Wl,--start-group -lharfbuzz -lfreetype -Wl,--end-group -lgraphite2 -lpng -lz -ltiff -lbz2 -lglib-2.0 -llzma -lws2_32 -lintl -liconv -lwebp -ljpeg -luuid
        else
          LDFLAGS += -lfreetype -lpng -lz -ljpeg -lbz2
        endif
      endif
    else
      # Currently none needed by the game itself (only used by SDL2 layer).
      # Placeholder for future use (savegame compression, etc).
      LDFLAGS +=
    endif
    TARGET = $(W32TILESTARGET)
    ODIR = $(W32ODIRTILES)
  else
    TARGET = $(TILESTARGET)
    ODIR = $(ODIRTILES)
  endif
else
  ifeq ($(LOCALIZE),1)
    NCURSES_PREFIX = ncursesw
  else
    NCURSES_PREFIX = ncurses
  endif
  ifdef OSXCROSS
    NCURSES_PREFIX = ncurses
  endif
  # ONLY when not cross-compiling, check for pkg-config or ncurses5-config
  # When doing a cross-compile, we can't rely on the host machine's -configs
  ifeq ($(CROSS),)
      ifeq ($(OSXCROSS),)
        ifneq ($(shell pkg-config --libs $(NCURSES_PREFIX) 2>/dev/null),)
          HAVE_PKGCONFIG = 1
        endif
        ifneq ($(shell which $(NCURSES_PREFIX)5-config 2>/dev/null),)
          HAVE_NCURSES5CONFIG = 1
        endif
      endif
  endif

  # Link to ncurses if we're using a non-tiles, Linux build
  ifeq ($(HAVE_PKGCONFIG),1)
    CXXFLAGS += $(shell $(PKG_CONFIG) --cflags $(NCURSES_PREFIX))
    LDFLAGS += $(shell $(PKG_CONFIG) --libs $(NCURSES_PREFIX))
  else
    ifeq ($(HAVE_NCURSES5CONFIG),1)
      CXXFLAGS += $(shell $(NCURSES_PREFIX)5-config --cflags)
      LDFLAGS += $(shell $(NCURSES_PREFIX)5-config --libs)
    else
      ifneq ($(TARGETSYSTEM),WINDOWS)
        LDFLAGS += -l$(NCURSES_PREFIX)
      endif

      ifdef OSXCROSS
        LDFLAGS += -L$(LIBSDIR)/$(NCURSES_PREFIX)/lib
        CXXFLAGS += -I$(LIBSDIR)/$(NCURSES_PREFIX)/include
      endif # OSXCROSS
    endif # HAVE_NCURSES5CONFIG
  endif # HAVE_PKGCONFIG
endif # TILES

ifeq ($(TARGETSYSTEM),CYGWIN)
  ifeq ($(LOCALIZE),1)
    # Work around Cygwin not including gettext support in glibc
    LDFLAGS += -lintl -liconv
  endif
endif

ifeq ($(BSD), 1)
  # BSDs have backtrace() and friends in a separate library
  ifeq ($(BACKTRACE), 1)
    LDFLAGS += -lexecinfo
    # ...which requires the frame pointer
    CXXFLAGS += -fno-omit-frame-pointer
  endif

  # And similarly, their libcs don't have gettext built in
  ifeq ($(LOCALIZE),1)
    LDFLAGS += -lintl -liconv
  endif
endif

# Global settings for Windows targets (at end)
ifeq ($(TARGETSYSTEM),WINDOWS)
  LDFLAGS += -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lversion
  ifeq ($(BACKTRACE),1)
    LDFLAGS += -ldbghelp
    ifeq ($(LIBBACKTRACE),1)
      LDFLAGS += -lbacktrace
    endif
  endif
endif

ifeq ($(BACKTRACE),1)
  DEFINES += -DBACKTRACE
  ifeq ($(LIBBACKTRACE),1)
      DEFINES += -DLIBBACKTRACE
  endif
endif

ifeq ($(LOCALIZE),1)
  DEFINES += -DLOCALIZE
endif

ifeq ($(TARGETSYSTEM),LINUX)
  BINDIST_EXTRAS += cataclysm-launcher
  ifeq ($(BACKTRACE),1)
    # -rdynamic needed for symbols in backtraces
    LDFLAGS += -rdynamic
  endif
endif

ifeq ($(TARGETSYSTEM),CYGWIN)
  BINDIST_EXTRAS += cataclysm-launcher
  DEFINES += -D_GLIBCXX_USE_C99_MATH_TR1
endif

ifeq ($(MSYS2),1)
  DEFINES += -D_GLIBCXX_USE_C99_MATH_TR1
  CXXFLAGS += -DMSYS2
endif

# Enumerations of all the source files and headers.
SOURCES := $(wildcard $(SRC_DIR)/*.cpp)
HEADERS := $(wildcard $(SRC_DIR)/*.h)
TESTSRC := $(wildcard tests/*.cpp)
TESTHDR := $(wildcard tests/*.h)
JSON_FORMATTER_SOURCES := tools/format/format.cpp tools/format/format_main.cpp src/json.cpp
CHKJSON_SOURCES := src/chkjson/chkjson.cpp src/json.cpp
CLANG_TIDY_PLUGIN_SOURCES := \
  $(wildcard tools/clang-tidy-plugin/*.cpp tools/clang-tidy-plugin/*/*.cpp)
TOOLHDR := $(wildcard tools/*/*.h)
# Using sort here because it has the side-effect of deduplicating the list
ASTYLE_SOURCES := $(sort \
  $(SOURCES) \
  $(HEADERS) \
  $(TESTSRC) \
  $(TESTHDR) \
  $(JSON_FORMATTER_SOURCES) \
  $(CHKJSON_SOURCES) \
  $(CLANG_TIDY_PLUGIN_SOURCES) \
  $(TOOLHDR))

_OBJS = $(SOURCES:$(SRC_DIR)/%.cpp=%.o)
ifeq ($(TARGETSYSTEM),WINDOWS)
  RSRC = $(wildcard $(SRC_DIR)/*.rc)
  _OBJS += $(RSRC:$(SRC_DIR)/%.rc=%.o)
endif
OBJS = $(sort $(patsubst %,$(ODIR)/%,$(_OBJS)))

ifdef LANGUAGES
  L10N = localization
endif

ifeq ($(TARGETSYSTEM), LINUX)
  ifneq ($(PREFIX),)
    DEFINES += -DPREFIX="$(PREFIX)" -DDATA_DIR_PREFIX
  endif
endif

ifeq ($(TARGETSYSTEM), CYGWIN)
  ifneq ($(PREFIX),)
    DEFINES += -DPREFIX="$(PREFIX)" -DDATA_DIR_PREFIX
  endif
endif

ifeq ($(USE_HOME_DIR),1)
  ifeq ($(USE_XDG_DIR),1)
    $(error "USE_HOME_DIR=1 does not work with USE_XDG_DIR=1")
  endif
  DEFINES += -DUSE_HOME_DIR
endif

ifeq ($(USE_XDG_DIR),1)
  ifeq ($(USE_HOME_DIR),1)
    $(error "USE_HOME_DIR=1 does not work with USE_XDG_DIR=1")
  endif
  DEFINES += -DUSE_XDG_DIR
endif

ifeq ($(LTO), 1)
  # Depending on the compiler version, LTO usually requires all the
  # optimization flags to be specified on the link line, and requires them to
  # match the original invocations.
  LDFLAGS += $(CXXFLAGS)

  # If GCC or CLANG, use a wrapper for AR (if it exists) else test fails to build
  ifeq ($(CLANG), 0)
    GCCAR := $(shell command -v gcc-ar 2> /dev/null)
    ifdef GCCAR
      ifneq (,$(findstring gcc version,$(shell $(CXX) -v </dev/null 2>&1)))
        AR = gcc-ar
      endif
    endif
  else
    LLVMAR := $(shell command -v llvm-ar 2> /dev/null)
    ifdef LLVMAR
      ifneq (,$(findstring clang version,$(shell $(CXX) -v </dev/null 2>&1)))
        AR = llvm-ar
      endif
    endif
  endif
endif

all: version $(CHECKS) $(TARGET) $(L10N) $(TESTS)
	@

$(TARGET): $(OBJS)
	+$(LD) $(W32FLAGS) -o $(TARGET) $(OBJS) $(LDFLAGS)
ifeq ($(RELEASE), 1)
  ifndef DEBUG_SYMBOLS
    ifneq ($(BACKTRACE),1)
	$(STRIP) $(TARGET)
    endif
  endif
endif

$(PCH_P): $(PCH_H)
	-$(CXX) $(CPPFLAGS) $(DEFINES) $(subst -Werror,,$(CXXFLAGS)) -c $(PCH_H) -o $(PCH_P)

$(BUILD_PREFIX)$(TARGET_NAME).a: $(OBJS)
	$(AR) rcs $(BUILD_PREFIX)$(TARGET_NAME).a $(filter-out $(ODIR)/main.o $(ODIR)/messages.o,$(OBJS))

.PHONY: version
version:
	@( VERSION_STRING=$(VERSION) ; \
            [ -e ".git" ] && GITVERSION=$$( git describe --tags --always --match "[0-9A-Z]*.[0-9A-Z]*" ) && DIRTYFLAG=$$( [ -z "$$(git diff --numstat | grep -v lang/po/)" ] || echo "-dirty") && VERSION_STRING=$$GITVERSION$$DIRTYFLAG ; \
            [ -e "$(SRC_DIR)/version.h" ] && OLDVERSION=$$(grep VERSION $(SRC_DIR)/version.h|cut -d '"' -f2) ; \
            if [ "x$$VERSION_STRING" != "x$$OLDVERSION" ]; then printf '// NOLINT(cata-header-guard)\n#define VERSION "%s"\n' "$$VERSION_STRING" | tee $(SRC_DIR)/version.h ; fi \
         )

# Unconditionally create the object dir on every invocation.
$(shell mkdir -p $(ODIR))

$(ODIR)/%.o: $(SRC_DIR)/%.cpp $(PCH_P)
	$(CXX) $(CPPFLAGS) $(DEFINES) $(CXXFLAGS) $(PCHFLAGS) -c $< -o $@

$(ODIR)/%.o: $(SRC_DIR)/%.rc
	$(RC) $(RFLAGS) $< -o $@

src/version.h: version

src/version.cpp: src/version.h

localization:
	lang/compile_mo.sh $(LANGUAGES)

$(CHKJSON_BIN): $(CHKJSON_SOURCES)
	$(CXX) $(CXXFLAGS) $(TOOL_CXXFLAGS) -Isrc/chkjson -Isrc $(CHKJSON_SOURCES) -o $(CHKJSON_BIN)

json-check: $(CHKJSON_BIN)
	./$(CHKJSON_BIN)

clean: clean-tests clean-object_creator
	rm -rf *$(TARGET_NAME) *$(TILES_TARGET_NAME)
	rm -rf *$(TILES_TARGET_NAME).exe *$(TARGET_NAME).exe *$(TARGET_NAME).a
	rm -rf *obj *objwin
	rm -rf *$(BINDIST_DIR) *cataclysmdda-*.tar.gz *cataclysmdda-*.zip
	rm -f $(SRC_DIR)/version.h
	rm -f $(CHKJSON_BIN)
	rm -f pch/*pch.hpp.gch
	rm -f pch/*pch.hpp.pch
	rm -f pch/*pch.hpp.d

distclean:
	rm -rf *$(BINDIST_DIR)
	rm -rf save
	rm -rf lang/mo
	rm -f data/options.txt
	rm -f data/keymap.txt
	rm -f data/auto_pickup.txt
	rm -f data/fontlist.txt

bindist: $(BINDIST)

ifeq ($(TARGETSYSTEM), LINUX)
DATA_PREFIX=$(DESTDIR)$(PREFIX)/share/cataclysm-dda/
BIN_PREFIX=$(DESTDIR)$(PREFIX)/bin
LOCALE_DIR=$(DESTDIR)$(PREFIX)/share/locale
install: version $(TARGET)
	mkdir -p $(DATA_PREFIX)
	mkdir -p $(BIN_PREFIX)
	install --mode=755 $(TARGET) $(BIN_PREFIX)
	cp -R --no-preserve=ownership data/core $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/font $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/json $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/mods $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/names $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/raw $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/motd $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/credits $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/title $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/help $(DATA_PREFIX)
ifeq ($(TILES), 1)
	cp -R --no-preserve=ownership gfx $(DATA_PREFIX)
endif
ifeq ($(SOUND), 1)
	cp -R --no-preserve=ownership data/sound $(DATA_PREFIX)
endif
	install --mode=644 data/changelog.txt data/cataicon.ico data/fontdata.json \
                   LICENSE.txt LICENSE-OFL-Terminus-Font.txt -t $(DATA_PREFIX)
	mkdir -p $(LOCALE_DIR)
ifdef LANGUAGES
	LOCALE_DIR=$(LOCALE_DIR) lang/compile_mo.sh $(LANGUAGES)
endif
endif

ifeq ($(TARGETSYSTEM), CYGWIN)
DATA_PREFIX=$(DESTDIR)$(PREFIX)/share/cataclysm-dda/
BIN_PREFIX=$(DESTDIR)$(PREFIX)/bin
LOCALE_DIR=$(DESTDIR)$(PREFIX)/share/locale
install: version $(TARGET)
	mkdir -p $(DATA_PREFIX)
	mkdir -p $(BIN_PREFIX)
	install --mode=755 $(TARGET) $(BIN_PREFIX)
	cp -R --no-preserve=ownership data/core $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/font $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/json $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/mods $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/names $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/raw $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/motd $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/credits $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/title $(DATA_PREFIX)
	cp -R --no-preserve=ownership data/help $(DATA_PREFIX)
ifeq ($(TILES), 1)
	cp -R --no-preserve=ownership gfx $(DATA_PREFIX)
endif
ifeq ($(SOUND), 1)
	cp -R --no-preserve=ownership data/sound $(DATA_PREFIX)
endif
	install --mode=644 data/changelog.txt data/cataicon.ico data/fontdata.json \
                   LICENSE.txt LICENSE-OFL-Terminus-Font.txt -t $(DATA_PREFIX)
	mkdir -p $(LOCALE_DIR)
ifdef LANGUAGES
	LOCALE_DIR=$(LOCALE_DIR) lang/compile_mo.sh $(LANGUAGES)
endif
endif


ifeq ($(NATIVE), osx)
APPTARGETDIR=Cataclysm.app
APPRESOURCESDIR=$(APPTARGETDIR)/Contents/Resources
APPDATADIR=$(APPRESOURCESDIR)/data
ifndef FRAMEWORK
  SDLLIBSDIR=$(shell sdl2-config --libs | sed -n 's/.*-L\([^ ]*\) .*/\1/p')
endif  # ifndef FRAMEWORK

appclean:
	rm -rf $(APPTARGETDIR)
	rm -f data/options.txt
	rm -f data/keymap.txt
	rm -f data/auto_pickup.txt
	rm -f data/fontlist.txt

build-data/osx/AppIcon.icns: build-data/osx/AppIcon.iconset
	iconutil -c icns $<

ifdef OSXCROSS
app: appclean version $(APPTARGET)
else
app: appclean version build-data/osx/AppIcon.icns $(APPTARGET)
endif
	mkdir -p $(APPTARGETDIR)/Contents
	cp build-data/osx/Info.plist $(APPTARGETDIR)/Contents/
	mkdir -p $(APPTARGETDIR)/Contents/MacOS
	cp build-data/osx/Cataclysm.sh $(APPTARGETDIR)/Contents/MacOS/
	mkdir -p $(APPRESOURCESDIR)
	cp $(APPTARGET) $(APPRESOURCESDIR)/
	cp build-data/osx/AppIcon.icns $(APPRESOURCESDIR)/
	mkdir -p $(APPDATADIR)
	cp data/fontdata.json $(APPDATADIR)
	cp -R data/core $(APPDATADIR)
	cp -R data/font $(APPDATADIR)
	cp -R data/json $(APPDATADIR)
	cp -R data/mods $(APPDATADIR)
	cp -R data/names $(APPDATADIR)
	cp -R data/raw $(APPDATADIR)
	cp -R data/motd $(APPDATADIR)
	cp -R data/credits $(APPDATADIR)
	cp -R data/title $(APPDATADIR)
	cp -R data/help $(APPDATADIR)
ifdef LANGUAGES
	lang/compile_mo.sh $(LANGUAGES)
	mkdir -p $(APPRESOURCESDIR)/lang/mo/
	cp -pR lang/mo/* $(APPRESOURCESDIR)/lang/mo/
endif
ifeq ($(LOCALIZE), 1)
	LIBINTL=$$($(CROSS)otool -L $(APPTARGET) | grep libintl | sed -n 's/\(.*\.dylib\).*/\1/p') && if [ -f $$LIBINTL ]; then cp $$LIBINTL $(APPRESOURCESDIR)/; fi; \
		if [ ! -z "$$OSXCROSS" ]; then LIBINTL=$$(basename $$LIBINTL) && if [ ! -z "$$LIBINTL" ]; then cp $(LIBSDIR)/gettext/lib/$$LIBINTL $(APPRESOURCESDIR)/; fi; fi
endif
ifeq ($(TILES), 1)
ifeq ($(SOUND), 1)
	cp -R data/sound $(APPDATADIR)
endif  # ifdef SOUND
	cp -R gfx $(APPRESOURCESDIR)/
ifdef FRAMEWORK
	cp -R $(FRAMEWORKSDIR)/SDL2.framework $(APPRESOURCESDIR)/
	cp -R $(FRAMEWORKSDIR)/SDL2_image.framework $(APPRESOURCESDIR)/
	cp -R $(FRAMEWORKSDIR)/SDL2_ttf.framework $(APPRESOURCESDIR)/
ifeq ($(SOUND), 1)
	cp -R $(FRAMEWORKSDIR)/SDL2_mixer.framework $(APPRESOURCESDIR)/
	cd $(APPRESOURCESDIR)/ && ln -s SDL2_mixer.framework/Frameworks/Vorbis.framework Vorbis.framework
	cd $(APPRESOURCESDIR)/ && ln -s SDL2_mixer.framework/Frameworks/Ogg.framework Ogg.framework
	cd $(APPRESOURCESDIR)/SDL2_mixer.framework/Frameworks && find . -maxdepth 1 -type d -not -name '*Vorbis.framework' -not -name '*Ogg.framework' -not -name '.' | xargs rm -rf
endif  # ifdef SOUND
else # libsdl build
	cp $(SDLLIBSDIR)/libSDL2.dylib $(APPRESOURCESDIR)/
	cp $(SDLLIBSDIR)/libSDL2_image.dylib $(APPRESOURCESDIR)/
	cp $(SDLLIBSDIR)/libSDL2_ttf.dylib $(APPRESOURCESDIR)/
ifeq ($(SOUND), 1)
	cp $(SDLLIBSDIR)/libSDL2_mixer.dylib $(APPRESOURCESDIR)/
endif  # ifdef SOUND
endif  # ifdef FRAMEWORK

endif  # ifdef TILES

dmgdistclean:
	rm -rf Cataclysm
	rm -f Cataclysm.dmg
	rm -rf lang/mo

dmgdist: dmgdistclean $(L10N) app
ifdef OSXCROSS
	mkdir Cataclysm
	cp -a $(APPTARGETDIR) Cataclysm/$(APPTARGETDIR)
	cp build-data/osx/DS_Store Cataclysm/.DS_Store
	cp build-data/osx/dmgback.png Cataclysm/.background.png
	ln -s /Applications Cataclysm/Applications
	genisoimage -quiet -D -V "Cataclysm DDA" -no-pad -r -apple -o Cataclysm-uncompressed.dmg Cataclysm/
	dmg dmg Cataclysm-uncompressed.dmg Cataclysm.dmg
	rm Cataclysm-uncompressed.dmg
else
	dmgbuild -s build-data/osx/dmgsettings.py "Cataclysm DDA" Cataclysm.dmg
endif

endif  # ifeq ($(NATIVE), osx)

$(BINDIST): distclean version $(TARGET) $(L10N) $(BINDIST_EXTRAS) $(BINDIST_LOCALE)
	mkdir -p $(BINDIST_DIR)
	cp -R $(TARGET) $(BINDIST_EXTRAS) $(BINDIST_DIR)
ifdef LANGUAGES
	cp -R --parents lang/mo $(BINDIST_DIR)
endif
	$(BINDIST_CMD)

export ODIR _OBJS LDFLAGS CXX W32FLAGS DEFINES CXXFLAGS TARGETSYSTEM CLANG PCH PCHFLAGS

ctags: $(ASTYLE_SOURCES)
	ctags $^
	./tools/json_tools/cddatags.py

etags: $(ASTYLE_SOURCES)
	etags $^
	./tools/json_tools/cddatags.py

astyle: $(ASTYLE_SOURCES)
	$(ASTYLE_BINARY) --options=.astylerc -n $(ASTYLE_SOURCES)

# Test whether the system has a version of astyle that supports --dry-run
ifeq ($(shell if $(ASTYLE_BINARY) -Q -X --dry-run src/game.h > /dev/null; then echo foo; fi),foo)
  ASTYLE_CHECK=$(shell $(ASTYLE_BINARY) --options=.astylerc --dry-run -X -Q --ascii $(ASTYLE_SOURCES))
endif

astyle-check:
ifdef ASTYLE_CHECK
	$(info $(ASTYLE_BINARY) -V: $(shell $(ASTYLE_BINARY) -V))
	@if [ "$(findstring Formatted,$(ASTYLE_CHECK))" = "" ]; then echo "no astyle regressions";\
        else printf "astyle regressions found.\n$(ASTYLE_CHECK)\n" && false; fi
else
	@echo Cannot run an astyle check, your system either does not have astyle, or it is too old.
endif

style-json: json_blacklist $(JSON_FORMATTER_BIN)
ifndef CROSS
	find data -name "*.json" -print0 | grep -v -z -F -f json_blacklist | \
	  xargs -0 -L 1 $(JSON_FORMATTER_BIN)
else
	@echo Cannot run json formatter in cross compiles.
endif

style-all-json: $(JSON_FORMATTER_BIN)
	find data -name "*.json" -print0 | xargs -0 -L 1 $(JSON_FORMATTER_BIN)

$(JSON_FORMATTER_BIN): $(JSON_FORMATTER_SOURCES)
	$(CXX) $(CXXFLAGS) $(TOOL_CXXFLAGS) -Itools/format -Isrc \
	  $(JSON_FORMATTER_SOURCES) -o $(JSON_FORMATTER_BIN)

python-check:
	flake8

tests: version $(BUILD_PREFIX)cataclysm.a
	$(MAKE) -C tests

check: version $(BUILD_PREFIX)cataclysm.a
	$(MAKE) -C tests check

clean-tests:
	$(MAKE) -C tests clean

object_creator: version $(BUILD_PREFIX)cataclysm.a
	$(MAKE) -C object_creator

clean-object_creator:
	$(MAKE) -C object_creator clean

.PHONY: tests check ctags etags clean-tests install lint

-include $(SOURCES:$(SRC_DIR)/%.cpp=$(DEPDIR)/%.P)
-include ${OBJS:.o=.d}
