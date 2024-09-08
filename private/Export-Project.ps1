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
        #Final export of the project
        $global:ActiveProject | Export-CLIXML -Path "$($global:RunSettings.Preferences)"
    }
}