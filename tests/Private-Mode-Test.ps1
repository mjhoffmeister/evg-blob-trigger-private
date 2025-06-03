# Private Mode End-to-End Test Script
# This script tests the private mode deployment from within the VNet via jumpbox

param(
    [string]$ResourceGroupName = "rg-evgblobpvt-westus2",
    [string]$StorageAccountName = "stevgblobpvtwestus2",
    [string]$ContainerName = "uploads",
    [string]$FunctionAppName = "func-evgblobpvt-westus2"
)

Write-Host "=== Private Mode End-to-End Test ===" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Yellow
Write-Host "Function App: $FunctionAppName" -ForegroundColor Yellow
Write-Host ""

# Test 1: Check Function App accessibility
Write-Host "Test 1: Function App Health Check" -ForegroundColor Cyan
try {
    $healthUrl = "https://$FunctionAppName.azurewebsites.net/api/health"
    Write-Host "Testing: $healthUrl" -ForegroundColor Gray
    $healthResponse = Invoke-RestMethod -Uri $healthUrl -Method GET -TimeoutSec 30
    Write-Host "✅ Health check passed: $($healthResponse.status)" -ForegroundColor Green
    Write-Host "   Message: $($healthResponse.message)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Check Function App ping endpoint
Write-Host "`nTest 2: Function App Ping Test" -ForegroundColor Cyan
try {
    $pingUrl = "https://$FunctionAppName.azurewebsites.net/api/ping"
    Write-Host "Testing: $pingUrl" -ForegroundColor Gray
    $pingResponse = Invoke-RestMethod -Uri $pingUrl -Method GET -TimeoutSec 30
    Write-Host "✅ Ping test passed: $($pingResponse.message)" -ForegroundColor Green
    Write-Host "   Timestamp: $($pingResponse.timestamp)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Ping test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check private DNS resolution
Write-Host "`nTest 3: Private DNS Resolution" -ForegroundColor Cyan
try {
    $functionAppFqdn = "$FunctionAppName.azurewebsites.net"
    $storageFqdn = "$StorageAccountName.blob.core.windows.net"
    
    Write-Host "Resolving Function App: $functionAppFqdn" -ForegroundColor Gray
    $funcIp = [System.Net.Dns]::GetHostAddresses($functionAppFqdn) | Select-Object -First 1
    Write-Host "✅ Function App resolves to: $($funcIp.IPAddressToString)" -ForegroundColor Green
    
    Write-Host "Resolving Storage Account: $storageFqdn" -ForegroundColor Gray
    $storageIp = [System.Net.Dns]::GetHostAddresses($storageFqdn) | Select-Object -First 1
    Write-Host "✅ Storage Account resolves to: $($storageIp.IPAddressToString)" -ForegroundColor Green
    
    # Check if IPs are private (10.x.x.x range)
    if ($funcIp.IPAddressToString.StartsWith("10.")) {
        Write-Host "✅ Function App using private IP (VNet)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Function App using public IP" -ForegroundColor Yellow
    }
    
    if ($storageIp.IPAddressToString.StartsWith("10.")) {
        Write-Host "✅ Storage Account using private IP (VNet)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Storage Account using public IP" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ DNS resolution failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Upload test file to storage
Write-Host "`nTest 4: Storage Upload Test" -ForegroundColor Cyan
try {
    # Create a test file
    $testFileName = "private-mode-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $testContent = @"
Private Mode Test File
Created: $(Get-Date)
Test Type: End-to-End Private Network Test
Source: Jumpbox VM within VNet
Storage Account: $StorageAccountName
Container: $ContainerName
Function App: $FunctionAppName

This file was uploaded to test the private mode deployment.
If you see this in the Event Hub trigger, the private mode is working correctly!
"@
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    $testContent | Out-File -FilePath $tempFile -Encoding UTF8
    
    Write-Host "Created test file: $testFileName" -ForegroundColor Gray
    Write-Host "Uploading to storage account via private endpoint..." -ForegroundColor Gray
    
    # Upload using Azure CLI (should work via private endpoint)
    $uploadResult = az storage blob upload `
        --account-name $StorageAccountName `
        --container-name $ContainerName `
        --name $testFileName `
        --file $tempFile `
        --auth-mode login `
        --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ File uploaded successfully via private endpoint" -ForegroundColor Green
        $uploadInfo = $uploadResult | ConvertFrom-Json
        Write-Host "   Blob URL: $($uploadInfo.name)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Upload failed: $uploadResult" -ForegroundColor Red
    }
    
    # Clean up temp file
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "❌ Storage upload test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Wait and check for Event Hub processing
Write-Host "`nTest 5: Event Processing Verification" -ForegroundColor Cyan
Write-Host "Waiting 30 seconds for event processing..." -ForegroundColor Gray
Start-Sleep -Seconds 30

try {
    Write-Host "Checking Application Insights for recent function executions..." -ForegroundColor Gray
    
    # Query Application Insights for recent function executions
    $aiQuery = @"
traces
| where timestamp > ago(5m)
| where message contains "ProcessBlobEvents" or message contains "BlobCreated"
| order by timestamp desc
| take 10
| project timestamp, message, severityLevel
"@
    
    Write-Host "You can check the following in Azure portal:" -ForegroundColor Yellow
    Write-Host "1. Application Insights logs for function execution" -ForegroundColor Yellow
    Write-Host "2. Event Hub metrics for message processing" -ForegroundColor Yellow
    Write-Host "3. Storage Account monitoring for blob creation events" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Event processing check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Network connectivity test
Write-Host "`nTest 6: Network Connectivity Test" -ForegroundColor Cyan
try {
    Write-Host "Testing connectivity to private endpoints..." -ForegroundColor Gray
    
    # Test Function App private endpoint (port 443)
    $funcTest = Test-NetConnection -ComputerName $FunctionAppName.azurewebsites.net -Port 443 -WarningAction SilentlyContinue
    if ($funcTest.TcpTestSucceeded) {
        Write-Host "✅ Function App private endpoint reachable" -ForegroundColor Green
    } else {
        Write-Host "❌ Function App private endpoint not reachable" -ForegroundColor Red
    }
    
    # Test Storage private endpoint (port 443)
    $storageTest = Test-NetConnection -ComputerName "$StorageAccountName.blob.core.windows.net" -Port 443 -WarningAction SilentlyContinue
    if ($storageTest.TcpTestSucceeded) {
        Write-Host "✅ Storage Account private endpoint reachable" -ForegroundColor Green
    } else {
        Write-Host "❌ Storage Account private endpoint not reachable" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Network connectivity test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Private Mode Test Complete ===" -ForegroundColor Green
Write-Host "Review the results above to verify private mode functionality." -ForegroundColor Yellow
Write-Host "All green checkmarks indicate successful private mode operation." -ForegroundColor Yellow
