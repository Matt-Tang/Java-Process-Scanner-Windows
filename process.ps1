##### Initialize variables
$csvpath = ("\\CL11180.sunlifecorp.com\JavaDiscovery\" + $env:computername + "_process.txt")
$keywords_Path = ("C:\JavaProcess\keywords.txt")
$temp1_Path = ("C:\JavaProcess\temp.csv")
$temp2_Path = ("C:\JavaProcess\pid.txt")
$content = Get-Content -Path $keywords_Path
$date=Get-Date

Remove-Item -Force -Path $temp1_Path, $temp2_Path -ErrorAction 'silentlycontinue'
New-Item $temp1_Path -ItemType file -Value "Server,Name,Path,Version,Company,Counter,CommandLine,FirstDiscovered,LastDiscovered`n" | Out-Null
New-Item $temp2_Path -ItemType file | Out-Null

##### Puts keywords in file into array
foreach ($keyword in $content)
{
  $keyword = $keyword -split(',')
}

function Get-Processes {
    $match=0

    for ($i= 0; $i -lt $keyword.Length; $i++)
    {
        if ($keyword[$i] -eq $null) {
            continue
        }

        $processes = Get-WmiObject Win32_Process  | Where-Object {$_.CommandLine -match $keyword[$i]} ## Get all processes where the command line contains one of the keywords
        foreach ($process in $processes)
        {
            if(Get-Content -Path $temp2_Path | Select-String -pattern $process.ProcessId -quiet){
                continue
            }
            elseif ($process.CommandLine -like '*powershell.exe*')
            {
                Add-Content -Path $temp2_Path $process.ProcessId
                continue
            }
            else
            {
                $processObject = New-Object PSObject -Property @{ ## Get process properties
                    Server=$process.__SERVER;
                    Name=$process.ProcessName;
                    Path=$process.Path;
                    Version = (Get-ItemProperty -path $process.Path).VersionInfo.FileVersion;
                    Company = (Get-Process | Where-Object {$_.ID -match $process.ProcessID}).Company
                    Counter = 1;
                    CommandLine = $process.CommandLine; 
                    FirstDiscovered=$date;
                    LastDiscovered=$date;
                }
                                       
                $commandLine= $processObject.CommandLine | Out-String
                $csvObjects = Import-Csv $temp1_Path           

                for ( $j = 0; $j -lt $csvObjects.Length; $j++)
                {
                    $command = $csvObjects[$j].CommandLine | Out-String ## convert to string 
           
                    if ($command -eq $commandLine) { ### Check if command line is found, if yes increase the counter
                        $csvObjects[$j].Counter=([int]$csvObjects[$j].Counter+1).toString()
                        $match=1
                        break
                    }
                }

                if ($match -ne 1 ) {
                        [array]$csvObjects += $processObject      ## If new process then add to storage               
                }

                $csvObjects |
                    Select-Object Server, Name, Path, Version, Company, Counter, CommandLine, FirstDiscovered, LastDiscovered | 
                    Export-Csv -Path $temp1_Path -NoTypeInformation

                Add-Content -Path $temp2_Path $process.ProcessId  ### Add pid to the scanned list already
                $match=0             
            }
        }
        
    }
}

##### Function to create file/fill in information if it does not exist
function Create-FileProcess {
   Copy-Item -Path $temp1_Path -Destination $csvpath
}

##### Function to modify file
function Modify-FileProcess {

    [array]$existing = Import-Csv -Path $csvpath |
                        Select-Object Server, Name, Path, Version, Company, Counter, CommandLine, FirstDiscovered, LastDiscovered
    $found = 0

    Import-CSV -Path $temp1_Path | ForEach-Object {
        
        for ($x = 0 ; $x -lt $existing.Length; $x++)
        {
            if ($_.CommandLine -eq $existing[$x].CommandLine)
            {
                $existing[$x].Counter=(([int]$_.Counter)+([int]$existing[$x].Counter)).toString()  ### Increase counter if command line is found
                $existing[$x].LastDiscovered=$date
                $found = 1
                break
            }
        }

        if ($found -ne 1)
        {
            [array]$existing+=$_
        }

        $found = 0
    }
  
    $existing |
        Select-Object Server, Name, Path, Version, Company, Counter, CommandLine, FirstDiscovered, LastDiscovered | 
        Export-Csv -Path $csvpath -NoTypeInformation
}

############################## Main program ##########################################
##############################
### Matthew Tang           ###   
### Java Discovery Project ###
### November 19th, 2018    ###
##############################

Get-Processes 
################### For running process #######################
if (!(Test-Path $csvpath)) ##### If process file is not created
{
    Write-Host "Creating file"
    Create-FileProcess        
}
elseif (Test-Path $csvpath) ## If process file exists already
{
    Write-Host "Modifiying file"
    Modify-FileProcess 
}
    
Remove-Item -Force -Path $temp1_Path, $temp2_Path -ErrorAction 'silentlycontinue'