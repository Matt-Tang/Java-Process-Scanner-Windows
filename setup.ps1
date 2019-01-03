﻿### Variable declaration
$path = Split-Path $MyInvocation.MyCommand.Path

$share = "\\CL11180.sunlifecorp.com\JavaDiscovery"
$scriptPath = ($path + "\process.ps1")
$textPath =  ($path + "\keywords.txt")

$storage = "C:\JavaProcess"

if (Test-Path $share)
{
    if (Test-Path $storage){
          Remove-Item -Force -Recurse -Path $storage
    }

    New-Item -Path $storage -ItemType directory | Out-Null
    
    Move-Item -Path "$scriptPath" -Destination $storage | Out-Null
    Move-Item -Path "$textPath" -Destination $storage | Out-Null
	
	Write-Host "Process Script running..."
    & "C:\JavaProcess\process.ps1"
	Write-Host "Process Script done"
    Start-Sleep -s 2
    Write-Host "Task script running..."
    & "$path\task.ps1"
	Write-Host "Task script done"
	
  
}
else
{
    Write-Host "Share folder not available, operation not successful. . ."
}



