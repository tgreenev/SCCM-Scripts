Param(
    [Parameter(Mandatory = $True)]
    [AllowEmptyString()]
    [string]$ServiceName,
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$option = 'Status'
)
$ServiceOption = $option.ToLower()
#Error checking
$matchParam = "^restart|manual|disable|automatic|status|stop|start$"
#This will start off true. The moment something doesn't match the above, it 
#will convert to false and exit the script
[bool]$runInvoke = $true
if (-not $ServiceName) { $runInvoke = $false }
if ($ServiceOption -notmatch $matchParam) { $runInvoke = $false }

if ($runInvoke -eq $true) {
    $ServiceObj = Get-Service *$($ServiceName)*
    #This checks to see if the service name from the parameters is actually a true service
    #We also don't want to try to pull multiple services
    if (($null -ne $ServiceObj) -and ($ServiceObj.GetType().BaseType.Name -notlike "*Array*")) {


        #This is used to get the path
        $ServicePath = Get-WmiObject win32_service | Where-Object { $_.Name -like "*$($ServiceName)*" } | Select-Object -ExpandProperty PathName

        #These if/elseif statements are designed to only perform one fuction at time
        #For example there would be no need to set a type to Disable and Automatic

        if ($ServiceOption -eq 'start') {
            if ($ServiceObj.StartType -ne 'Disabled') { 
                Start-Service $ServiceObj
                Write-Host "SUCCESS: Started $($ServiceObj.Name) service"
            }
            else {
                Write-Host "ERROR: Unable to start $($ServiceObj.Name) as the startup is DISABLED"
            }
            continue
        }
        
        if ($ServiceOption -eq 'stop') {
            Stop-Service $ServiceObj
            Write-Host "SUCCESS: Stopped $($ServiceObj.Name) service"
            continue
        }
        
        #Service Status code
        if ($ServiceOption -eq "status") {
            $output = @"
Service Name: $($ServiceObj.Name)
Service Status: $($ServiceObj.Status)
Service Startup Type: $($ServiceObj.StartType)
Service Path: $($ServicePath)
"@
            Write-Host $output
        }
        elseif ($ServiceOption -eq "restart") {
            if ($ServiceObj.StartType -ne 'Disabled') { 
                $ServiceObj | Stop-Service
                $ServiceObj | Start-Service
                Write-Host "SUCCESS: Restarted $($ServiceObj.Name) service"
            }
            else {
                Write-Host "ERROR: Unable to restart $($ServiceObj.Name) as the startup is DISABLED"
 
            }
        }
        else {
            Set-Service $ServiceObj.Name -StartupType $ServiceOption
            Write-Host "SUCCESS: Set $($ServiceObj.name) to $ServiceOption"
        }
    }
    else {
        Write-Host "The serivce ($($ServiceName)) is not installed or more than one service was found"
    }
}
else {
    Write-Host "You have entered invalid input. Please re-run script"
}
