# HEIF
Mac OS X 12+: Convert any image to HEIF/HEIC format.

```
OVERVIEW: Converts image to HEIC format, version 0.8

USAGE: heif-parser [--quality <quality>] [--heif10] [--trash-source] <source-files> ...

ARGUMENTS:
  <source-files>          Source files

OPTIONS:
  -q, --quality <quality> Output image quality it ranges from 0.1 (max compression) to 1.0 (lossless) (default: 0.76)
  --heif10                Use 10 bit color depth in destination
  --trash-source          Trash source file
  -h, --help              Show help information.
```

Compiling on macOS (to create executable `HEIF` and copying to `bin` folder):

```
cd HEIF
swift build -c release --arch arm64 --arch x86_64
cp .build/apple/Products/Release/HEIF /usr/local/bin
```

Please note: odd image dimensions will be truncated by Apple's codec to even ones. 
