# Script to copy companies teams backgrounds to users %appdata%\Microsoft\Teams\Backgrounds.
# Created by: Remy Kuster
# Website: www.iamsysadmin.eu
# Modified by: Johan Lundström (19-03-2021)
# Creation date: 13-01-2021

# Create variables

$sourcefolder = "\\Your CM server\source$\Applications\Microsoft Teams\Backgrounds" # Set the share and folder where you put the custom backgrounds
$TeamsStarted = "$env:APPDATA\Microsoft\Teams"
$DirectoryBGToCreate = "$env:APPDATA\Microsoft\Teams\Backgrounds"
$Uploadfolder = "$env:APPDATA\Microsoft\Teams\Backgrounds\Uploads"
$Logfile = "$env:LOCALAPPDATA\Logs\BG-copy.log"
$Logfilefolder = "$env:LOCALAPPDATA\Logs"
$MEMCMDetectionFolder = "$env:LOCALAPPDATA\Set-Teams-BG-done"
$MEMCMDetectionFile = "Set-Teams-BG-done.txt"

# Create logfile and function

# Check if %localappdata%\Logs is present, if not create folder and logfile

if (!(Test-Path -LiteralPath $Logfilefolder -PathType container)) 
    {
    
        try 
            {
                New-Item -Path $Logfilefolder -ItemType Directory -ErrorAction Stop | Out-Null #-Force
                New-Item -Path $Logfilefolder -Name "BG-copy.log" -ItemType File -ErrorAction Stop | Out-Null #-Force

                Start-Sleep -s 10

            }

        catch 

            {
                Write-Error -Message "Unable to create directory '$Logfilefolder' . Error was: $_" -ErrorAction Stop    
            }

    "Successfully created directory '$Logfilefolder' ."

    }

else 

    {
        "Directory '$Logfilefolder' already exist"
    }

# Clear the logfile before starting

#Clear-Content $Logfile

# Create the logwrite function

Function LogWrite
{
   Param ([string]$logstring)
   $Stamp = (Get-Date).toString("dd/MM/yyy HH:mm:ss")
    $Line = "$Stamp $logstring"
 
   Add-content $Logfile -value $Line
}

# Check if teams is started once before for current user

if ( (Test-Path -LiteralPath $TeamsStarted) ) 
    { 
        logwrite "Teams started once before by the current user."
    }

else

    {
        logwrite "Teams has never been started by user"
        Exit 1
    }

# Check if %appdata%\Microsoft\Teams\Background is present, if not create folder

if (!(Test-Path -LiteralPath $DirectoryBGToCreate -PathType container)) 
    {
    
        try 
            {
                New-Item -Path $DirectoryBGToCreate -ItemType Directory -ErrorAction Stop | Out-Null #-Force
            }
        catch 
            {
                Write-Error -Message "Unable to create directory '$DirectoryBGToCreate' . Error was: $_" -ErrorAction Stop    
            }

    logwrite "Successfully created directories '$DirectoryBGToCreate' ."
    }

else 
    {
        logwrite "Directory '$DirectoryBGToCreate' already exist"
    }

# Check if %appdata%\Microsoft\Teams\Background\Uploads is present, if not create folder

if (!(Test-Path -LiteralPath $Uploadfolder -PathType container)) 
    {
    
        try 
            {
                New-Item -Path $Uploadfolder -ItemType Directory -ErrorAction Stop | Out-Null #-Force
            }
        catch 
            {
                Write-Error -Message "Unable to create directory '$Uploadfolder' . Error was: $_" -ErrorAction Stop    
            }

     logwrite "Successfully created directories '$Uploadfolder' ."
    }

else 
    {
        logwrite "Directory '$Uploadfolder' already exist"
    }

# Check if machine is connected to your corporate network

#$getoutput = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString # process active IP-address
$getoutput = Get-NetIPAddress -AddressFamily IPv4 | Out-String -stream | Select-String -Pattern "IPAddress" # process IP-address list

# You can multiple adres ranges if your company has got vpn, wireless and physical different subnets. 
# This because we don't want to start the copy action from the share if the device is not connected to the corperate network.

if (($getoutput -like '*192.168.*.*') -or ($getoutput -like '*10.10.*.*') -or ($getoutput -like '*.*.*.*'))

    {
        logwrite "Corporate network detected"
        $connected="YES"
    }
else
    {
        logwrite "Corporate network not detected"
        logwrite "Copy action of uploads folder from share not started"
    #   Exit 1
    }

# copy content from share to teams background location

if($connected -eq "YES")
    {
        logwrite "Start copy action of uploads folder from share"
        $sourcefiles = (Get-ChildItem -Path $sourcefolder -erroraction SilentlyContinue).Name
        
        if($sourcefiles -ne $null)

        {
        
        foreach($sourcefile in $sourcefiles)
            {
                if(!(Test-Path $Uploadfolder\$sourcefile))
                    {
                        Copy-Item -Path $sourcefolder\$sourcefile -Destination $Uploadfolder\$sourcefile -Recurse -Force
                        if(Test-path -Path "$Uploadfolder\$sourcefile")
                            {
                                logwrite "File $sourcefile was copied"
                            }
                        else
                            {
                                logwrite "Failed to copy file $sourcefile"
                                Exit 1
                            }
                    }
                else
                    {
                        logwrite "File $sourcefile already exists"
                    }            
                            
            }
        }

        else

        {
        logwrite "Failed to connect to $sourcefolder "
        }


# Create the folder for MEMCM detection method

        new-item -itemtype "directory" -path $MEMCMDetectionFolder -erroraction SilentlyContinue

   
# Create the txt file for MEMCM detection method

        new-item $MEMCMDetectionFolder\$MEMCMDetectionFile -erroraction SilentlyContinue

                       }

