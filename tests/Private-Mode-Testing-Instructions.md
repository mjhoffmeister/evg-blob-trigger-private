# Private Mode Testing Instructions

## Overview
This guide walks you through testing the private mode deployment using the Azure Bastion and jumpbox VM to verify that all services are working correctly within the private network.

## Prerequisites
- Private mode infrastructure deployed successfully
- Azure portal access
- Web browser

## Connection Information
- **Bastion Host**: `bas-evgblobpvt-westus2`
- **Bastion Public IP**: `4.246.99.139`
- **Jumpbox VM**: `vm-jumpbox-evgblobpvt-westus2`
- **Computer Name**: `jumpbox`
- **Admin Username**: `azureuser`
- **Resource Group**: `rg-evgblobpvt-westus2`

## Step 1: Connect to Jumpbox via Azure Bastion

1. **Open Azure Portal**: Navigate to [portal.azure.com](https://portal.azure.com)

2. **Find the Virtual Machine**:
   - Search for "vm-jumpbox-evgblobpvt-westus2"
   - Or navigate to Resource Group `rg-evgblobpvt-westus2` and find the VM

3. **Connect via Bastion**:
   - Click on the VM name
   - Click **"Connect"** → **"Connect via Bastion"**
   - Enter credentials:
     - **Username**: `azureuser`
     - **Password**: `[Your password from terraform.tfvars.private]`
   - Click **"Connect"**

4. **Wait for Connection**: Azure Bastion will open a new browser tab with the remote desktop session

## Step 2: Prepare the Jumpbox Environment

Once connected to the jumpbox VM:

1. **Open PowerShell as Administrator**:
   - Click Start → Search for "PowerShell"
   - Right-click → "Run as Administrator"

2. **Install Azure CLI** (if not already installed):
   ```powershell
   # Download and install Azure CLI
   Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
   Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
   
   # Restart PowerShell to refresh PATH
   ```

3. **Login to Azure**:
   ```powershell
   az login
   ```
   Follow the device login flow in the browser.

4. **Set the subscription**:
   ```powershell
   az account set --subscription "c94297dc-12b3-40c7-a773-64846b40a34c"
   ```

## Step 3: Download and Run the Test Script

1. **Create test directory**:
   ```powershell
   New-Item -ItemType Directory -Path "C:\PrivateModeTest" -Force
   Set-Location "C:\PrivateModeTest"
   ```

2. **Download the test script**:
   ```powershell
   # Copy the test script content (you'll need to manually copy from local machine)
   # Or create the script manually in PowerShell ISE
   ```

3. **Create the test script**:
   ```powershell
   # Open PowerShell ISE
   powershell_ise.exe
   
   # Copy the Private-Mode-Test.ps1 content and save as:
   # C:\PrivateModeTest\Private-Mode-Test.ps1
   ```

## Step 4: Run the Private Mode Test

1. **Execute the test script**:
   ```powershell
   Set-Location "C:\PrivateModeTest"
   .\Private-Mode-Test.ps1
   ```

2. **Review the test results**:
   - ✅ Green checkmarks indicate successful private mode operation
   - ❌ Red X marks indicate issues that need investigation
   - ⚠️ Yellow warnings indicate items to review

## Step 5: Manual Verification Tests

### Test Function App Endpoints
```powershell
# Test health endpoint
Invoke-RestMethod -Uri "https://func-evgblobpvt-westus2.azurewebsites.net/api/health"

# Test ping endpoint
Invoke-RestMethod -Uri "https://func-evgblobpvt-westus2.azurewebsites.net/api/ping"
```

### Test DNS Resolution
```powershell
# Check Function App DNS
nslookup func-evgblobpvt-westus2.azurewebsites.net

# Check Storage Account DNS
nslookup stevgblobpvtwestus2.blob.core.windows.net
```

### Upload Test File
```powershell
# Create test file
"Test from jumpbox $(Get-Date)" | Out-File -FilePath "test-private-mode.txt"

# Upload to storage
az storage blob upload `
  --account-name "stevgblobpvtwestus2" `
  --container-name "uploads" `
  --name "test-private-mode.txt" `
  --file "test-private-mode.txt" `
  --auth-mode login
```

## Step 6: Monitor Event Processing

1. **Check Application Insights**:
   - Navigate to Application Insights `appi-evgblobpvt-westus2` in Azure portal
   - Go to **Logs** and run:
   ```kusto
   traces
   | where timestamp > ago(10m)
   | where message contains "ProcessBlobEvents"
   | order by timestamp desc
   ```

2. **Check Event Hub Metrics**:
   - Navigate to Event Hub `evhns-evgblobpvt-westus2`
   - Check **Metrics** for incoming messages

3. **Check Function App Logs**:
   - Navigate to Function App `func-evgblobpvt-westus2`
   - Go to **Monitor** → **Logs**

## Expected Results

### Successful Private Mode Indicators:
- ✅ Function App resolves to private IP (10.0.1.5)
- ✅ Storage Account resolves to private IP (10.0.1.4)
- ✅ HTTP endpoints return successful responses
- ✅ File uploads succeed via private endpoints
- ✅ Event processing continues to work
- ✅ Application Insights receives telemetry

### Private IP Addresses:
- **Function App Private Endpoint**: `10.0.1.5`
- **Storage Account Private Endpoint**: `10.0.1.4`
- **Jumpbox VM**: `10.0.5.4`

## Troubleshooting

### If DNS resolution fails:
1. Check private DNS zone configuration
2. Verify DNS zone links to VNet
3. Restart network services on jumpbox

### If endpoints are unreachable:
1. Verify private endpoints are created
2. Check NSG rules
3. Confirm VNet integration is working

### If uploads fail:
1. Check storage account network rules
2. Verify RBAC permissions
3. Confirm service endpoints are configured

## Security Verification

To confirm private mode is working:

1. **Try accessing from public internet** (should fail):
   ```bash
   # From your local machine (outside VNet) - should fail
   curl https://func-evgblobpvt-westus2.azurewebsites.net/api/health
   ```

2. **From jumpbox** (should succeed):
   ```powershell
   # From within VNet - should succeed
   Invoke-RestMethod -Uri "https://func-evgblobpvt-westus2.azurewebsites.net/api/health"
   ```

This confirms that the services are only accessible from within the private network!
