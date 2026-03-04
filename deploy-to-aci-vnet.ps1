# Deploy My Mind to Azure Container Instances with VNet Support
# Prerequisites: Azure CLI installed and logged in (az login)

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerName,
    
    [Parameter(Mandatory=$true)]
    [string]$AcrName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [int]$CpuCores = 1,
    
    [Parameter(Mandatory=$false)]
    [int]$MemoryGb = 1,
    
    [Parameter(Mandatory=$false)]
    [string]$VNetName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubnetName,
    
    [Parameter(Mandatory=$false)]
    [string]$VNetResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [switch]$PrivateOnly
)

Write-Host "Deploying My Mind to Azure Container Instances..." -ForegroundColor Green

# Build and tag the image
$imageName = "$AcrName.azurecr.io/tools/my-mind:latest"
Write-Host "`n1. Building Docker image..." -ForegroundColor Cyan
docker build -t $imageName `
    --build-arg BUILD_DATE=$(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") `
    --build-arg VERSION="latest" `
    .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# Login to ACR
Write-Host "`n2. Logging into Azure Container Registry..." -ForegroundColor Cyan
az acr login --name $AcrName

if ($LASTEXITCODE -ne 0) {
    Write-Host "ACR login failed!" -ForegroundColor Red
    exit 1
}

# Push to ACR
Write-Host "`n3. Pushing image to ACR..." -ForegroundColor Cyan
docker push $imageName

if ($LASTEXITCODE -ne 0) {
    Write-Host "Push failed!" -ForegroundColor Red
    exit 1
}

# Build deployment command
Write-Host "`n4. Deploying to Azure Container Instances..." -ForegroundColor Cyan

$deployCommand = @(
    "az", "container", "create",
    "--resource-group", $ResourceGroup,
    "--name", $ContainerName,
    "--image", $imageName,
    "--os-type", "Linux",
    "--cpu", $CpuCores,
    "--memory", $MemoryGb,
    "--registry-login-server", "$AcrName.azurecr.io",
    "--registry-username", $AcrName,
    "--registry-password", (az acr credential show --name $AcrName --query "passwords[0].value" -o tsv),
    "--ports", "8080",
    "--location", $Location
)

# Add VNet configuration if specified
if ($VNetName -and $SubnetName) {
    Write-Host "Configuring VNet integration..." -ForegroundColor Yellow
    
    # Determine VNet resource group (use container RG if not specified)
    $vnetRg = if ($VNetResourceGroup) { $VNetResourceGroup } else { $ResourceGroup }
    
    # Get subnet ID
    $subnetId = az network vnet subnet show `
        --resource-group $vnetRg `
        --vnet-name $VNetName `
        --name $SubnetName `
        --query id -o tsv
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to get subnet ID. Make sure VNet and subnet exist." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  VNet: $VNetName" -ForegroundColor Gray
    Write-Host "  Subnet: $SubnetName" -ForegroundColor Gray
    Write-Host "  Subnet ID: $subnetId" -ForegroundColor Gray
    
    $deployCommand += "--subnet", $subnetId
    
    # If private only, don't assign public IP
    if ($PrivateOnly) {
        Write-Host "  IP Type: Private only (no public IP)" -ForegroundColor Gray
        $deployCommand += "--ip-address", "Private"
    } else {
        Write-Host "  IP Type: Public and Private" -ForegroundColor Gray
    }
} else {
    # Public deployment with DNS
    Write-Host "Configuring public deployment..." -ForegroundColor Yellow
    $deployCommand += "--dns-name-label", $ContainerName
}

# Execute deployment
& $deployCommand[0] $deployCommand[1..($deployCommand.Length-1)]

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDeployment successful!" -ForegroundColor Green
    
    # Show access information
    $containerInfo = az container show --resource-group $ResourceGroup --name $ContainerName --query "{fqdn:ipAddress.fqdn,ip:ipAddress.ip,ports:ipAddress.ports}" -o json | ConvertFrom-Json
    
    if ($PrivateOnly -or (-not $containerInfo.fqdn)) {
        Write-Host "`nContainer deployed with PRIVATE access only:" -ForegroundColor Cyan
        Write-Host "  Private IP: $($containerInfo.ip)" -ForegroundColor White
        Write-Host "  Port: 8080" -ForegroundColor White
        Write-Host "`nAccess from within VNet:" -ForegroundColor Yellow
        Write-Host "  http://$($containerInfo.ip):8080" -ForegroundColor Cyan
    } else {
        Write-Host "`nAccess your app at:" -ForegroundColor Cyan
        Write-Host "  Public: http://$($containerInfo.fqdn):8080" -ForegroundColor White
        if ($containerInfo.ip) {
            Write-Host "  Private: http://$($containerInfo.ip):8080" -ForegroundColor White
        }
    }
} else {
    Write-Host "Deployment failed!" -ForegroundColor Red
    exit 1
}
