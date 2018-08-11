<#
	.SYNOPSIS
		Identify whether or not Splunk and CarbonBlack are installed and the corresponding version

	.DESCRIPTION
		Connects to remote machine via WMI and checks to see if Splunk UniversalForwarder and CarbonBlack are installed. If they are installed it provides the version of the software enstalled.

	.PARAMETER ComputerName
		[String] Computername to execute the function.  Can be multiple values.  Recommend FQDN hostname

	.PARAMETER Credential
		Powershell Credential Object - Use (Get-Credential) if necessary.

	.EXAMPLE
				PS C:\> Get-GVRSecurityToolsInstallStatus -ComputerName 'dc01.domain.local' -Credential $cred -Verbose

	.NOTES
		Additional information about the function.
#>
function Get-GVRSecurityToolsInstallStatus {
    [CmdletBinding(ConfirmImpact = 'None',
        PositionalBinding = $true)]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1,
            HelpMessage = 'Please enter a valid FQDN hostname')]
        [ValidateNotNull()]
        [string[]]$ComputerName,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Please provide valid PS Credential hint: (get-credential)')]
        [ValidateNotNull()]
        [pscredential]$Credential
    )

    Begin {

    }
    Process {

        $systemcount = $ComputerName.count
        Write-Verbose -Message "Querying $systemcount computers. This may take some time depending on number of systems, software installed, and network connectivity."

        Foreach ($Computer in $ComputerName) {

            Write-Verbose -Message "Beginning Get-WMIObject Win32_Product query on $computer.  Please be patient."
            $installed = Get-WmiObject Win32_Product -ComputerName $Computer -Credential $Credential
            Write-Verbose -Message "Query on $computer complete"


            $applist = $installed | ForEach-Object Name
            $carbon = ($applist -contains "CarbonBlack Sensor")
            $carbonversion = ($installed | Where-Object Name -Like "CarbonBlack Sensor").version
            $forwarder = ($applist -contains "UniversalForwarder")
            $splunkver = ($installed | Where-Object Name -like "UniversalForwarder").Version

            $obj = New-Object -TypeName psobject -Property @{
                ComputerName      = $Computer
                SplunkInstalled   = $forwarder
                SplunkVersion     = $splunkver
                CarbonBlack       = $carbon
                CarbonBlk_Version = $carbonversion

            } # $obj = New-Object

            $obj

        } # $foreach g in computername

    }
    End {

    }
}
