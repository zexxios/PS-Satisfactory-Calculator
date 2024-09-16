function Get-ProjectFiles {
    $AllProjects = (Get-ChildItem -Path $global:RunSettings.Preferences.ProjectDirectory -Recurse | Where-Object {$_.Name -match ".xml"}) | Select-Object Name,FullName

    if ($AllProjects.Count -ge 1) {
        $AllProjects | Foreach-Object {
            $ProjectContents = $null
            $ProjectContents = Import-CLIXML -Path $_.FullName
            $FilePath = $_.FullName
            
            if ($ProjectContents.FilePath -ne $FilePath) {
                Write-Host "$($FilePath)"
                $ProjectContents.FilePath = $FilePath
            }

            $global:RunSettings.Projects += $ProjectContents
        }
        Write-Host ""
        Write-Host -ForegroundColor Green "Found and imported [$($global:RunSettings.Projects.Count)] existing projects"
    }
}