# PowerShell Script to Process Audio Files and Display Information
# Define parameters
param (
    [switch]$CSV,
    [string]$CSVPath = "audio_analysis.csv"
)

# Get list of audio files in the current directory
$audioFiles = Get-ChildItem -Path . -Filter "*.wav"

# Determine maximum file name length for dynamic padding
$maxNameLength = ($audioFiles | ForEach-Object {$_.Name.Length} | Measure-Object -Maximum).Maximum

# Ensure the header name is also taken into account
$maxNameLength = [Math]::Max($maxNameLength, "File".Length)


# Define the headers
$headers = @("File","Channels","SampleFmt","SampleRate","BitsPerSample")


# Define the format strings
$consoleHeaderFormat = "{0,-$maxNameLength}`t{1,-10}`t{2,-15}`t{3,-15}`t{4,-15}"
$consoleDataFormat = "{0,-$maxNameLength}`t{1,-10}`t{2,-15}`t{3,-15}`t{4,-15}"

# If CSV output is selected, write headers to CSV
if ($CSV) {
    $headers | Out-File -FilePath $CSVPath -Encoding UTF8
} else {
    # Output headers to the console with padding for alignment
    Write-Host ($consoleHeaderFormat -f $headers)
     Write-Host ($consoleHeaderFormat -f "----","----","----","----","----")
}

# Loop through each audio file
foreach ($audioFile in $audioFiles) {

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
            

            # Output in CSV format
             if ($CSV) {
                "$($audioFile.Name),$channels,$sampleFmt,$sampleRate,$bitsPerSample" | Out-File -FilePath $CSVPath -Encoding UTF8 -Append
                }else {
                # Write data to the console with padded strings
                Write-Host ($consoleDataFormat -f $($audioFile.Name), $channels, $sampleFmt, $sampleRate, $bitsPerSample)
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
if ($CSV){
     Write-Host "Done. Results saved to '$CSVPath'."
} else {
    Write-Host "Done."
}