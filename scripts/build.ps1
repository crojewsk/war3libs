<#
 Copyright (c) 2018 Cezary Rojewski

.SYNOPSIS
    Compile Jass and Zinc code and inject it into a Warcraft 3 map file.

.PARAMETER JassInclude
    # Location of common.j and blizzard.j files to include.

.PARAMETER JassHelper
    # Full path specifying location of jasshelper.exe compiler.

.PARAMETER Output
    # Map file to inject compiled code into or name of an output file to create.
    # If Output does not end with '.w3x', then the jasshelper.exe is run with
    # --scriptonly option.

.EXAMPLE
    build.ps1 include/ jasshelper.exe output.w3x
#>
Param ($JassInclude, $JassHelper, $Output)

$Usage = 'Usage: build.ps1 JASS_INCLUDE JASS_HELPER OUTPUT'

If (!$JassInclude -or !$JassHelper -or !$Output)
{
    Write-Host $Usage
    return
}

$CommonJ = Join-Path -Path $JassInclude -ChildPath 'common.j'
$BlizzardJ = Join-Path -Path $JassInclude -ChildPath 'blizzard.j'
$TemporaryJ = ".tmp.j"
$MainJ = "war3map.j"
$BuildDir = "build"
$IncludeDir = "..\include"
$SrcDir = "..\src"

try
{
    Set-Location -Path $BuildDir -ErrorAction Stop

    # Map initialization functions are to be placed at the bottom
    $AllSrcFiles = Get-ChildItem -Path $IncludeDir -Include *.j, *.zn -Exclude $MainJ -Recurse -ErrorAction Stop
    $AllSrcFiles += Get-ChildItem -Path $SrcDir -Include *.j, *.zn -Recurse -ErrorAction Stop
    $AllSrcFiles += Join-Path -Path $IncludeDir -ChildPath $MainJ
    New-Item $TemporaryJ -ItemType File -Force -ErrorAction Stop
}
catch [System.Exception]
{
    Write-Host $PSItem.Exception.Message
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