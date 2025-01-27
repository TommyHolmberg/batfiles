#requires -RunAsAdministrator
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Only add the type if it doesn't already exist
if (-not ([System.Management.Automation.PSTypeName]'NativeMethods').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NativeMethods {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetWindowRect(IntPtr hWnd, ref RECT lpRect);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
        int X, int Y, int cx, int cy, uint uFlags);
       
    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);
   
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);
}
"@
}

function Get-OpenWindows {
    Get-Process | Where-Object {$_.MainWindowTitle -ne "" -and $_.MainWindowHandle -ne 0} | 
    Select-Object ProcessName, MainWindowTitle, MainWindowHandle
}


function Move-WindowToMouse {
    param (
        [int]$hwnd,
        [int]$x,
        [int]$y
    )

    Write-Host "DEBUG: Moving window with handle: $hwnd to position X:$x Y:$y"
    
    # Validate window handle first
    if (![NativeMethods]::IsWindow([IntPtr]$hwnd)) {
        Write-Host "Invalid window handle: window may have been closed"
        return
    }
    
    # Check if window is visible
    if (![NativeMethods]::IsWindowVisible([IntPtr]$hwnd)) {
        Write-Host "Window is not visible or may be minimized"
        return
    }
   
    $rect = New-Object NativeMethods+RECT
    $success = [NativeMethods]::GetWindowRect([IntPtr]$hwnd, [ref]$rect)
   
    if (!$success) {
        $lastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Host "DEBUG: Error getting window rect. Last error code: $($lastError)"
        if ($lastError -eq 203) {
            Write-Host "The window you selected cannot be moved. This is due to technical limitations."
            return
        } else {
            Write-Host "An error has occurred, the window cannot be moved."
            return
        }
    }
   
    $windowWidth = $rect.Right - $rect.Left
    $windowHeight = $rect.Bottom - $rect.Top
    Write-Host "DEBUG: Window Rect: Left=$($rect.Left), Top=$($rect.Top), Right=$($rect.Right), Bottom=$($rect.Bottom)"
    Write-Host "DEBUG: Window Width: $($windowWidth), Height: $($windowHeight)"

    # Constants for SetWindowPos
    $SWP_NOSIZE = 0x0001
    $HWND_TOPMOST = New-Object -TypeName IntPtr -ArgumentList (-1) # Makes window topmost
    
    # Adjust the Y-coordinate to place the center of the title bar under the cursor
    $titleBarHeight = 30  # Approximate height of the title bar, adjust if necessary
    $newX = $x - ($windowWidth / 2)
    $newY = $y - $titleBarHeight/2
    
    $success = [NativeMethods]::SetWindowPos(
        [IntPtr]$hwnd, 
        $HWND_TOPMOST,  # Changed from [IntPtr]::Zero to make it topmost
        $newX, 
        $newY, 
        0, 
        0, 
        $SWP_NOSIZE  # Removed NOZORDER flag to allow z-order changes
    )
    
    if (!$success) {
        $lastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Host "DEBUG: Error setting window position. Last error code: $($lastError)"
    }
}

function Select-Window {
    param (
        [string]$title = "Select a Window"
    )
    $openWindows = Get-OpenWindows
    if ($openWindows.Count -eq 0) {
        Write-Host "No open windows found."
        return $null
    }
    Write-Host "Open Windows:"
    for ($i=0; $i -lt $openWindows.Count; $i++) {
        Write-Host "$($i+1). $($openWindows[$i].MainWindowTitle)  `t $($openWindows[$i].ProcessName)"
    }
    while ($true) {
        try {
            $selection = Read-Host "`nSelect a window number"
            $selection = [int]$selection - 1
            if ($selection -ge 0 -and $selection -lt $openWindows.count) {
                Write-Host "DEBUG: (Select-Window func) Selected window hwnd: $($openWindows[$selection].MainWindowHandle)"
                return $openWindows[$selection]
            } else {
                Write-Host "Invalid selection, try again."
            }
        } catch {
            Write-Host "Invalid input, try again."
        }
    }
}

function Get-MousePosition {
    $cursor = [System.Windows.Forms.Cursor]::Position
    return @{ X = $cursor.X; Y = $cursor.Y }
}

# Function to check if the script is running as administrator
function Is-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check for admin rights. if not admin, elevate and exit.
if (-not (Is-Admin)) {
    Write-Host "Script requires administrator privileges. Requesting elevation..."
    try {
        Start-Process powershell.exe -Verb runas -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    } catch {
        Write-Host "Failed to elevate. Please run the script as an administrator."
        return
    }
}

# Start of script logic
$selectedWindow = Select-Window
if (!$selectedWindow) {
    Write-Host "No window selected. Exiting."
    return
}
Write-Host "DEBUG: (main) Selected window hwnd: $($selectedWindow.MainWindowHandle)"

# Get current mouse position
$mousePos = Get-MousePosition
Write-Host "DEBUG: Mouse position: X=$($mousePos.X), Y=$($mousePos.Y)"

if ($selectedWindow.MainWindowHandle) {
    Write-Host "Moving '$($selectedWindow.MainWindowTitle)' to mouse position..."

     # Restore if minimized, then maximize
    $SW_RESTORE = 9  # Constant for restoring a minimized window
     if ([NativeMethods]::IsIconic([IntPtr]$selectedWindow.MainWindowHandle)){
         [NativeMethods]::ShowWindow([IntPtr]$selectedWindow.MainWindowHandle, $SW_RESTORE) | Out-Null
           Write-Host "Window restored."
     }
    Move-WindowToMouse -hwnd $selectedWindow.MainWindowHandle -x $mousePos.X -y $mousePos.Y
    
} else {
    Write-Host "No valid window handle found."
}