$ErrorActionPreference = "Stop"

$info = Get-Content -Raw -Path "info.json" | ConvertFrom-Json
$modName = $info.name
$version = $info.version
$folderName = "${modName}_${version}"
$distDir = "dist"
$stageRoot = Join-Path $distDir "stage"
$stageModDir = Join-Path $stageRoot $folderName
$zipPath = Join-Path $distDir "${folderName}.zip"

$excludeDirs = @(".git", ".github", "dist")
$excludeFiles = @("package.ps1", "package.sh")

if (Test-Path $distDir) {
    Remove-Item -Recurse -Force $distDir
}

New-Item -ItemType Directory -Force -Path $stageModDir | Out-Null

Get-ChildItem -Force | Where-Object {
    ($excludeDirs -notcontains $_.Name) -and ($excludeFiles -notcontains $_.Name)
} | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $stageModDir -Recurse -Force
}

Compress-Archive -Path (Join-Path $stageRoot $folderName) -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $stageRoot

Write-Host "Created $zipPath"
