# Copy source code and test files to jumpbox for private deployment
# Run this script locally before connecting to jumpbox

param(
    [string]$LocalSourcePath = ".\src",
    [string]$LocalTestsPath = ".\tests", 
    [string]$TempZipPath = ".\function-app-package.zip"
)

Write-Host "=== Preparing Function App Package for Jumpbox Deployment ===" -ForegroundColor Green

# Check if source exists
if (-not (Test-Path $LocalSourcePath)) {
    Write-Host "❌ Source path not found: $LocalSourcePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $LocalTestsPath)) {
    Write-Host "❌ Tests path not found: $LocalTestsPath" -ForegroundColor Red
    exit 1
}

# Create temporary directory for packaging
$tempDir = Join-Path $env:TEMP "BlobEventProcessor"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "📦 Packaging source code..." -ForegroundColor Cyan

# Copy source files
$sourceDestination = Join-Path $tempDir "src"
Copy-Item $LocalSourcePath $sourceDestination -Recurse -Force
Write-Host "✅ Copied source files" -ForegroundColor Green

# Copy test files  
$testsDestination = Join-Path $tempDir "tests"
Copy-Item $LocalTestsPath $testsDestination -Recurse -Force
Write-Host "✅ Copied test files" -ForegroundColor Green

# Create deployment instructions
$instructionsPath = Join-Path $tempDir "DEPLOYMENT-INSTRUCTIONS.md"
$instructions = @"
# Function App Private Deployment Instructions

## Prerequisites (Install on Jumpbox)
1. Azure CLI: https://aka.ms/installazurecliwindows
2. .NET 8.0 SDK: https://dotnet.microsoft.com/download/dotnet/8.0
3. Node.js: https://nodejs.org/en/download/
4. Azure Functions Core Tools: ``npm install -g azure-functions-core-tools@4 --unsafe-perm true``

## Deployment Steps
1. Extract this package to ``C:\temp\BlobEventProcessor``
2. Open PowerShell as Administrator
3. Login to Azure: ``az login``
4. Navigate to: ``cd C:\temp\BlobEventProcessor\tests``
5. Run deployment: ``.\Deploy-From-Jumpbox.ps1``
6. Run tests: ``.\Private-Mode-Test.ps1``

## Files Included
- ``src\`` - Function App source code (.NET 8.0 isolated)
- ``tests\`` - Test scripts and sample files
- ``Deploy-From-Jumpbox.ps1`` - Deployment script
- ``Private-Mode-Test.ps1`` - End-to-end test script

## Expected Results
- Function App deployed in dotnet-isolated mode
- VNet integration enabled
- Private endpoints active
- Event processing through private network only
"@

Set-Content -Path $instructionsPath -Value $instructions -Encoding UTF8
Write-Host "✅ Created deployment instructions" -ForegroundColor Green

# Create ZIP package
Write-Host "🗜️  Creating ZIP package..." -ForegroundColor Cyan
if (Test-Path $TempZipPath) {
    Remove-Item $TempZipPath -Force
}

# Use .NET compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $TempZipPath)

Write-Host "✅ Package created: $TempZipPath" -ForegroundColor Green

# Cleanup temp directory
Remove-Item $tempDir -Recurse -Force

Write-Host ""
Write-Host "=== Package Ready for Jumpbox Deployment ===" -ForegroundColor Green
Write-Host "📦 Package file: $TempZipPath" -ForegroundColor Yellow
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Connect to Azure Bastion: https://portal.azure.com" -ForegroundColor White
Write-Host "   2. Navigate to: rg-evgblobpvt-westus2 > bas-evgblobpvt-westus2" -ForegroundColor White
Write-Host "   3. Click 'Connect' > RDP > Connect to VM: jumpbox" -ForegroundColor White
Write-Host "   4. Copy $TempZipPath to the jumpbox" -ForegroundColor White
Write-Host "   5. Extract to C:\temp\BlobEventProcessor" -ForegroundColor White
Write-Host "   6. Follow DEPLOYMENT-INSTRUCTIONS.md" -ForegroundColor White
Write-Host ""
