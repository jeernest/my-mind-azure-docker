# My Mind Docker Container

> **⚠️ First Time Setup Required**  
> This repository does NOT include the My Mind application source code.  

Docker container for the [My Mind](https://github.com/ondras/my-mind) web application - a mind mapping tool.

## Why This Deployment?

These scripts enable **private, secure deployment** of the My Mind application to Azure Container Instances (ACI). By hosting the application in your own Azure environment:

- **🔒 Data Privacy**: Your mind maps never leave your private network - no data sent over public internet
- **🛡️ No Third-Party Servers**: Run your own instance instead of relying on remote servers
- **🔐 Secure by Default**: Private VNet deployment ensures the application is only accessible within your network
- **✅ Full Control**: You own and control your data and infrastructure

Perfect for organizations with strict security requirements or anyone who wants to keep their mind mapping data completely private.

## Prerequisites

- Docker installed
- Extracted my-mind application in `my-mind-master/` directory
- For Azure deployment: Azure CLI and an Azure Container Registry

## Local Development

### 1. Copy Application Files

Extract the my-mind-master.zip and copy the `my-mind-master` folder to this directory:

```powershell
Expand-Archive -Path "$env:USERPROFILE\Downloads\my-mind-master.zip" -DestinationPath "."
```

### 2. Build and Run Locally

```powershell
.\build-and-run.ps1
```

### 3. Stop and Clean Up

```powershell
docker stop my-mind-app
docker rm my-mind-app
```

## Push to Azure Container Registry

### Quick Push to ACR

```powershell
# Build and push to your-acr-name.azurecr.io/tools/my-mind:latest
.\build-and-push-acr.ps1

# Or specify different ACR and tag
.\build-and-push-acr.ps1 -AcrName "myregistry" -ImageTag "v1.0.0"
```

### View Image Metadata

```powershell
docker inspect your-acr-name.azurecr.io/tools/my-mind:latest --format '{{json .Config.Labels}}' | ConvertFrom-Json
```

## Deploy to Azure Container Instances

### Option 1: Quick Deploy to Private VNet (Recommended)

Deploy container to private VNet:

```powershell
.\deploy-private.ps1 `
    -ResourceGroup "my-resource-group" `
    -ContainerName "my-mind-app"
```

**Features**:
- ✅ Deployed to private VNet (your-vnet, your-subnet)
- ✅ No public IP (secure, internal only)

### Option 2: Custom VNet Deployment

```powershell
.\deploy-to-aci-vnet.ps1 `
    -ResourceGroup "my-resource-group" `
    -ContainerName "my-mind-app" `
    -AcrName "myregistry" `
    -VNetName "your-vnet" `
    -SubnetName "your-subnet" `
    -VNetResourceGroup "vnet-rg" `
    -PrivateOnly
```

## Container Details

- **Base Image**: nginx:alpine-slim (lightweight, ~7MB, 62 fewer packages than standard alpine)
- **Port**: 8080 (non-privileged port)
- **Security**: Runs as non-root user (nginx)
- **Health Check**: Built-in HTTP health check on port 8080
- **Features**:
  - Gzip compression enabled
  - Security headers configured
  - Static asset caching
  - Custom nginx configuration
  - **Security hardened**: 0 Critical, 0 High vulnerabilities
  - Runs as non-root user for enhanced security

## Directory Structure

```
my-mind-file-docker/
├── .dockerignore            # Files to exclude from build
├── .gitignore               # Git ignore rules
├── build-and-push-acr.ps1   # Build and push to ACR (PowerShell)
├── build-and-run.ps1        # Local build/run script
├── deploy-private.ps1       # Quick deploy to private VNet
├── deploy-to-aci-vnet.ps1   # Full VNet deployment with all options
├── Dockerfile               # Container definition with metadata labels
├── LICENSE                  # MIT License
├── nginx.conf               # Nginx web server configuration
├── README.md                # This file
├── setup-dns.ps1            # Optional DNS configuration script
└── my-mind-master/          # Application files (download separately)
```

## Troubleshooting

### Check container logs:
```powershell
docker logs my-mind-app
```

### Check ACI logs:
```powershell
az container logs --resource-group my-resource-group --name my-mind-app
```

### Test locally before deploying:
Always test with `build-and-run.ps1` before pushing to Azure.

## License

The My Mind application is licensed under MIT. See the [original repository](https://github.com/ondras/my-mind) for details.
