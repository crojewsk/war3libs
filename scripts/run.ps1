<#
 Copyright (c) 2018 Cezary Rojewski

.DESCRIPTION
    Given the input params, attempts to build map using jasshelper
    and if successful, run it.

.REMARKS
    Although no parameters are specified, any provided will be added to
    command line when invoking jasshelper.

    Checkout jasshelper manual for more infomation about available arguments.

.EXAMPLE
    run.ps1 --debug  # '--debug' option will be added to command line
#>

$ScriptPath  = Split-Path -Parent $MyInvocation.MyCommand.Definition


$Warcraft3   = 'E:\Games\Warcraft III\Warcraft III.exe'
$CommonJ     = Join-Path -Path $ScriptPath -ChildPath 'bin\jasshelper\common.j'
$BlizzardJ   = Join-Path -Path $ScriptPath -ChildPath 'bin\jasshelper\blizzard.j'

# For run purposes, clijasshelper is prefered due to stdout redirection
$Jasshelper  = Join-Path -Path $ScriptPath -ChildPath 'bin\jasshelper\clijasshelper.exe'
# Path to directory containing all .j and .zn files to be compiled using jasshelper
$JassFolder  = Join-Path -Path $ScriptPath -ChildPath 'jass'
# Path to unparsed .j file generated prior to compilation
$GeneratedJ  = Join-Path -Path $ScriptPath -ChildPath 'bin\generated.j'
# Path to base map
$MapW3X      = Join-Path -Path $ScriptPath -ChildPath 'build1.w3x'
# Path to output map w3x file to be created after successful build
$OutputW3X   = Join-Path -Path $ScriptPath -ChildPath 'bin\ITT2.w3x'


# Create GeneratedJ file from content of all .j and .zn files
$InputFiles  = Get-ChildItem -Path $JassFolder -Include *.j, *.zn -Recurse
New-Item $GeneratedJ -ItemType File -Force

ForEach ($File in $InputFiles)
{
    If ($File.Extension -eq '.zn')
    {
        Add-Content -Path $GeneratedJ -Value "//! zinc"
        Get-Content -Path $File | Add-Content $GeneratedJ
        Add-Content -Path $GeneratedJ -Value "//! endzinc"
    }
    Else
    {
        Get-Content -Path $File | Add-Content $GeneratedJ
    }
}

Copy-Item $MapW3X $OutputW3X -Force

# Run jasshelper to perform actual compilation of map script
$Params = $args + @($CommonJ, $BlizzardJ, $GeneratedJ, $OutputW3X)
$Ret = & $Jasshelper $Params

If ($Ret -Match 'Success!$')
{
    # Run the map
    & $Warcraft3 @('-window', '-loadfile', $OutputW3X)
}
Else
{
    Write-Host $Ret
}

