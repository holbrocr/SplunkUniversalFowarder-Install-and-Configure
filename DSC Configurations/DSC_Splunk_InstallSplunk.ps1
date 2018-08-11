param
(
    [String]$MSIPath = "\\source.domain.com\DSC\Splunk\splunkforwarder-7.1.0-2e75b3406c5b-x64-release.msi",
    [String]$DestinationPath = "C:\Temp",
    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        Position = 1)]
    [ValidateNotNull()]
    [string[]]$ComputerName,
    [String]$SPLPath = "\\source.domain.com\DSC\Splunk\splunkclouduf-14Jun2018.spl"
)

Configuration SplunkInstallation
{
    param (
        $nodename
    )

    Import-DscResource -ModuleName 'PSDscResources'

    Node $nodename

    {
        File TempDirectory {
            Ensure          = "Present"
            Type            = "Directory"
            DestinationPath = $DestinationPath
            Force           = $true
        }

        File SplunkMSICopy {
            Ensure          = "Present"
            Type            = "File" # Default is "File".
            MatchSource     = $true
            SourcePath      = $MSIPath
            DestinationPath = "$Destinationpath\splunkforwarder-7.1.0-2e75b3406c5b-x64-release.msi"
            DependsOn       = "[File]TempDirectory"

        }

        File SplunkCertCopy {
            Ensure          = "Present"
            Type            = "File" # Default is "File".
            MatchSource     = $true
            SourcePath      = $SPLPath
            DestinationPath = "$DestinationPath\splunkclouduf-14Jun2018.spl"
            DependsOn       = "[File]SplunkMSICopy"
        }

        MsiPackage InstallSplunkUniversalForwarder {
            ProductId = '{C05A896E-05F4-49B6-A191-FC29B1362B81}'
            Path      = "$DestinationPath\splunkforwarder-7.1.0-2e75b3406c5b-x64-release.msi"
            Ensure    = 'Present'
            Arguments = 'AGREETOLICENSE=Yes DEPLOYMENT_SERVER="172.18.23.40:8089"  SPLUNKPASSWORD=changeme '
            DependsOn = "[File]SplunkCertCopy"
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

$ComputerName | foreach {SplunkInstallation -nodename $_ }
