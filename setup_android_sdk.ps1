$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$jdk = "C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot"

$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk
$env:JAVA_HOME = $jdk
$env:PATH = "$jdk\bin;$sdk\cmdline-tools\latest\bin;$sdk\platform-tools;" + $env:PATH

Write-Host "Accepting SDK licenses..."
"y`ny`ny`ny`ny`ny`ny`ny`ny`ny`n" | cmd /c sdkmanager --licenses 2>&1

Write-Host "Installing Android SDK 36 + build-tools 28.0.3..."
cmd /c "sdkmanager ""platform-tools"" ""platforms;android-36"" ""build-tools;28.0.3"" ""build-tools;36.0.0""" 2>&1

Write-Host "SDK_DONE"
