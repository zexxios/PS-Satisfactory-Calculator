function Export-Project {
    param (
        [switch]$End,
        [string]$Selection
    )

    if (!$End) {
        $CurrentDate = Get-Date -Format "MM-dd-yyyy_hh-mmtt"

        #Create report directory if it doesn't exist
        if ((Test-Path -Path "$($global:RunSettings.Preferences.ProjectDirectory)\Reports") -eq $false) {
            $ReportPath = (New-Item -Path "$($global:RunSettings.Preferences.ProjectDirectory)\Reports\$($global:ActiveProject.Name)-$($CurrentDate)" -ItemType Directory).FullName
        }

        #Create all CSVs for active project
        if (($Selection -eq "JSON") -or ($Selection -eq "All")) {            
            $global:ActiveProject.Details.ProductionChains | Foreach-Object {

            }
            
            $ProductionChainsCSV | Export-CSV -Path "$($ReportPath)\ProductionChains.csv"
        }

        if (($Selection -eq "HTML") -or ($Selection -eq "All")) {
            
        }

        $UserResponse = $null

    } else {
        try {
            $global:ActiveProject | Export-CLIXML -Path $global:ActiveProject.FilePath -Force

            Write-Host -ForegroundColor Green "Project has been exported to [$($global:ActiveProject.FilePath)]"
            
        } catch {
            Write-Output "Unable to export project to file"
            Write-Output $_
        }
    }
}