# This module is for testing/debugging not requiring the module to be built

##Import Classes

foreach ($class in (Get-ChildItem "$PSScriptRoot\Classes\*.ps1" -ErrorAction SilentlyContinue)) {
    . $Class
}

#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
foreach ($import in @($Public)) {
    try {
        Write-Verbose "Importing $($Import.FullName)"
        . $import.FullName
    } catch {
        Write-Error -Message "Failed to import function $($import.fullName): $_"
    }
}

Export-ModuleMember -Function $Public.Basename