
Param (
    [string]$LogPath = "C:\Windows\Temp\CreateSymLink.Log",
    [string]$FileName = "CMTrace.exe",
    [string]$SourceDir = "$($env:windir)\CCM",
    [string]$DestDir = "$($env:windir)\system32",
    [string]$URL = "https://github.com/AdamGrossTX/cmtrace/raw/main/CMTrace.exe",
    [switch]$RemoveExisting = $True #Remove any non-hardlink file that exists in the dest location
)
Start-Transcript -Path $LogPath -Force -ErrorAction SilentlyContinue

try {
    $OutFile = "$env:TEMP\$FileName"
    $FileExists = Test-Path -Path "$SourceDir\$FileName"

    if(-not $FileExists) {
        $Result = Invoke-WebRequest -UseBasicParsing -Uri $URL -OutFile $OutFile -ErrorAction SilentlyContinue -Verbose
        if (-not $OutFile) {
            Write-Host "Failed to download CMTrace.exe"
            Exit 1
        }
        else {
            Copy-Item -Path $OutFile -Destination "$SourceDir\$FileName" -Force -Verbose
        }
    }

    $SourcePath = Join-Path -Path $SourceDir -ChildPath $FileName
    $DestPath = Join-Path -Path $DestDir -ChildPath $FileName

    $SourceExists = Get-Item $SourcePath -ErrorAction SilentlyContinue
    $DestExists = Get-Item $DestPath -ErrorAction SilentlyContinue

    $HardlinkList = & fsutil hardlink list $SourcePath
    $HardlinkExists = $false
    foreach ($HardLink in $HardLinkList) {
        $Existing = Join-Path -Path $env:SystemDrive -ChildPath $Hardlink
        $HardlinkExists = $Existing -eq $DestPath
        if ($HardlinkExists) { break; }
    }

    if ($HardlinkExists) {
        Write-Host "HardLink already exists. Skipping."
    }
    else {
        #Remove existing file if it already exists but only if the source file exists as well
        if ($SourceExists -and $DestExists -and $RemoveExisting.IsPresent) {
            fsutil hardlink list c:\windows\ccm\cmtrace.exe
            Write-Host "File already exists. Deleting."
            $DestExists | Remove-Item -Force -ErrorAction SilentlyContinue
        }

        if ($SourceExists ) {
            Write-Host "Creating new SymLink"
            $Result = & fsutil hardlink create $DestPath $SourcePath
            Write-Host $Result
        }
    }

    Stop-Transcript -ErrorAction SilentlyContinue
    Write-Host "Completed SymLink"
    return 0
    exit 0
}
catch {
    throw $_
}