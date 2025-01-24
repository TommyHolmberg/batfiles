# PowerShell Script to Process Audio Files and Display Information
# Get list of audio files in the current directory
$audioFiles = Get-ChildItem -Path . -Filter "*.wav"

# Add headers to the output
Write-Host "File`tChannels`tCodec`tSampleRate`tDuration`tBitRate"
Write-Host "----`t----`t----`t----`t----`t----"

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
$codec = $stream.codec_name
$sampleRate = $stream.sample_rate
           # Check that duration and bit rate exist before rounding
if ($stream.duration) {
$duration = [math]::Round($stream.duration, 2)
} else {
$duration = "N/A"
            }
if ($stream.bit_rate) {
$bitRate = $stream.bit_rate
} else {
$bitRate = "N/A"
            }


           # Write the extracted information to the console
Write-Host "$($audioFile.Name)`t$channels`t$codec`t$sampleRate`t$duration`t$bitRate"

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

Write-Host "Done."
