$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$jdk = "C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot"

$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk
$env:JAVA_HOME = $jdk
$env:PATH = "$jdk\bin;$sdk\cmdline-tools\latest\bin;$sdk\platform-tools;C:\flutter\bin;" + $env:PATH

Write-Host "Building Flutter APK..."
C:\flutter\bin\flutter.bat build apk --release
Write-Host "BUILD_COMPLETE"
