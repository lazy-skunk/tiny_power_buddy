class FileManager {
    [string]$sourcePath
    [string]$destinationPath

    FileManager([string]$sourcePath, [string]$destinationPath) {
        $this.sourcePath = $sourcePath
        $this.destinationPath = $destinationPath
    }

    [array] GetFilesUpdatedTodayRecursively() {
        $todayStart = [datetime]::Today
        $todayEnd = $todayStart.AddDays(1)

        $allFiles = Get-ChildItem -Path $this.sourcePath -Recurse | Where-Object { -not $_.PSIsContainer }

        $filesUpdatedToday = @()
        foreach ($file in $allFiles) {
            if ($file.LastWriteTime -ge $todayStart -and $file.LastWriteTime -lt $todayEnd) {
                $filesUpdatedToday += $file
            }
        }

        return $filesUpdatedToday
    }

    [void] CopyFilesToDestinationWithStructure([array]$files) {
        foreach ($file in $files) {
            $relativeFilePath = $file.FullName.Substring($this.sourcePath.Length).TrimStart('\')
            $destinationFileFullPath = Join-Path -Path $this.destinationPath -ChildPath $relativeFilePath

            $DestinationDirPath = [System.IO.Path]::GetDirectoryName($destinationFileFullPath)
            if (-not (Test-Path -Path $DestinationDirPath)) {
                New-Item -ItemType Directory -Path $DestinationDirPath
            }

            Copy-Item -Path $file.FullName -Destination $destinationFileFullPath -Force
        }
    }

    [void] Main() {
        $filesUpdatedToday = $this.GetFilesUpdatedTodayRecursively()
        $this.CopyFilesToDestinationWithStructure($filesUpdatedToday)

        if ($filesUpdatedToday.Count -gt 0) {
            Write-Host "$($filesUpdatedToday.Count) files were updated today and copied to the destination folder: $($this.destinationPath)!!!"
        } else {
            Write-Host "No files were updated today."
        }
    }
}

$sourcePath = Get-Location
$destinationPath = [System.Environment]::GetFolderPath('Desktop')

$fileManager = [FileManager]::new($sourcePath, $destinationPath)
$fileManager.Main()