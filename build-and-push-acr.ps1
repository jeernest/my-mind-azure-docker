# Build and push My Mind image to Azure Container Registry
# Usage: .\build-and-push-acr.ps1 [-AcrName your-acr-name] [-ImageTag latest]

param(
    [Parameter(Mandatory=$false)]
    [string]$AcrName = "your-acr-name",  # ← CHANGE THIS to your ACR name
    
    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "latest",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipLogin
)

$ErrorActionPreference = "Stop"

$fullImageName = "$AcrName.azurecr.io/tools/my-mind:$ImageTag"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Building and Pushing My Mind to ACR" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "ACR: $AcrName.azurecr.io" -ForegroundColor White
Write-Host "Image: tools/my-mind:$ImageTag" -ForegroundColor White
Write-Host ""

# Step 1: Build the image
Write-Host "[1/3] Building Docker image..." -ForegroundColor Green
docker build -t $fullImageName `
    --build-arg BUILD_DATE=$(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") `
    --build-arg VERSION=$ImageTag `
    .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green
Write-Host ""

# Step 2: Login to ACR (if not skipped)
if (-not $SkipLogin) {
    Write-Host "[2/3] Logging into Azure Container Registry..." -ForegroundColor Green
    az acr login --name $AcrName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ ACR login failed!" -ForegroundColor Red
        Write-Host "Tip: Make sure you're logged in with 'az login' and have access to the ACR" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✅ Logged in successfully!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[2/3] Skipping ACR login (--SkipLogin specified)" -ForegroundColor Yellow
    Write-Host ""
}

# Step 3: Push to ACR
Write-Host "[3/3] Pushing image to ACR..." -ForegroundColor Green
docker push $fullImageName

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Push failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✅ SUCCESS!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Image pushed: $fullImageName" -ForegroundColor White
Write-Host ""
Write-Host "To deploy to ACI, run:" -ForegroundColor Yellow
Write-Host "  .\deploy-to-aci-vnet.ps1 -ResourceGroup 'your-rg' -ContainerName 'my-mind-app' -AcrName '$AcrName'" -ForegroundColor Cyan
Write-Host ""
Write-Host "To pull the image:" -ForegroundColor Yellow
Write-Host "  docker pull $fullImageName" -ForegroundColor Cyan
Write-Host ""
