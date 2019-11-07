Param(
    [Parameter(Mandatory = $True)]
    [AllowEmptyString()]
    [string]$option,
    [AllowEmptyString()]
    [string]$time,
    [AllowEmptyString()]
    [string]$msg
)
#If time is null, default will be 10mins
if (-not $time) { $time = "600" }
#Will display time in hh:mm:ss format
$ts = [timespan]::fromseconds($time)
#If time is less than hour, we will drop off the hh part
if ($ts.Hours -le 0) { $displayTime = ("{0:mm\:ss}" -f $ts) }
else { $displayTime = ("{0:hh\:mm\:ss}" -f $ts) }

#The series of statements will check for the option and if a msg is present
if (($option -ceq "SHUTDOWN") -or ($option -eq "restart")) {
    #This will evaulate only when option is shutdown and message if present
    if (($option -ceq "SHUTDOWN") -and ($msg)) {
        & C:\windows\System32\msg.exe * /TIME:$($time) "$msg`nShutting down in $displayTime"
        Start-Sleep -Seconds $time
        Stop-Computer -Force
    }
    #Will evaluate only if option is shutdown
    if (($option -ceq "SHUTDOWN") -and (-not $msg)) {
        $msg = "This computer will be shutting down in $displayTime"
        & C:\windows\System32\msg.exe * /TIME:$($time) $msg
        Start-Sleep -Seconds $time
        Stop-Computer -Force
    }
    #Same as above, but only for restarting
    if (($option -eq "restart") -and ($msg)) {
        & C:\windows\System32\msg.exe * /TIME:$($time) "$msg`nRestarting in $displayTime"
        Start-Sleep -Seconds $time
        Restart-Computer -Force 
    }
    if (($option -ceq "restart") -and (-not $msg)) {
        $msg = "This computer will be restarting in $displayTime"
        & C:\windows\System32\msg.exe * /TIME:$($time) $msg
        Start-Sleep -Seconds $time
        Restart-Computer -Force
    }
}
else {
    Write-Host "You have entered an invalid option. Please re-run script."
}
