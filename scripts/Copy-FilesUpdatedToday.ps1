class FileManager {
    [string]$sourcePath
    [string]$destinationPath

    FileManager([string]$sourcePath, [string]$destinationPath) {
        if (-Not (Test-Path -Path $sourcePath -PathType Container)) {
            throw "The source directory '$sourcePath' does not exist."
        }
        if (-Not (Test-Path -Path $destinationPath -PathType Container)) {
            throw "The destination directory '$destinationPath' does not exist."
        }

        $this.sourcePath = $sourcePath
        $this.destinationPath = $destinationPath
    }

    [array] GetFilesUpdatedTodayRecursively() {
        try {
            $todayStart = [datetime]::Today
            $todayEnd = $todayStart.AddDays(1)

            $allFiles = Get-ChildItem -Path $this.sourcePath -Recurse -ErrorAction Stop | Where-Object { -not $_.PSIsContainer }

            $filesUpdatedToday = @()
            foreach ($file in $allFiles) {
                if ($file.LastWriteTime -ge $todayStart -and $file.LastWriteTime -lt $todayEnd) {
                    $filesUpdatedToday += $file
                }
            }

            return $filesUpdatedToday
        }
        catch {
            throw "An error occurred while retrieving files: $_"
        }
    }

    [void] CopyFilesToDestinationWithStructure([array]$files) {
        try {
            foreach ($file in $files) {
                $relativeFilePath = $file.FullName.Substring($this.sourcePath.Length).TrimStart('\')
                $destinationFileFullPath = Join-Path -Path $this.destinationPath -ChildPath $relativeFilePath

                $destinationDirPath = [System.IO.Path]::GetDirectoryName($destinationFileFullPath)
                if (-not (Test-Path -Path $destinationDirPath)) {
                    New-Item -ItemType Directory -Path $destinationDirPath -ErrorAction Stop
                }

                Copy-Item -Path $file.FullName -Destination $destinationFileFullPath -Force -ErrorAction Stop
            }
        }
        catch {
            throw "An error occurred while copying files: $_"
        }
    }

    [void] Main() {
        try {
            Write-Host "Source Path: $($this.sourcePath)" -ForegroundColor Cyan
            Write-Host "Destination Path: $($this.destinationPath)" -ForegroundColor Cyan
            Write-Host "Note: Files in the destination with the same name will be overwritten." -ForegroundColor Yellow

            $confirmation = ""
            while ($confirmation -ne "yes" -and $confirmation -ne "no") {
                $confirmation = Read-Host "Do you want to start the process of copying files updated today to the destination folder? (yes/no)"
                if ($confirmation -ne "yes" -and $confirmation -ne "no") {
                    Write-Host "Please enter 'yes' or 'no'." -ForegroundColor Red
                }
            }
            
            if ($confirmation -eq "yes") {
                $filesUpdatedToday = $this.GetFilesUpdatedTodayRecursively()
                $this.CopyFilesToDestinationWithStructure($filesUpdatedToday)

                if ($filesUpdatedToday.Count -gt 0) {
                    Write-Host "$($filesUpdatedToday.Count) files were updated today and copied to the destination folder: $($this.destinationPath)" -ForegroundColor Green
                }
                else {
                    Write-Host "No files were updated today." -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "Process cancelled by the user." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "An error occurred during execution: $_"
        }
    }
}

try {
    $sourcePath = Get-Location
    $destinationPath = [System.Environment]::GetFolderPath('Desktop')

    $fileManager = [FileManager]::new($sourcePath, $destinationPath)
    $fileManager.Main()
}
catch {
    Write-Error "An error occurred during initialization: $_"
}
