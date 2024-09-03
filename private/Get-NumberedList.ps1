function Get-NumberedList {
    param (
        [PSCustomObject]$Object
    )

    $i = 1
    $NumberedList = @()

    if ($Object) {
        foreach ($Name in $Object) {
            $NumberedList += [PSCustomObject]@{
                ID = $i
                Name = $Name
            }

            $i++
        }

        if ($NumberedList) {
            Write-Output $NumberedList
        }
    }
}