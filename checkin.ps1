$checkin_url = "http://localhost:8080" 
$active = "Unknown"
$install = $false

if ($env:CI_CHECKIN_HOST -ne $null) 
{ 
  $checkin_url = $env:CI_CHECKIN_HOST 
  $active = $env:CI_CHECKIN_NAME
  $install = $true
} 

#Taken and adapted to pseudo escape backslashes from http://powershelljson.codeplex.com/
Function ConvertFrom-JSON {
    param(
        $json,
        [switch]$raw  
    )

    Begin
    {
      $script:startStringState = $false
      $script:valueState = $false
      $script:arrayState = $false 
      $script:saveArrayState = $false
      $script:lastChar = ""
      $script:escaping = $false

      function scan-characters ($c) {
        switch -regex ($c)
        {
          "{" { 
            "(New-Object PSObject "
            $script:saveArrayState=$script:arrayState
            $script:valueState=$script:startStringState=$script:arrayState=$false       
            $script:lastChar=""
              }
          "}" { ")"; $script:arrayState=$script:saveArrayState }

          '"' {
            if($script:startStringState -eq $false -and $script:valueState -eq $false -and $script:arrayState -eq $false) {
              '| Add-Member -Passthru NoteProperty "'
            }
            else { '"';$script:lastChar="" }

            $script:startStringState = $true
          }

          "[a-z0-9A-Z@._\-\\ ]" { 
            
            if ($script:lastChar -eq '\' -and $c -eq '\') {
              '\'
              $script:lastChar=''
            } 
            elseif ($c -eq '\') { 
              $script:lastChar=$c
            }
            else {
              $c
              $script:lastChar=$c 
            }
          }

          ":" {" " ;$script:valueState = $true }
          "," {
            if($script:arrayState) { "," }
            else { $script:valueState = $false; $script:startStringState = $false }
          } 
          "\[" { "@("; $script:arrayState = $true }
          "\]" { ")"; $script:arrayState = $false }
          "[\t\r\n]" {}
        }
      }
      
      function parse($target)
      {
        $result = ""
        ForEach($c in $target.ToCharArray()) {  
          $result += scan-characters $c
        }
        $result   
      }
    }

    Process { 
        if($_) { $result = parse $_ } 
    }

    End { 
        If($json) { $result = parse $json }

        If(-Not $raw) {
            $result | Invoke-Expression
        } else {
            $result 
        }
    }
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

$result = ''

Log "Requesting the location of the MSI."

try
{
   $client = New-Object net.WebClient
   $result = $client.downloadString("$checkin_url/next-engagement/$active")
}
catch [System.Exception]
{
   Report $checkin_url $active '' 'checkin' 'failure' $_.toString()
}

if ($result -ne '')
{
  Log "Imprint: $result"

  $downloadComplete = $false

  try
  {
    $imprint = ConvertFrom-JSON $result

    $cred = "bell"
    Log "Getting credential from file"
    $user = get-content "c:\$cred.user"
    $pswd = get-content "c:\$cred.cred" | convertto-securestring
    $credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $user,$pswd

    Log "Using network share"
    MapNetDrive "\\bell\illuminate" $credential
    Log "Network drive mapped"
    
    $droplocation = $imprint.memory

    Log "Searching for latest drop in $droplocation"
    $latestdrop = (get-childitem "$droplocation" | sort-object LastWriteTime -descending)[0]

    Log "Searching for msi drop in $latestdrop"
    $msi = get-childitem -recurse $latestdrop.FullName IlluminateServerSetup*.msi

    Log "Copying $msi.FullName"
    Copy-Item $msi.FullName "c:/latestinstaller.msi"

    $downloadComplete = $true
  }
  catch [System.Exception] 
  {
    Report $checkin_url $active $imprint.memory 'download' 'failure' $_.toString()
  }

  if ($downloadComplete -eq $true) 
  {
    Log "Running installer"

    if ($install -eq $true) 
    {
      msiexec /i "c:\latestinstaller.msi" $imprint.parameters /quiet | add-content "c:\updatelog.txt"
    }

    if ($?) {
      Report $checkin_url $active $imprint.memory 'imprint' 'success'  
    } else {
      Report $checkin_url $active $imprint.memory 'imprint' 'failure' 
    }
  }
}
