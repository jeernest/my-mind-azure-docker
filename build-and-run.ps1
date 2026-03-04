# Build and run My Mind Docker container locally

# Build the Docker image
Write-Host "Building Docker image..." -ForegroundColor Green
docker build -t my-mind:latest .

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful!" -ForegroundColor Green
    
    # Run the container
    Write-Host "`nStarting container on http://localhost:8080..." -ForegroundColor Green
    docker run -d -p 8080:8080 --name my-mind-app my-mind:latest
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nContainer is running!" -ForegroundColor Green
        Write-Host "Access the app at: http://localhost:8080" -ForegroundColor Cyan
        Write-Host "`nTo stop: docker stop my-mind-app" -ForegroundColor Yellow
        Write-Host "To remove: docker rm my-mind-app" -ForegroundColor Yellow
    }
} else {
    Write-Host "Build failed!" -ForegroundColor Red
}
