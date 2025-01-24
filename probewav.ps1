# PowerShell Script to Process Audio Files and Display Information

# Get list of audio files in the current directory
$audioFiles = Get-ChildItem -Path . -Filter "*.wav"

# Array to store audio data
$audioData = @()

# Loop through each audio file
foreach ($audioFile in $audioFiles) {
    Write-Host "Processing $($audioFile.Name)..."

    # Extract metadata using ffprobe
    $ffprobeOutput = & ffprobe -v quiet -print_format json -show_streams $audioFile.FullName 2>&1
    $ffprobeOutput = $ffprobeOutput -join "`n"

    # Check if ffprobe succeeded
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ffprobe failed for $($audioFile.Name)"
        continue
    }

    # Parse JSON and handle potential errors more carefully
    try {
        $json = ConvertFrom-Json $ffprobeOutput
        # Ensure json has a streams property
        if (-not $json.streams) {
            throw "No streams found in ffprobe output"
        }

        # Ensure $json.streams is always treated as an array
        if ($json.streams -isnot [System.Array]) {
            $streams = @($json.streams) # Convert to a single-element array
        }
        else {
            $streams = $json.streams
        }

        $stream = $streams | Where-Object {$_.codec_type -eq "audio"} | Select-Object -First 1

        if ($stream) {
            $channels = $stream.channels
            $sampleFmt = $stream.sample_fmt
            $sampleRate = $stream.sample_rate
            $bitsPerSample = $stream.bits_per_sample
            $bitRate = if ($stream.bit_rate) { [int]$stream.bit_rate } else { 0 }

            # Add data to the array
            $audioData += [PSCustomObject]@{
                FileName = $($audioFile.Name)
                Channels = $channels
                SampleFmt = $sampleFmt
                SampleRate = $sampleRate
                BitsPerSample = $bitsPerSample
                BitRate = $bitRate
            }

        } else {
            Write-Error "No audio stream found for $($audioFile.Name)."
            continue
        }
    }
    catch {
        Write-Error "Parsing failed for $($audioFile.Name): $_"
        continue
    }
}

# Sort the data: Mono first, then by bitrate within each channel group
$sortedData = $audioData | Sort-Object @{ Expression = { $_.Channels -eq 1 }; Descending = $false }, BitRate

# Determine maximum file name length for dynamic padding
$maxNameLength = ($sortedData | ForEach-Object { $_.FileName.Length } | Measure-Object -Maximum).Maximum
$maxNameLength = [Math]::Max($maxNameLength, "File".Length)

# Define the headers
$headers = @("File", "Channels", "SampleFmt", "SampleRate", "BitsPerSample")

# Define the format strings
$consoleHeaderFormat = "{0,-$maxNameLength}`t{1,-10}`t{2,-15}`t{3,-15}`t{4,-15}"
$consoleDataFormat = "{0,-$maxNameLength}`t{1,-10}`t{2,-15}`t{3,-15}`t{4,-15}"

# Output headers to the console with padding for alignment
Write-Host ($consoleHeaderFormat -f $headers)
Write-Host ($consoleHeaderFormat -f "----", "----", "----", "----", "----")

# Output the sorted data with blank lines between channel groups
$currentChannel = $null  # Initialize with a null value
foreach ($item in $sortedData) {
    if ($item.Channels -ne $currentChannel) {
        if ($currentChannel -ne $null){ # Don't output a line before the first group
            Write-Host ""  # Output blank line
        }
        $currentChannel = $item.Channels
    }
    Write-Host ($consoleDataFormat -f $($item.FileName), $($item.Channels), $($item.SampleFmt), $($item.SampleRate), $($item.BitsPerSample))
}

Write-Host "Done."