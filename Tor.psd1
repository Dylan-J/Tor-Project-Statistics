@{

    # Script module or binary module file associated with this manifest.
    # RootModule = ''

    # Version number of this module.
    ModuleVersion     = '1.0.0'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID              = '1a576e2f-8540-441a-982d-0f1d45790325'

    # Author of this module
    Author            = 'Dylan Jones'

    # Company or vendor of this module
    CompanyName       = 'Microsoft'

    # Copyright statement for this module
    Copyright         = '(c) Dylan Jones. All rights reserved.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = @(
        'Functions\Get-TorSummary.ps1',
        'Functions\Get-TorRelay.ps1'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Get-TorSummary',
        'Get-TorRelay'
    )

    ScriptsToProcess  = @(
        'Classes\TorBridgeSummary.ps1',
        'Classes\TorRelayData.ps1',
        'Classes\TorRelayIP.ps1',
        'Classes\TorRelaySummary.ps1',
        'Classes\TorRelayExitPolicy.ps1'
    )

    RequiredAssemblies = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{


        } 

    } 
}