<#
.SYNOPSIS
    Creates the MOF configuration file to copy modules to remote machines
.DESCRIPTION
    Creates the MOF configuration file to copy modules to remote machines.
    These modules are required for further DSC activity in installing Splunk
    Exports the MOF files to .\CopyDSCResources\ folder
.PARAMETER Computername
    FQDN of the system you would like to run against.  Accepts multiple values.  Accepts Pipeline
.PARAMETER Path
    The source UNC of the folder containing all the modules you need to copy to the local machines
    The UNC share must have everyone read (or have machine permissions added) since credentials
    are not passed
.PARAMETER ModuleDestPath
    The destination path. This must be a Module folder that is in Powershell's path
    Defaults to "C:\Program Files\WindowsPowerShell\modules\"
.EXAMPLE
    C:\PS> .\DSC_Splunk_CopyDSCResources.ps1 -ComputerName myhost.domain.com
.NOTES
    Author: Clarence Holbrook
    Date:   August 8, 2018
#>

param
(
    [String]$Path = "\\source.domain.com\DSC\DSC_Resources\Modules\AllResources",
    [String]$ModuleDestPath = "C:\Program Files\WindowsPowerShell\modules\",
    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        Position = 1)]
    [ValidateNotNull()]
    [string[]]$ComputerName
)

Configuration CopyDSCResources {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$NodeName    )

    Import-DscResource -ModuleName "PSDesiredStateConfiguration"

    Node $NodeName {
        File DSCResourceFolder {
            SourcePath      = $Path
            DestinationPath = $ModuleDestPath
            Recurse         = $true
            Type            = "Directory"
        }
    }
}

$ComputerName | foreach {CopyDSCResources -NodeName $_}