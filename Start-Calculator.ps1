#Set variables
$ScriptPath = (Get-Location).Path

#Import all JSON files
if ((Test-Path -Path $ScriptPath) -eq $true) {
    $global:ConfigMaster = @{}
    $AllConfigFiles = Get-ChildItem -Path "$($ScriptPath)\Config"

    foreach ($File in $AllConfigFiles) {
        $ConfigName = $null
        $FileContent = $null

        $ConfigName = $File.Name.Replace(".json","")
        $FileContent = Get-Content -Path $File.FullName | ConvertFrom-Json

        $global:ConfigMaster.Add($ConfigName,$FileContent)
    }
}

$global:FactoryBuilds = @()
$global:ProductionChains = @()

#Prompt user to select item or type item name
$global:FactoryDefinition = New-UserPrompt -StartBuild

#Build the factory
if ($FactoryItem) {
    $FactoryBuild = New-FactoryBuild -FactoryItem $FactoryDefinition
}
