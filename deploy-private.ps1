# Quick Deploy to Private VNet (Customize for your environment)
# Update the defaults below to match your Azure environment

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerName
)

$params = @{
    ResourceGroup = $ResourceGroup
    ContainerName = $ContainerName
    AcrName = "your-acr-name"         # ← CHANGE THIS to your ACR name
    VNetName = "your-vnet-name"       # ← CHANGE THIS to your VNet name
    SubnetName = "your-subnet-name"   # ← CHANGE THIS to your subnet name (must be delegated to ACI)
    VNetResourceGroup = "your-vnet-rg"   # ← CHANGE THIS if your VNet is in a different resource group
    PrivateOnly = $true
    Location = "eastus"               # ← CHANGE THIS to your region if needed
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Quick Deploy - Private VNet" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VNet: $($params.VNetName)" -ForegroundColor White
Write-Host "VNet RG: $($params.VNetResourceGroup)" -ForegroundColor White
Write-Host "Subnet: $($params.SubnetName)" -ForegroundColor White
Write-Host "Container RG: $ResourceGroup" -ForegroundColor White
Write-Host "Access: Private only (no public IP)" -ForegroundColor White
Write-Host ""
Write-Host "Note: To configure DNS, run setup-dns.ps1 after deployment" -ForegroundColor DarkGray
Write-Host ""

# Deploy container
& "$PSScriptRoot\deploy-to-aci-vnet.ps1" @params