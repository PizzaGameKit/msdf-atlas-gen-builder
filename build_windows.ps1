$arch = "x64"
$vs_arch = "x86.x64"
$cmake_arch = "x64"

if ($Args[0] -eq "arm64")
{
	$arch = $Args[0]
	$vs_arch = "ARM64"
	$cmake_arch = "ARM64"
}

$zlibPath = Convert-Path -LiteralPath "./zlib"
$libpngPath = Convert-Path -LiteralPath "./libpng"
$freetypePath = Convert-Path -LiteralPath "./freetype"
$msdfPath = Convert-Path -LiteralPath "./msdf-atlas-gen"

$outputFolder = "./binaries/win-$arch"

Remove-Item $outputFolder -Recurse -ErrorAction SilentlyContinue
if (!(Test-Path -Path $outputFolder)) {New-Item $outputFolder -Type Directory >$null}

$logFolder = "./logs/win-$arch"

Remove-Item $logFolder -Recurse -ErrorAction SilentlyContinue
if (!(Test-Path -Path $logFolder)) {New-Item $logFolder -Type Directory >$null}

$buildFolder = "build"

$zlibBuild = "$zlibPath/$buildFolder"
$libpngBuild = "$libpngPath/$buildFolder"
$freetypeBuild = "$freetypePath/$buildFolder"
$msdfBuild = "$msdfPath/$buildFolder"

$zlibLib = "$zlibBuild/Release/zs.lib"
$libpngLib = "$libpngBuild/Release/libpng18_static.lib"
$freetypeLib = "$freetypeBuild/Release/freetype.lib"
			
Write-Host "Look for MSBuild with C++ support" -ForegroundColor DarkCyan

	Set-Alias vswhere -Value "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

	$msbuild = vswhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.$vs_arch -find MSBuild\**\Bin\MSBuild.exe | select-object -first 1
	if (!$msbuild -Or !(Test-Path -Path $msbuild))
	{
		Write-Host "`tNot installed. Build aborted. Please install Visual Studio with the C++ component." -ForegroundColor DarkRed
		Read-Host -Prompt "Press Enter to exit"
		Break
	}
	else
	{
		Write-Host "`tFound at: $msbuild"
		Set-Alias msbuild -Value "$msbuild"
	}
	
Write-Host "Look for CMake support" -ForegroundColor DarkCyan

	if (!(Get-Command "cmake" -errorAction SilentlyContinue))
	{
		$cmake = vswhere -latest -find **\cmake.exe | select-object -first 1
		if (!$cmake -Or !(Test-Path -Path $cmake))
		{
			Write-Host "`tCMake is not installed or not on PATH. Please add it to PATH or installed it from the Visual Studio components." -ForegroundColor DarkRed
			Read-Host -Prompt "Press Enter to exit"
			Break
		}
		else
		{
			Write-Host "`tFound at (from Visual Studio): $cmake"
			Set-Alias cmake -Value "$cmake"
		}
	}
	else
	{
		$cmake = (Get-Command "cmake" -errorAction SilentlyContinue).Path
		Write-Host "`tFound at (from PATH): $cmake"
	}

Write-Host "Generate zlib" -ForegroundColor DarkCyan

	Remove-Item $zlibBuild -Recurse -ErrorAction SilentlyContinue
	if (!(Test-Path -Path $zlibBuild)) {New-Item $zlibBuild -Type Directory >$null}

	cmake -S $zlibPath -B $zlibBuild -G "Visual Studio 17 2022" -A $cmake_arch -DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded" | Out-File -FilePath "$logFolder/zlib.gen.log" -Append

	Write-Host "`tDone"

Write-Host "Build zlib" -ForegroundColor DarkCyan

	msbuild $zlibBuild/zlib.sln /t:zlibstatic /p:Configuration="Release" /p:Platform="$cmake_arch" | Out-File -FilePath "$logFolder/zlib.bin.log" -Append

	Write-Host "`tDone"

Write-Host "Generate libpng" -ForegroundColor DarkCyan

	Remove-Item $libpngBuild -Recurse -ErrorAction SilentlyContinue
	if (!(Test-Path -Path $libpngBuild)) {New-Item $libpngBuild -Type Directory >$null}

	cmake -S $libpngPath -B $libpngBuild -G "Visual Studio 17 2022" -A $cmake_arch -DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded" -DZLIB_LIBRARY="$zlibLib" -DZLIB_INCLUDE_DIR="$zlibPath" | Out-File -FilePath "$logFolder/libpng.gen.log" -Append

	Write-Host "`tDone"

Write-Host "Build libpng" -ForegroundColor DarkCyan

	msbuild $libpngBuild/libpng.sln /t:png_static /p:Configuration="Release" /p:Platform="$cmake_arch" | Out-File -FilePath "$logFolder/libpng.bin.log" -Append
	
	Copy-Item -Path "$libpngPath/pnglibconf.h.prebuilt" -Destination "$libpngPath/pnglibconf.h"

	Write-Host "`tDone"

Write-Host "Generate freetype" -ForegroundColor DarkCyan

	Remove-Item $freetypeBuild -Recurse -ErrorAction SilentlyContinue
	if (!(Test-Path -Path $freetypeBuild)) {New-Item $freetypeBuild -Type Directory >$null}

	cmake -S $freetypePath -B $freetypeBuild -G "Visual Studio 17 2022" -A $cmake_arch -DFT_DISABLE_BZIP2=TRUE -DFT_DISABLE_BROTLI=TRUE -DBUILD_SHARED_LIBS=false -DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded" -DZLIB_LIBRARY="$zlibLib" -DZLIB_INCLUDE_DIR="$zlibPath" -DPNG_LIBRARY="$libpngLib" -DPNG_PNG_INCLUDE_DIR="$libpngPath" | Out-File -FilePath "$logFolder/freetype.gen.log" -Append

	Write-Host "`tDone"

Write-Host "Build freetype" -ForegroundColor DarkCyan

	msbuild $freetypeBuild/freetype.sln /t:freetype /p:Configuration="Release" /p:Platform="$cmake_arch" | Out-File -FilePath "$logFolder/freetype.bin.log" -Append

	Write-Host "`tDone"
	
Write-Host "Generate msdf-atlas-gen" -ForegroundColor DarkCyan

	Remove-Item $msdfBuild -Recurse -ErrorAction SilentlyContinue
	if (!(Test-Path -Path $msdfBuild)) {New-Item $msdfBuild -Type Directory >$null}

	cmake -S $msdfPath -B $msdfBuild -G "Visual Studio 17 2022" -A $cmake_arch -DMSDF_ATLAS_USE_VCPKG=OFF -DMSDF_ATLAS_NO_ARTERY_FONT=OFF -DMSDF_ATLAS_USE_SKIA=OFF -DFREETYPE_LIBRARY="$freetypeLib" -DFREETYPE_INCLUDE_DIRS="$freetypePath/include/freetype;$freetypePath/include" -DZLIB_LIBRARY="$zlibLib" -DZLIB_INCLUDE_DIR="$zlibPath" -DPNG_LIBRARY="$libpngLib" -DPNG_PNG_INCLUDE_DIR="$libpngPath" | Out-File -FilePath "$logFolder/msdf-atlas-gen.gen.log" -Append

	Write-Host "`tDone"

Write-Host "Build msdf-atlas-gen" -ForegroundColor DarkCyan

	msbuild $msdfBuild/msdf-atlas-gen.sln /t:msdf-atlas-gen-standalone /p:Configuration="Release" /p:Platform="$cmake_arch" | Out-File -FilePath "$logFolder/msdf-atlas-gen.bin.log" -Append

	if (!(Test-Path -Path "$outputFolder")) {New-Item "$outputFolder" -Type Directory >$null}
	Copy-Item -Path "$msdfBuild/bin/Release/msdf-atlas-gen.exe" -Destination "$outputFolder/msdf-atlas-gen.exe"
	
	Write-Host "`tDone"

Read-Host -Prompt "All done - Press Enter to exit"