Param(
    [Parameter(Mandatory = $True)]
    [AllowEmptyString()]
    [string]$processInput,
    [Parameter(Mandatory = $True)]
    [AllowEmptyString()]
    [string]$option = 'Status'
)
#Since Get-Process does not use .exe, we need to elimate it if it exists
if ($processInput -like "*.exe") { $processInput = $processInput.replace(".exe", "") }

#Need to create a Log directory in case it does not exist, even if it does, the error is supressed
New-Item -ItemType Directory -Path C:\ -Name Logs -ErrorAction SilentlyContinue | Out-Null
$logfile = "C:\Logs\InvalidProcess.log"
$matchParam = "^Status|Kill$"
if ($option -match $matchParam) {
    $process = Get-Process $processInput -ErrorAction SilentlyContinue
    if ($process) {
        $ProcessOwner = (Get-Process $process.ProcessName -IncludeUserName | Select-Object -ExpandProperty username -Unique | ForEach-Object { $_.split("\")[1] }) -join ","
        if ($option -eq "Status") {
            if ($process.GetType().BaseType.Name -eq "Array") {
                $statusProcess = $process[0]
                Write-Host "Process Name: $($statusProcess.ProcessName)"
                Write-Host "Process Owners: $($ProcessOwner)"
            }
            else {
                Write-Host "Process Name: $($process.ProcessName)"
                Write-Host "Process Owner: $($ProcessOwner)" 
            }
        }
        if ($option -eq "Kill") {
            if ($process.GetType().BaseType.Name -eq "Array") {
                $KillProcess = $process[0]
                $DateTime = "[$((Get-Date -Format "MM/dd/yy HH:mm:ss"))]"
                "$DateTime INFO: Had to kill the following process (multiple ran):" | Add-Content $logFile
                "$DateTime Process Name: $($KillProcess.ProcessName)" | Add-Content $logFile
                "$DateTime Process Path: $($KillProcess.Path)" | Add-Content $logFile
                "$DateTime Process Owners: $($ProcessOwner)" | Add-Content $logFile
                $process | Stop-Process -Force
                Write-Host "SUCCESS: Killed $($KillProcess.ProcessName) process and logged event"
            }
            else {
                $DateTime = "[$((Get-Date -Format "MM/dd/yy HH:mm:ss"))]"
                "$DateTime INFO: Had to kill the following process (multiple):" | Add-Content $logFile
                "$DateTime Process Name: $($Process.ProcessName)" | Add-Content $logFile
                "$DateTime Process Path: $($Process.Path)" | Add-Content $logFile
                "$DateTime Process Owner: $($ProcessOwner)" | Add-Content $logFile
                $process | Stop-Process -Force
                Write-Host "SUCCESS: Killed $($Process.ProcessName) process and logged event"
            }
        }    
    } #End of checking for valid process
    else {
        Write-Host "ERROR: No such process: $processInput"
    }
} #End of option checking
else {
    Write-Host "ERROR: Invalid option. Please re-run script"
}
