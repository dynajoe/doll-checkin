Import-Module Deployment

$checkin_url = if($env:CI_CHECKIN_URL -eq "") { "http://localhost:8080" } else { $env:CI_CHECKIN_URL }
$parts = $env:COMPUTERNAME.Split('-')
$active = $parts[$parts.Length - 1]

Function Report
{
  param([string]$url = "unknown",
        [string]$active = "unknown",
        [string]$imprint = "unknown",
        [string]$state = "unknown",
        [string]$status = "unknown",
        [string]$error = "")

   $data = "{ ""active"": ""$active"", ""state"": ""$state"", ""status"": ""$status"", ""imprint"": ""$imprint"", ""error"": ""$error"" }"
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
  Log "Location: $imprint"

  $cred = "bell"
  Log "Getting credential from file"
  $user = get-content "c:\$cred.user"
  $pswd = get-content "c:\$cred.cred" | convertto-securestring
  $credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $user,$pswd
  Log "Using network share"
  MapNetDrive "\\bell\illuminate" $credential
  Log "Network drive mapped"
  Log "Running install-latest"
  #Install-Latest $imprint 'c:\latestinstaller.msi'

  Report $checkin_url $active $imprint 'imprint' 'success'  
}
