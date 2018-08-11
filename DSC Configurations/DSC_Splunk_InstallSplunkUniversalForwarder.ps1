param (
    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        Position = 1)]
    [ValidateNotNull()]
    [string[]]$ComputerName
)
Configuration InstallSplunkUniversalForwarder {
    # Parameter help description
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$NodeName
    )
    Import-DscResource -ModuleName PSDscResources

    Node $Nodename

    {

        MsiPackage InstallSplunkUniversalForwarder {
            ProductId = '{C05A896E-05F4-49B6-A191-FC29B1362B81}'
            Path      = 'C:\temp\splunkforwarder-7.1.0-2e75b3406c5b-x64-release.msi'
            Ensure    = 'Present'
            Arguments = 'AGREETOLICENSE=Yes DEPLOYMENT_SERVER="172.18.23.40:8089"  SPLUNKPASSWORD=changeme '
        } #MSIPackage

        Script ConfigureSplunkCloud {
            SetScript  = {
                set-location 'C:\Program Files\SplunkUniversalForwarder\bin\' ; .\splunk.exe install app C:\temp\splunkclouduf-14Jun2018.spl -auth admin:changeme
                set-location 'C:\Program Files\SplunkUniversalForwarder\bin\' ; .\splunk.exe restart

            } # Set script
            TestScript = { $app = & 'C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe' list app -auth admin:changeme  ; ([string]$app -match "fortive") }
            GetScript  = { @{ Result = (get-module clarencetest | Select-Object Version) } }
            DependsOn  = "[MsiPackage]InstallSplunkUniversalForwarder"
        }
    }
}

$ComputerName | foreach {InstallSplunkUniversalForwarder -nodename $_ }