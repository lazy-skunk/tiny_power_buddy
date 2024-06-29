class ItemSizeMeasurer {
    [string]$targetDirectory
    [string]$outputFilePath
    [int]$batchSize

    ItemSizeMeasurer([string]$targetDirectory, [string]$outputFilePath, [int]$batchSize) {
        if (-Not (Test-Path -Path $targetDirectory -PathType Container)) {
            throw "The directory '$targetDirectory' does not exist."
        }
        $this.targetDirectory = $targetDirectory
        $this.outputFilePath = $outputFilePath
        $this.batchSize = $batchSize

        $this.InitializeCsvFile()
    }

    [void] InitializeCsvFile() {
        try {
            "Type,Path,SizeGB,SizeMB" | Out-File -FilePath $this.outputFilePath -Encoding utf8BOM
        }
        catch {
            throw "Failed to initialize CSV file: $_"
        }
    }

    [void] MeasureAndLogItemSizes($items, [string]$itemType) {
        $batch = @()
        $totalItemsCount = $items.Count
        $processedItemsCount = 0

        foreach ($item in $items) {
            $processedItemsCount++
            $itemSize = $this.GetItemSize($item, $itemType)
            $batch += [PSCustomObject]@{
                Type   = $itemType
                Path   = $item.FullName
                SizeGB = $itemSize.SizeGB
                SizeMB = $itemSize.SizeMB
            }

            if ($processedItemsCount % $this.batchSize -eq 0) {
                $this.LogItemSizes($batch)
                $this.ShowProgress($processedItemsCount, $totalItemsCount, $itemType)
                $batch = @()
            }
        }
        
        if ($batch.Count -gt 0) {
            $this.LogItemSizes($batch)
        }
    }

    [PSCustomObject] GetItemSize($item, [string]$itemType) {
        $sizeInBytes = 0
        try {
            if ($itemType -eq "File") {
                $sizeInBytes = $item.Length
            }
            elseif ($itemType -eq "Directory") {
                $sizeInBytes = (Get-ChildItem -Path $item.FullName -Recurse -File -ErrorAction Stop | Measure-Object -Property Length -Sum).Sum
            }
        }
        catch {
            Throw "Error calculating size for $($item.FullName): $_"
        }

        return [PSCustomObject]@{
            SizeGB = [math]::Round($sizeInBytes / 1GB, 1)
            SizeMB = [math]::Round($sizeInBytes / 1MB, 1)
        }
    }
    
    [void] LogItemSizes($batch) {
        try {
            $batch | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Out-File -FilePath $this.outputFilePath -Encoding utf8BOM -Append
        }
        catch {
            throw "Error writing batch to file: $_"
        }
    }
    
    [void] ShowProgress([int]$currentItemCount, [int]$totalItemCount, [string]$itemType) {
        $percentComplete = ($currentItemCount / $totalItemCount) * 100
        Write-Progress -Activity "Calculating $itemType sizes" -Status "$currentItemCount of $totalItemCount $itemType(s)" -PercentComplete $percentComplete
    }

    [void] Main() {
        try {
            $items = Get-ChildItem -Path $this.targetDirectory -Recurse -ErrorAction Stop
            $files = $items | Where-Object { -Not $_.PSIsContainer }
            $directories = $items | Where-Object { $_.PSIsContainer }
    
            $this.MeasureAndLogItemSizes($files, "File")
            $this.MeasureAndLogItemSizes($directories, "Directory")
        }
        catch {
            Write-Error "An error occurred during execution: $_"
        }
    }
}


try {
    $directory = "/mnt/tiny_power_buddy"
    $outputFile = "sizes.csv"
    $batchSize = 100
    
    $measurer = [ItemSizeMeasurer]::new($directory, $outputFile, $batchSize)
    $measurer.Main()
}
catch{
    Write-Error "An error occurred during initialization: $_"
}