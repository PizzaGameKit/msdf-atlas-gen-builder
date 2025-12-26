#!/bin/bash

# Move to script's directory
cd "`dirname "$0"`"

zlibPath="$(cd "./zlib" && pwd -P)"
libpngPath="$(cd "./libpng" && pwd -P)"
freetypePath="$(cd "./freetype" && pwd -P)"
msdfPath="$(cd "./msdf-atlas-gen" && pwd -P)"

outputFolder="./binaries/osx"
rm -r -f $outputFolder
mkdir -p $outputFolder

logFolder="./logs/osx"
rm -r -f $logFolder
mkdir -p $logFolder

buildFolder="build"

zlibBuild="$zlibPath/$buildFolder"
libpngBuild="$libpngPath/$buildFolder"
freetypeBuild="$freetypePath/$buildFolder"
msdfBuild="$msdfPath/$buildFolder"

zlibLib="$zlibBuild/libz.a"
libpngLib="$libpngBuild/libpng18.a"
freetypeLib="$freetypeBuild/libfreetype.a"

# Generate zlib
echo "Generate zlib"

rm -r -f $zlibBuild

cmake -S $zlibPath -B $zlibBuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET="10.15" -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" > "$logFolder/zlib.gen.log"

echo -e "\tDone"

# Build zlib
echo "Build zlib"

cmake --build $zlibBuild --target zlibstatic > "$logFolder/zlib.bin.log"

echo -e "\tDone"

# Generate libpng
echo "Generate libpng"

rm -r -f $libpngBuild

cmake -S $libpngPath -B $libpngBuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET="10.15" -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" -DZLIB_LIBRARY="$zlibLib" -DZLIB_INCLUDE_DIR="$zlibPath" > "$logFolder/linpng.gen.log"

echo -e "\tDone"

# Build libpng
echo "Build libpng"

cmake --build $libpngBuild --target png_static > "$logFolder/libpng.bin.log"

cp -f "$libpngPath/pnglibconf.h.prebuilt" "$libpngPath/pnglibconf.h"

echo -e "\tDone"

# Generate freetype
echo "Generate freetype"

rm -r -f $freetypeBuild

cmake -S ./freetype -B $freetypeBuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET="10.15" -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" -DFT_DISABLE_BZIP2=TRUE -DFT_DISABLE_BROTLI=TRUE -DBUILD_SHARED_LIBS=false -DZLIB_LIBRARY="$zlibLib" -DZLIB_INCLUDE_DIR="$zlibPath" -DPNG_LIBRARY="$libpngLib" -DPNG_PNG_INCLUDE_DIR="$libpngPath" > "$logFolder/freetype.gen.log"

echo -e "\tDone"

# Build freetype
echo "Build freetype"

cmake --build $freetypeBuild > "$logFolder/freetype.bin.log"

echo -e "\tDone"

# Generate msdf-atlas-gen
echo "Generate msdf-atlas-gen"

rm -r -f $msdfBuild

cmake -S $msdfPath -B $msdfBuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET="10.15" -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" -DMSDF_ATLAS_USE_VCPKG=OFF -DMSDF_ATLAS_NO_ARTERY_FONT=OFF -DMSDF_ATLAS_USE_SKIA=OFF -DFREETYPE_LIBRARY="$freetypeLib" -DFREETYPE_INCLUDE_DIRS="$freetypePath/include/freetype;$freetypePath/include" -DZLIB_LIBRARY="$zlibLib" -DZLIB_INCLUDE_DIR="$zlibPath" -DPNG_LIBRARY="$libpngLib" -DPNG_PNG_INCLUDE_DIR="$libpngPath" > "$logFolder/msdf-atlas-gen.gen.log"

echo -e "\tDone"

# Build msdf-atlas-gen
echo "Build msdf-atlas-gen"

cmake --build $msdfBuild --target msdf-atlas-gen-standalone > "$logFolder/msdf-atlas-gen.bin.log"

cp -f "$msdfBuild/bin/msdf-atlas-gen" "$outputFolder/msdf-atlas-gen"

echo -e "\tDone"
