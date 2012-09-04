$checkin_url = "http://localhost:8080" 
$active = "Unknown"
$install = $false

if ($env:CI_CHECKIN_HOST -ne $null) 
{ 
  $checkin_url = $env:CI_CHECKIN_HOST 
  $active = $env:CI_CHECKIN_NAME
  $install = $true
} 

Function Report
{
  param([string]$url = "unknown",
        [string]$active = "unknown",
        [string]$imprint = "unknown",
        [string]$state = "unknown",
        [string]$status = "unknown",
        [string]$exception = "")
  
   $exception = $exception.Replace('"', "'").Replace('\', '\\')
   $imprint = $imprint.Replace('\', '\\')

   $data = "{ ""active"": ""$active"", ""state"": ""$state"", ""status"": ""$status"", ""imprint"": ""$imprint"", ""error"": ""$exception"" }"
   $client = New-Object net.WebClient
   $report_url = "$url/engagement-complete/"
   Log "Reporting to $report_url: $data"
   $client.Headers.Add("Content-Type", "application/json")
   $client.UploadString($report_url, $data)
}

function Log
{
   param(
      [Parameter(Position=1,Mandatory=$true)]
      [string]$Value
   )
   
   Add-Content c:\updatelog.txt "$(Get-Date) $Value"
}

function MapNetDrive 
{
    param(
    
    #Non-Boolean parameters (Values)
    #
    [Parameter(Position=1,Mandatory=$true)]
    [string]$Path,
    
    [Parameter(Position=2,Mandatory=$true)]
    $Credentials
    )

    net use $Path $Credentials.GetNetworkCredential().Password /user:$($Credentials.UserName) >> updatelog.txt 2>>updateerr.txt
}

$imprint = ''

Log "Requesting the location of the MSI."

try
{
   $client = New-Object net.WebClient
   $imprint = $client.downloadString("$checkin_url/next-engagement/$active")
}
catch [System.Exception]
{
   Report $checkin_url $active '' 'checkin' 'failure' $_.toString()
}

if ($imprint -ne '')
{
  Log "Imprint: $imprint"

  $downloadComplete = $false

  try
  {
    $cred = "bell"
    Log "Getting credential from file"
    $user = get-content "c:\$cred.user"
    $pswd = get-content "c:\$cred.cred" | convertto-securestring
    $credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $user,$pswd

    Log "Using network share"
    MapNetDrive "\\bell\illuminate" $credential
    Log "Network drive mapped"

    Log "Searching for latest drop in $imprint"
    $latestdrop = (get-childitem "$imprint" | sort-object LastWriteTime -descending)[0]

    Log "Searching for msi drop in $latestdrop"
    $msi = get-childitem -recurse $latestdrop.FullName IlluminateServerSetup*.msi

    Log "Copying $msi.FullName"
    Copy-Item $msi.FullName "c:/latestinstaller.msi"

    $downloadComplete = $true
  }
  catch [System.Exception] 
  {
    Report $checkin_url $active $imprint 'download' 'failure' $_.toString()
  }

  if ($downloadComplete -eq $true) 
  {
    Log "Running installer"

    if ($install -eq $true) 
    {
      msiexec /l*v install.log /i "c:\latestinstaller.msi" $env:CI_MSI_PARAMETERS.Split(" ") /quiet | add-content "c:\updatelog.txt"
    }
    
    if ($?) {
      Report $checkin_url $active $imprint 'imprint' 'success'  
    } else {
      Report $checkin_url $active $imprint 'imprint' 'failure' 
    }
  }
}
