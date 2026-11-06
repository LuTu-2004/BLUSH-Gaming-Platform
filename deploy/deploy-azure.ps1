# ============================================================================
# Đưa backend + bản web Flutter (trang Admin) lên Azure App Service.
#   .\deploy\deploy-azure.ps1                       # build + upload
#   .\deploy\deploy-azure.ps1 -Apk                  # thêm: build APK trỏ về server
#   .\deploy\deploy-azure.ps1 -SkipWeb              # chỉ backend (bản web cũ trên server sẽ BỊ XÓA)
#   .\deploy\deploy-azure.ps1 -PublishProfile D:\keys\blush-api-trong.PublishSettings
# Cần: .NET SDK, Flutter, file publish profile (Azure Portal -> App Service -> Overview -> Download publish profile).
# File publish profile chứa mật khẩu deploy: để NGOÀI repo, không gửi ai. Xem deploy/README.md.
# ============================================================================
param(
    [string]$PublishProfile = (Join-Path $PSScriptRoot '..\..\blush-api-trong.PublishSettings'),
    [switch]$SkipWeb,
    [switch]$Apk
)

$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..')
$flutterDir = Join-Path $repo 'frontend\mobile_flutter'
$work = Join-Path ([IO.Path]::GetTempPath()) 'blush-deploy'
$publishDir = Join-Path $work 'publish'
$zip = Join-Path $work 'blush-api.zip'

function Step($text) { Write-Host "`n==> $text" -ForegroundColor Cyan }
function Check($what) { if ($LASTEXITCODE -ne 0) { throw "$what thất bại (exit $LASTEXITCODE)" } }

# --- 0. Đọc publish profile: địa chỉ server + tài khoản deploy -------------------
if (-not (Test-Path $PublishProfile)) {
    throw "Không thấy publish profile ở '$PublishProfile'. Tải từ Azure Portal rồi truyền -PublishProfile <đường dẫn>."
}
[xml]$xml = Get-Content -Raw -Encoding UTF8 $PublishProfile
$zipProfile = $xml.publishData.publishProfile | Where-Object { $_.publishMethod -eq 'ZipDeploy' } | Select-Object -First 1
if (-not $zipProfile) { throw 'Publish profile không có mục ZipDeploy (bật "SCM Basic Auth Publishing Credentials" trong Configuration).' }
$siteUrl = $zipProfile.destinationAppUrl.TrimEnd('/')
$scmUrl = 'https://' + ($zipProfile.publishUrl -replace ':443$', '')
$apiBaseUrl = "$siteUrl/api"
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($zipProfile.userName):$($zipProfile.userPWD)"))
Write-Host "Server: $siteUrl"

if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -ItemType Directory -Force $work | Out-Null

# --- 1. Backend cho Linux (App Service chạy Linux, .NET 8 có sẵn) ---------------
Step 'Build backend (Release, linux-x64)'
dotnet publish (Join-Path $repo 'backend\Blush.Api.csproj') -c Release -r linux-x64 --self-contained false -o $publishDir --nologo -v quiet
Check 'dotnet publish'

# --- 2. Bản web Flutter -> wwwroot (backend phục vụ ở địa chỉ gốc, chung origin với API) ---
if (-not $SkipWeb) {
    Step 'Build Flutter web'
    Push-Location $flutterDir
    try { flutter build web --release --dart-define=API_BASE_URL=$apiBaseUrl; Check 'flutter build web' }
    finally { Pop-Location }
    Copy-Item -Recurse (Join-Path $flutterDir 'build\web') (Join-Path $publishDir 'wwwroot')
}

# --- 3. Nén zip bằng tar.exe của Windows ---------------------------------------
# KHÔNG dùng Compress-Archive: PowerShell 5 ghi đường dẫn bằng '\', Linux giải nén ra tên file lạ.
Step 'Nén zip'
Push-Location $publishDir
try { & "$env:SystemRoot\System32\tar.exe" -a -c -f $zip *; Check 'tar' }
finally { Pop-Location }
Write-Host ("{0:N1} MB" -f ((Get-Item $zip).Length / 1MB))

# --- 4. Upload (Kudu zipdeploy: thay toàn bộ wwwroot, server tự khởi động lại) ---
Step 'Upload lên Azure (1-3 phút)'
Invoke-WebRequest -Method Post -Uri "$scmUrl/api/zipdeploy?isAsync=false" -InFile $zip -ContentType 'application/zip' `
    -Headers @{ Authorization = "Basic $auth" } -TimeoutSec 900 -UseBasicParsing | Out-Null

# --- 5. Kiểm tra: đăng nhập tài khoản không tồn tại phải ra 401 (API + DB chạy) ---
Step 'Kiểm tra server'
$ok = $false
for ($i = 1; $i -le 12 -and -not $ok; $i++) {
    try {
        Invoke-WebRequest -Method Post -Uri "$apiBaseUrl/auth/login" -ContentType 'application/json' `
            -Body '{"email":"deploy-check@example.com","password":"x"}' -TimeoutSec 90 -UseBasicParsing | Out-Null
    } catch {
        $code = [int]$_.Exception.Response.StatusCode
        if ($code -eq 401) { $ok = $true } else { Write-Host "  lần $i : HTTP $code, đợi server khởi động..."; Start-Sleep 15 }
    }
}
if (-not $ok) { throw "Server chưa trả lời đúng sau ~3 phút. Xem log: Azure Portal -> App Service -> Log stream." }
Write-Host "API OK" -ForegroundColor Green
if (-not $SkipWeb) { Write-Host "Web: $siteUrl" -ForegroundColor Green }

# --- 6. (Tùy chọn) APK trỏ về server --------------------------------------------
if ($Apk) {
    Step 'Build APK'
    Push-Location $flutterDir
    try { flutter build apk --release --dart-define=API_BASE_URL=$apiBaseUrl; Check 'flutter build apk' }
    finally { Pop-Location }
    Write-Host "APK: $(Join-Path $flutterDir 'build\app\outputs\flutter-apk\app-release.apk')" -ForegroundColor Green
}
