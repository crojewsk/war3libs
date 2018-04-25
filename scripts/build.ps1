$ScriptPath  = Split-Path -Parent $MyInvocation.MyCommand.Definition

$CommonJ     = Join-Path -Path $ScriptPath -ChildPath 'temp\common.j'
$BlizzardJ   = Join-Path -Path $ScriptPath -ChildPath 'temp\blizzard.j'
$Jasshelper  = Join-Path -Path $ScriptPath -ChildPath 'jasshelper\jasshelper.exe'

$War3MapJ    = Join-Path -Path $ScriptPath -ChildPath 'bin\war3map.j'
$MapW3X      = Join-Path -Path $ScriptPath -ChildPath 'bin\Build.w3x'
$OutputW3X   = Join-Path -Path $ScriptPAth -ChildPath 'bin\NOTD_Aftermath_1.6.w3x'

Copy-Item $MapW3X $OutputW3X -Force

$Params = @($CommonJ, $BlizzardJ, $War3MapJ, $OutputW3X)
& $Jasshelper $Params
