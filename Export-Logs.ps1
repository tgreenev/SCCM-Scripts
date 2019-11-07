Param(
    [Parameter(Mandatory = $True)]
    [AllowEmptyString()]
    [string]$numberOfDays = '7'
)
if ($numberOfDays -eq "") { $numberOfDays = "7" }
#Script will only run if number of days is a number up to 999
if ($numberOfDays -match "^\d{1,3}$") {
    #Create log folder if it is not there
    New-Item -ItemType Directory -Path C:\ -Name Logs -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType Directory -Path C:\Logs -Name EventLogs -ErrorAction SilentlyContinue | Out-Null
    #Remove any old .7z file that starts with log_
    Get-ChildItem -Path C:\Logs\EventLogs log_*.7z | Remove-Item
    #Cast number to int
    [int]$days = $numberOfDays
    #Convert number to negative to get past days
    $Date = ((Get-Date).AddDays(0 - $days))
    #This two-liner is to convert to milliseconds
    $tsThen = New-TimeSpan -Start $date -End (Get-Date)
    $DateMS = [math]::Round($tsThen.TotalMilliseconds)
    #The next three lines will export the logs to given path 
    #Checks to see if system log exisits, if so overwrite
    if (Test-Path  C:\Logs\EventLogs\system.evtx) { wevtutil epl System C:\Logs\EventLogs\system.evtx /q:"*[System[TimeCreated[timediff(@SystemTime) >= 0] and TimeCreated[timediff(@SystemTime) <= $DateMS]]]" /ow }
    else { wevtutil epl System C:\Logs\EventLogs\system.evtx /q:"*[System[TimeCreated[timediff(@SystemTime) >= 0] and TimeCreated[timediff(@SystemTime) <= $DateMS]]]" }
    #Checks application log
    if (Test-Path  C:\Logs\EventLogs\application.evtx) { wevtutil epl Application C:\Logs\EventLogs\application.evtx /q:"*[System[TimeCreated[timediff(@SystemTime) >= 0] and TimeCreated[timediff(@SystemTime) <= $DateMS]]]" /ow }
    else { wevtutil epl Application C:\Logs\EventLogs\application.evtx /q:"*[System[TimeCreated[timediff(@SystemTime) >= 0] and TimeCreated[timediff(@SystemTime) <= $DateMS]]]" }
    #Checks security
    if (Test-Path  C:\Logs\EventLogs\security.evtx) { wevtutil epl Security C:\Logs\EventLogs\security.evtx /q:"*[System[TimeCreated[timediff(@SystemTime) >= 0] and TimeCreated[timediff(@SystemTime) <= $DateMS]]]" /ow }
    else { wevtutil epl Security C:\Logs\EventLogs\security.evtx /q:"*[System[TimeCreated[timediff(@SystemTime) >= 0] and TimeCreated[timediff(@SystemTime) <= $DateMS]]]" }
    $fileName = "C:\Logs\EventLogs\log_" + (Get-Date -Format yyyyMMddTHHmmss) + ".7z"
    #Use 7zip to compress to 7z file for smallest size possible
    & "C:\Program Files\7-Zip\7z.exe" a -t7z $fileName C:\Logs\EventLogs\ | Out-Null
    #Determine path for logs to be pushed and setting folder name based off target machine
    $filePath = "\\server\share\LogsPushed\$($env:COMPUTERNAME)\"
    #Creating the folder, if it exists we will surpress the error
    New-Item -ItemType Directory -path $filePath -Force -ErrorAction SilentlyContinue | Out-Null
    #Copying the 7z file to the network folder
    Copy-Item -Path $fileName -Destination $filePath | Out-Null
    Write-Host "SUCCESS: Pull events logs, compressed and copied to share."
}
else {
    Write-Host "You entered an invalid number. Please enter an number up to 999."
}
