function New-PromptArray {
    param (
        $Options
    )

    $PromptArray = @()

    $i = 1
    if ($Options) {
        $Options | Foreach-Object {
            $PromptArray += [PSCustomObject]@{
                ID = $i
                Message = $_
            }

            $i++
        }

        if ($PromptArray) {
            Write-Output $PromptArray
        }
    }
}