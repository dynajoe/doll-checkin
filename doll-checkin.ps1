$checkin_url = $env:CI_CHECKIN_URL
$parts = $env:COMPUTERNAME.Split('-')
$active = $parts[$parts.Length - 1]

Function Report()
{
  param([string]$url = "unknown",
        [string]$active = "unknown",
        [string]$imprint = "unknown",
        [string]$state = "unknown",
        [string]$status = "unknown",
        [string]$error = "")

   $data = @"
   {
      "active": "$active",
      "state": "$state",
      "status": "$status", 
      "imprint": "$imprint",
      "error": "$error"
   }
"@ 

   $client = New-Object net.WebClient
   $client.UploadString("$url/engagement-complete/", $data)
}

$imprint = ''

try
{
   $client = New-Object net.WebClient
   $imprint = $client.downloadString($checkin_url + "/next-engagement/" + $active)
   Report $checkin_url $active '' 'checkin' 'failure' ''
}
catch [System.Exception]
{
   Report $checkin_url $active '' 'checkin' 'failure' ''
}
