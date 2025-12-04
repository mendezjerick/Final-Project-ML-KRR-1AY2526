param(
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

if ($Clean) {
    if (Test-Path "download_app/build") {
        try { Remove-Item "download_app/build" -Recurse -Force -ErrorAction Stop }
        catch { Write-Warning "Could not delete 'download_app/build': $_" }
    }
    if (Test-Path "download_app/dist") {
        try { Remove-Item "download_app/dist" -Recurse -Force -ErrorAction Stop }
        catch { Write-Warning "Could not delete 'download_app/dist' (close ShuRiceApp.exe if running): $_" }
    }
}

$pyinstaller = "pyinstaller"

function Add-DataArg($relativePath, $bundleTarget) {
    $src = Resolve-Path $relativePath
    return @("--add-data", "$($src.Path);$bundleTarget")
}

$dataArgs = @()
$dataArgs += Add-DataArg "data/rice.csv" "data"
$dataArgs += Add-DataArg "src/backgrounds" "src/backgrounds"
$dataArgs += Add-DataArg "src/icons" "src/icons"
if (Test-Path "models") {
    $dataArgs += Add-DataArg "models" "models"
}
$dataArgs += Add-DataArg "src/web" "src/web"

$arguments = @(
    "--noconsole",
    "--onefile",
    "--name", "ShuRiceApp",
    "--paths", "src",
    "--distpath", "download_app/dist",
    "--workpath", "download_app/build",
    "--icon", (Resolve-Path "src/icons/shu.ico").Path,
    "--collect-all", "PySide6",
    "--copy-metadata", "PySide6"
)
$arguments += $dataArgs
$arguments += "app.py"

Write-Host "Running: $pyinstaller $arguments"
& $pyinstaller @arguments
