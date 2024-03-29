<#
 Copyright (c) 2018 Cezary Rojewski

.SYNOPSIS
    Compile Jass and Zinc code and inject it into a Warcraft 3 map file.

.PARAMETER JassNatives
    # Location of common.j and blizzard.j files to include.

.PARAMETER JassHelper
    # Full path specifying location of jasshelper.exe compiler.

.PARAMETER Output
    # Map file to inject compiled code into or name of an output file to create.
    # If Output does not end with '.w3x', then the jasshelper.exe is run with
    # --scriptonly option.

.EXAMPLE
    build.ps1 natives/ jasshelper.exe output.w3x
#>
Param ($JassNatives, $JassHelper, $Output)

$Usage = 'Usage: build.ps1 JASS_NATIVES JASS_HELPER OUTPUT'

If (!$JassNatives -or !$JassHelper -or !$Output)
{
    Write-Host $Usage
    return
}

$CommonJ = Join-Path -Path $JassNatives -ChildPath 'common.j'
$BlizzardJ = Join-Path -Path $JassNatives -ChildPath 'blizzard.j'
$TemporaryJ = ".tmp.j"
$MainJ = "war3map.j"
$BuildDir = "build"
$IncludeDir = "..\include"
$SrcDir = "..\src"
$TestMap = "..\ExampleMap.w3x"

If (!(Test-Path -PathType Container $BuildDir))
{
    New-Item $BuildDir -ItemType Directory
}

try
{
    Set-Location -Path $BuildDir -ErrorAction Stop
    Copy-Item -Path $TestMap -Force

    # Map initialization functions are to be placed at the bottom
    $AllSrcFiles = Get-ChildItem -Path $IncludeDir -Include *.j, *.zn -Exclude $MainJ -Recurse -ErrorAction Stop
    $AllSrcFiles += Get-ChildItem -Path $SrcDir -Include *.j, *.zn -Recurse -ErrorAction Stop
    $AllSrcFiles += Join-Path -Path $IncludeDir -ChildPath $MainJ
    New-Item $TemporaryJ -ItemType File -Force -ErrorAction Stop
}
catch [System.Exception]
{
    Write-Host $PSItem.Exception.Message
    return
}

# Fill TemporaryJ with content of all .j and .zn files
ForEach ($File in $AllSrcFiles)
{
    If ($File.Extension -eq '.zn')
    {
        Add-Content -Path $TemporaryJ -Value "//! zinc"
        Get-Content -Path $File | Add-Content $TemporaryJ
        Add-Content -Path $TemporaryJ -Value "//! endzinc"
    }
    Else
    {
        Get-Content -Path $File | Add-Content $TemporaryJ
    }
}

$JassHelperArgs = @("""$CommonJ""", """$BlizzardJ""", $TemporaryJ, """$Output""")
If (!$Output.EndsWith('.w3x'))
{
    $JassHelperArgs = "--scriptonly " + $JassHelperArgs
}

Start-Process -NoNewWindow -FilePath $JassHelper -ArgumentList $JassHelperArgs -Wait
# Temporary file no longer needed
Remove-Item $TemporaryJ