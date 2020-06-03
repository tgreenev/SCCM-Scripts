Start-Transcript C:\Logs\sccm-col.txt
# Site configuration
$SiteCode = "SCCM" # Site code 
$ProviderMachineName = "SCCMSITE.COMPANY.COM" # SMS Provider machine name

# Customizations
$initParams = @{ }
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if ($null -eq (Get-Module ConfigurationManager)) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if ($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

$AllApps = Get-CMApplication -Fast | Select-Object -ExpandProperty LocalizedDisplayName
#Get all collections that have certain strings, wildcards will work
$CollectionArray = Get-CMCollection -name '*collection name string here*' -ForceWildcardHandling | Select-Object -ExpandProperty name
#Get app name in each collection
foreach ($currentCol in $CollectionArray) {
    $Collectionapps = Get-CMDeployment -CollectionName $currentCol | Select-Object -ExpandProperty ApplicationName
    #Sets up array for applications
    $obj = @()
    #This script is design to find apps and format it based off the following format:
    #"DEP - App Name - Version"
    #ex: "FIN - SQL Browser - 19.2"
    foreach ($app in $collectionapps) { 
        $split = $app -split (' - ')
        #We need to use a key/value pair for name and version
        #so we are going to use .NET to convert the numbers
        #powershell's version type
        #Need to check to see if apps in collection has an update in all apps
        #You may want to change this depending on how your apps are named
        $matchingapps = $AllApps | Where-Object { $_ -like "DEP - $($split[1]) -*" } 
        if ($matchingapps.count -eq 1) {
            $Obj += New-Object -TypeName PSobject -Property @{
                Name        = "$($split[1])"
                Version     = [System.Version]::Parse($($split[2]))
                DisplayName = $matchingapps
            }
        }
        else {
            foreach ($matchingapp in $matchingapps) {
                $splitmatch = $matchingapp -split (' - ')
                $Obj += New-Object -TypeName PSobject -Property @{
                    Name        = "$($splitmatch[1])"
                    Version     = [System.Version]::Parse($($splitmatch[2]))
                    DisplayName = $matchingapp
                }
            }
        }
    }

    #This Groups all the unique objects. If there are multiple versions for
    #one app, it will be in this group
    $GroupObj = $obj | Group-Object -Property name | Where-Object Count -gt 1
    #The highest var contains the newest version only
    $highest = @()
    $everythingElse = @()
    #This is the tricky part, but what makes it work. We will loop through each group of apps (Matlab, Ansys, etc),
    #Then within each group, there is a set of versions (2019, 2020, etc)
    #We are sorting in desecneindg order so the highest version is always at the top
    # Then we throw everything else in the the other var
    foreach ($group in $GroupObj) {
        for ($i = 0; $i -lt $Group.Group.Count; $i++) {
            if ($i -eq 0) { $highest += ($Group.Group | Sort-Object Version -Descending)[0] }
            else { $everythingElse += $($Group.Group | Sort-Object Version -Descending)[$i] }
        }
    }
    #Now that we have our apps separated, we can add the new version of apps, and then remove the 
    #older version of apps. You will get errors as most apps are already deployed, but the script
    #will still continue. The  Start-CMContentDistribution cmdlet will most likely always throw
    #errors if you deployed an app before. Again, no need to worry as the script will still continue

    foreach ($finalHighApp in $highest) {
        Start-CMContentDistribution -DistributionPointGroupName DP1 -ApplicationName $finalHighApp.DisplayName -ErrorAction SilentlyContinue
        Write-Host "adding $($finalHighApp.displayname)"
        New-CMApplicationDeployment -Name $finalHighApp.DisplayName -CollectionName $currentCol -DeployAction Install -DeployPurpose Required -UserNotification HideAll -RebootOutsideServiceWindow $true
    }
    foreach ($finalElseApp in $everythingElse) {
        Write-Host "removing $($finalElseApp.displayname)"
        Remove-CMApplicationDeployment -Name $finalElseApp.DisplayName -CollectionName $currentCol -Force
    }
}
Stop-Transcript
