function Uninstall-SplunkUniversalFowarder {
    <#
.SYNOPSIS
    Uninstall UniversalForwarder remotely
.DESCRIPTION
    Uses WMI Win32_Product to uninstall any instances of UniversalForwarder.
.PARAMETER Computername
    FQDN of the system you would like to run against.  Accepts multiple values.  Accepts Pipeline
.PARAMETER SplunkInstall
    Specifies a path to the 'bin' directory of the splunk install
    Defaults to "C:\Program Files\SplunkUniversalForwarder\bin\"
.PARAMETER Credential
    Requires a PSCredential object
.EXAMPLE
    C:\PS> Uninstall-SplunkUniversalFowarder -ComputerName myhost.domain.com -Credential (get-credential)
    Test the fowarders using the default SplunkLogin credential and default install path
.NOTES
    Author: Clarence Holbrook
    Date:   August 3, 2018
#>

    [CmdletBinding()]
    param(
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ComputerName,
        [Parameter (Mandatory = $true)]
        [pscredential]$Credential
    )

    begin {
    }

    process {
        Foreach ($l in $ComputerName) {
            Write-Verbose -Message "Processing $l"
            $app = Get-WmiObject Win32_Product -ComputerName $l -Credential $Credential -Verbose -Filter "Name = 'UniversalForwarder'"
            $app.uninstall()

        } #foreach $l in $list
    }

    end {
    }
}
