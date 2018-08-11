# GVR Splunk Universal Forwarder Management Guide

<!-- TOC -->

- [GVR Splunk Universal Forwarder Management Guide](#gvr-splunk-universal-forwarder-management-guide)
  - [Prerequisites](#prerequisites)
  - [PHASE 1 - Obtain Current Install Status](#phase-1---obtain-current-install-status)
  - [PHASE 2 - Uninstall Previous Versions](#phase-2---uninstall-previous-versions)
  - [PHASE 3 - Install and Configure Universal Fowarder](#phase-3---install-and-configure-universal-fowarder)
    - [Step 1 - Create and populate a fileshare with installation and configuration files](#step-1---create-and-populate-a-fileshare-with-installation-and-configuration-files)
    - [Step 2 - Download PSDscResources module and distribute to target endPoints](#step-2---download-psdscresources-module-and-distribute-to-target-endpoints)
    - [Step 4: Install UniversalForwarder on target endpoints](#step-4-install-universalforwarder-on-target-endpoints)
  - [More Helpful Functions and Scripts](#more-helpful-functions-and-scripts)

<!-- /TOC -->

## Prerequisites

- [ ] Microsoft's RSAT Tools installed on workstation from which scripts will be executed
- [ ] Administrative access to the system to be managed
- [ ] Target endpoints must be a member of a domain - cannot be standalone servers
- [ ] Windows Server 2012 or greater with WinRM 5.1 installed
  - [ ] Management and uninstall functions will work on Windows Server 2008 R2
  - [ ] DSC installation will not work on 2008 R2 and below
- [ ] PSRemoting enabled on target endpoints
  - How to [Enable PSRemoting via GPO](https://www.techrepublic.com/article/how-to-enable-powershell-remoting-via-group-policy/).
- [ ] ExecutionPolicy must be set to "RemoteSigned" (less restrictive not recommended but will work)
  - How to [Set execution policy through GPO](https://4sysops.com/archives/set-powershell-execution-policy-with-group-policy/)
  - To set manually run `Set-Executionpolicy -ExecutionPolicy RemoteSigned`.
  - ExecutionPolicy must be done on the machine from which the scripts are executed as well as the target endpoints.
- [ ] All functions require a PS Credential object be passed.  By assigning the PScredential object to a variable, you can reuse that object. **Example:**
    ``` Powershell
    $cred = (get-credential)
    ```

## PHASE 1 - Obtain Current Install Status

 **Step Summary:** Obtain a list of systems where Splunk UniversalForwarder needs to be installed and/or upgraded

You can utilize the **Get-GVRSecurityToolsinstallStatus** function in the GVRSecurityModule to identify the installation status of Splunk and CarbonBlack.

**Note:** This function queries the WMI class win32_product for each system.
Depending on the length of time that it takes to list all installed applications and network connectivity, this command may take a considerable length of time for some systems.  Please be patient.  There are other options that are faster if you feel you need to speed things up.

**Example 1:** To query all DC's in the domain "child.domain.local"

```Powershell
    $dclist = get-addomain child.domain.local | % replicadirectoryservers
    $status = Get-GVRSecurityToolsInstallStatus -Computername $dclist -Credential $cred -Verbose
    $status | export-csv C:\temp\securitytoolstatus.csv -NoTypeInformation
```

**Example 2:** Query only a specific host

```PowerShell
    $status = Get-GVRSecurityToolsInstallStatus -Computername dc01.domain.local -Credential $cred -Verbose
    $status | FT -auto
```

**Example 3:** List only the hosts that do not have the SplunkUniversalForwarder installed

```PowerShell
    $status = Get-GVRSecurityToolsInstallStatus -Computername $dclist -Credential $cred -Verbose
    $notinstalled = $status | ? SplunkInstalled -like "False"
    $notinstalled | ft -auto
```

## PHASE 2 - Uninstall Previous Versions

**Step Summary:** Uninstall existing versions of Splunk Universal Fowarder

Currently the DSC installation resource does not perform an upgrade.  To install the latest version of UniversalForward, please remove any previous versions.

You can utilize the function **Uninstall-SplunkUniversalFowarder** to automatically remove Splunk Universal Forwarder from a remote machine. Again, be aware that this uses the WMI class, win32_products and may take some period of time for it to complete.  Please be patient.

**Example:** Remove splunk from a list of servers (1 per line) in a text file

```Powershell
    $list = get-content C:\temp\listofserverstoremovesplunk.txt
    Uninstall-SplunkUniveralFowarder -ComputerName $list -Credential $cred
```

## PHASE 3 - Install and Configure Universal Fowarder

**Step Summary:** Utilize DesiredStateConfiguration (DSC) to install and configure Splunk Universal Forwarder
*Note:** Extract the .ps1 files in GVRSPlunkInstall.zip to a directory. This document examples will use C:\Temp\DSC as the base directory.  All relative paths will assume that you are currently in the base directory where the scripts reside.

Having a basic understanding of PowerShell DSC will be helpful in troubleshooting any issues.  Below are some resources that will provide basic information regarding DSC:

- [Microsoft's DSC Overview](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [PowerShell DSC The Basics](https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-desired-state-configuration-the-basics/)

### Step 1 - Create and populate a fileshare with installation and configuration files

- Create SMB fileshare.  Example used in this document:  `\\hostname.domain.com\DSC`
- Create 2 subfolders:  **DSCResources** and **Install**
  - Folder: `\\hostame.domain.com\DSC\DSCRescources`
  - Folder: `\\hostname.domain.com\DSC\Install`

- Set share permission.  These DSC resources do not pass credentials for share access.
  - The endpoints machine accounts need "Read" permission to this share.  You can either add the machine accounts (more secure) or you can give Read to "everyone" (less secure).
  - **Tip:** Use FQDN in any share paths you define as parameters in the script
- Extract and copy contents of **GVRSPlunkSource_1.0.1.zip** to the **\Install** directory

### Step 2 - Download PSDscResources module and distribute to target endPoints

- Download and copy the Microsoft PowerShell module: PSDscResources

```Powershell
  install-module PSDscResources
```

- Answer "Yes" or "Ok" if prompted to install or connect to PSGallery
- Verify module has been installed:

```Powershell
  Get-Module PSDscResources -ListAvailable
```

- Module will be at 'C:\Program Files\WindowsPowerShell\Modules'.
- Copy the entire folder "PSDscResources" to the `\DSCResources` folder created earlier

**Use DSC to copy PSDscResources module to all target endpoints:**

**Notes:** PowerShell DSC in push mode requires 2 steps to complete a deployment:

- Open Windows Powershell (recommended: runas Administrator)
- Execute the configuration script (DSC_Splunk_CopyDSCResources.ps1) to create mof files for each endoint.
  - A mof file for each endpoing will be stored in a subfolder of your base folder
  - Examples:
    - `C:\temp\DSC\CopyDSCResources\myhost1.domain.local.mof`
    - `C:\temp\DSC\CopyDSCResources\myhost2.domain.local.mof`

To review help and see Parameter requirements:

```Powershell
cd C:\Temp\DSC
get-help .\DSC_Splunk_CopyDSCResources.ps1 -Detailed
```

EXAMPLE:

```PowerShell
cd C:\temp\DSC

# Define the source folder and systems on which to execute
$serverlist = get-content C:\temp\server_list.txt
$Path = '\\hostame.domain.com\DSC\DSCRescources'

# Execute the script to create the MOF files
.\DSC_Splunk_CopyDSCResources.ps1 -ComputerName $serverlist -Path $Path
```

Invoke the DSC configuration and copy the Module to all target endpoints.

EXAMPLE:

```PowerShell
# Create the PSCredential object - local or domain credential with admin access to the endpoints
$cred = get-credential

# Start the DSC configuration.
Start-DscConfiguration .\CopyDSCResources\ -Credential $cred -Wait -Verbose -Force
```

**Tips:**

- Review the output to look for any failures.  Text (in Red) will provide information regarding the problem.
- Most common problems are "ExecutionPolicy" related
- Use the FQDN for all hostnames (shares and endpoints) is a best practice
- You may run the DSC Configuration multiple times without harm.  To remove systems from future configuration runs, delete the corresponding MOF file from the .\CopyDSCResources directory.

### Step 4: Install UniversalForwarder on target endpoints

Universal Forwarder Install: Use DSC to copy the install files to the endpoints then install and configure Universal Forwarder

**Create the MOF files for the DSC Installation Configuration:**

- To review help and see Parameter requirements:

```Powershell
  cd C:\Temp\DSC
  get-help .\DSC_Splunk_InstallSplunkUniversalForwarder.ps1 -Detailed
```

**EXAMPLE:**

```PowerShell
cd C:\temp\dsc

# Set the variables for the required Parameters
$serverlist = get-content C:\temp\serverlist.txt
$cred = get-credential

# Full UNC path to the msi and spl files. Use SMB folder defined earlier
$msipath = '\\hostname.domain.com\DSC\Install\splunkforwarder-7.1.0-2e75b3406c5b-x64-release.msi'
$splpath = '\\hostname.domain.com\DSC\Install\splunkclouduf-14Jun2018.spl'

# Path to the temporary folder on the endpoint where you will copy and execute the files.
$destpath = 'C:\temp' # Warning: Do NOT include '\' at the end of the path

# Create the MOF Files in .\SplunkInstallation directory for each target endpoint
.\DSC_Splunk_InstallSplunk.ps1 -ComputerName $serverlist -MSIPath $msipath -DestinationPath $destpath -SPLPath $splpath

```

**Install UniversalForwarder: Start DSC configuration:**

- **WARNING:** this will install and configure software on your target endpoints!
- The file size being copied is approx 49mb. Depending on network performance it may take some time to remote sites.

```PowerShell
Start-DscConfiguration .\SplunkInstallation -Credential $cred -Verbose -Wait -Force
```

Review output and address errors as needed.

## More Helpful Functions and Scripts

Use these functions and scripts to validate Splunk UniversalForwarder connectivity to the SplunkCloud forward servers.  Also use them to configure DNS Debug logging on remote systems and validate DNS debug settings.

```PowerShell
# Validate splunk-forward servers as active or configured for remote hosts
Test-SplunkForwardServers -ComputerName host1.domain.com -Credential $cred

#Verify that DNS Debug Logging is configured
$list = get-addomain | % replicadirectoryservers
$logging =Get-GVRDNSDebugLogging -ComputerName $list -Credential $cred
$logging | ft -auto

#Set DNS Debug Logging on target endpoints using default settings
Set-GVRDNSDebugLogging -ComputerName myhost.domain.com -Credential $cred
```
