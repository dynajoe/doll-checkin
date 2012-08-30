$checkin_url = if($env:CI_CHECKIN_URL -eq "") { $env:CI_CHECKIN_URL } else { "http://localhost:8080" }
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
   $report_url = "$url/engagement-complete/"
   $report_url
   $client.UploadString($report_url, $data)
}

$imprint = ''

try
{
   $client = New-Object net.WebClient
   $imprint = $client.downloadString($checkin_url + "/next-engagement/" + $active)
}
catch [System.Exception]
{
   Report $checkin_url $active '' 'checkin' 'failure' $_.toString()
}
