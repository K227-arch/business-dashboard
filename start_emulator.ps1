$emulatorDir = "C:\Users\HP OMEN\AppData\Local\Android\Sdk\emulator"
Set-Location $emulatorDir
Start-Process -FilePath ".\emulator.exe" -ArgumentList "-avd Pixel_9_Pro -gpu host -no-snapshot-load" -WorkingDirectory $emulatorDir

# Wait a bit then move window to visible position
Start-Sleep -Seconds 8
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class WinPos {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc fn, IntPtr lParam);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int x, int y, int w, int h, bool r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    public static void BringToScreen() {
        EnumWindows((hWnd, lParam) => {
            var sb = new StringBuilder(256);
            GetWindowText(hWnd, sb, 256);
            if (sb.ToString().Contains("Pixel_9_Pro")) {
                ShowWindow(hWnd, 9);
                MoveWindow(hWnd, 50, 50, 420, 860, true);
                SetForegroundWindow(hWnd);
            }
            return true;
        }, IntPtr.Zero);
    }
}
"@
[WinPos]::BringToScreen()
