# PowerShell script to start all DMS backend services at once with Java 17 LTS

$JavaHome = "C:\Program Files\Java\jdk-17"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   DMS Backend Microservices Starter     " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Target Java 17 JDK: $JavaHome" -ForegroundColor Yellow

# Verify JDK 17 exists
if (-not (Test-Path $JavaHome)) {
    Write-Host "ERROR: JDK 17 not found at $JavaHome." -ForegroundColor Red
    Write-Host "Please ensure Java 17 LTS is installed or edit this script with the correct path." -ForegroundColor Yellow
    exit 1
}

# Apply JDK 17 to current session
$env:JAVA_HOME = $JavaHome
$env:PATH = "$JavaHome\bin;$env:PATH"

# Function to start a service in a new terminal window
function Start-ServiceWindow {
    param (
        [string]$ServiceName,
        [string]$ServiceDir,
        [string]$Command
    )
    Write-Host "Starting $ServiceName..." -ForegroundColor Green
    
    # We pass the command to set environment variables and run Maven in a new powershell window
    $FullCommand = "`$env:JAVA_HOME = '$JavaHome'; `$env:PATH = '$JavaHome\bin;' + `$env:PATH; cd '$ServiceDir'; $Command"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $FullCommand
}

# 1. Start Eureka Server first
Start-ServiceWindow "Eureka Server" "$PSScriptRoot\eureka-server" "..\user-service\mvnw.cmd spring-boot:run"

# Wait for Eureka Server to boot up so clients can register successfully
Write-Host "Waiting 12 seconds for Eureka Server to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 12

# 2. Start all other services
$Services = @(
    @{ Name = "User Service"; Dir = "$PSScriptRoot\user-service"; Cmd = ".\mvnw.cmd spring-boot:run" },
    @{ Name = "Product Service"; Dir = "$PSScriptRoot\product-service"; Cmd = ".\mvnw.cmd spring-boot:run" },
    @{ Name = "Order Service"; Dir = "$PSScriptRoot\order-service"; Cmd = ".\mvnw.cmd spring-boot:run" },
    @{ Name = "Inventory Service"; Dir = "$PSScriptRoot\inventory-service"; Cmd = ".\mvnw.cmd spring-boot:run" },
    @{ Name = "Audit Service"; Dir = "$PSScriptRoot\audit-service"; Cmd = ".\mvnw.cmd spring-boot:run" },
    @{ Name = "Distributor Service"; Dir = "$PSScriptRoot\distributor-service"; Cmd = ".\mvnw.cmd spring-boot:run" }
)

foreach ($Service in $Services) {
    Start-ServiceWindow $Service.Name $Service.Dir $Service.Cmd
    # Brief pause between spawns to prevent CPU spikes and database lock contentions
    Start-Sleep -Seconds 2
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "All services have been started in separate windows!" -ForegroundColor Green
Write-Host "Eureka Dashboard: http://localhost:8761" -ForegroundColor Green
Write-Host "User Service UI: http://localhost:8082/users/login" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
