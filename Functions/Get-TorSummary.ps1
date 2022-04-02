function Get-TorSummary {
    [CmdletBinding()]
    param (
        [string] [Parameter(Mandatory = $true)] $OutputFolder
    )
    $SummaryCSV = "TorRelaySummary.csv"
    $BridgeSummaryCSV = "TorBridgeSummary.csv"
    $SummaryList = @()
    $BridgeList = @()

    if (!(Test-Path($OutputFolder))) { 
        Try {
            mkdir $OutputFolder -ErrorAction:Stop | Out-Null 
        }
        catch {
            Write-Error "Cannot create configuration folder $($OutputFolder)"
            exit
        }
    }

    Write-Verbose "Downloading TOR node information"
    $Uri = "https://onionoo.torproject.org/summary"
    $PageResponse = Invoke-WebRequest $Uri -UseBasicParsing
    $RelayPublishDate = ($PageResponse.Content | convertfrom-json).relays_published
    $BridgePublishDate = ($PageResponse.Content | convertfrom-json).bridges_published
    $SummaryData = ($PageResponse.Content | convertfrom-json).relays
    foreach ($RelayInfo in $SummaryData) {
        $RelaySummary = [TorRelaySummary]::new()
        $RelaySummary.Nickname = $RelayInfo.n
        $RelaySummary.Fingerprint = $RelayInfo.f
        $RelaySummary.IPAddress = $RelayInfo.a
        $RelaySummary.IsRunning = $RelayInfo.r
        $RelaySummary.RelayPublishDate = $RelayPublishDate
        $RelaySummary.NodeType = "Relay"
        $SummaryList += $RelaySummary
    }

    $SummaryData = ($PageResponse.Content | convertfrom-json).bridges
    foreach ($BridgeInfo in $SummaryData) {
        $BridgeSummary = [TorBridgeSummary]::new()
        $BridgeSummary.Nickname = $BridgeInfo.n
        $BridgeSummary.Fingerprint = $BridgeInfo.h
        $BridgeSummary.IsRunning = $BridgeInfo.r
        $BridgeSummary.BridgePublishDate = $BridgePublishDate
        $BridgeSummary.NodeType = "Bridge"
        $BridgeList += $BridgeSummary
    }
    Write-Host "Saving output to $OutputFolder"
    $SummaryList | Export-csv $OutputFolder\$SummaryCSV -NoTypeInformation -Force
    $BridgeList | Export-csv $OutputFolder\$BridgeSummaryCSV -NoTypeInformation -Force
}