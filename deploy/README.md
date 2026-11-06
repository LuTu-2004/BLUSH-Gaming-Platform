# Deploy BLUSH lên Azure

Server thật: **Azure App Service** (Linux, .NET 8, gói B1, vùng East Asia) + **Azure SQL** (gói free, tự ngủ khi không ai dùng).
Cùng một địa chỉ phục vụ cả API (`/api`), chat realtime (`/hubs/chat`), ảnh người dùng (`/uploads`) và **bản web Flutter** (trang gốc, dùng cho Admin).

## Cập nhật server sau khi sửa code

```powershell
.\deploy\deploy-azure.ps1          # backend + bản web
.\deploy\deploy-azure.ps1 -Apk     # thêm APK trỏ về server (để gửi người dùng Android)
```

Script tự: build backend cho Linux → build bản web Flutter → chép web vào `wwwroot` → nén zip → upload → gọi thử API.
Mất khoảng 3-5 phút. Thấy `API OK` là xong.

> `-SkipWeb` chỉ upload backend, nhưng upload là **thay toàn bộ** thư mục trên server → bản web cũ bị xóa. Chỉ dùng khi không cần web.

### Cần chuẩn bị (1 lần)

1. .NET SDK 8+, Flutter.
2. **File publish profile**: Azure Portal → App Service `blush-api-trong` → Overview → **Download publish profile**.
   Để ở thư mục **cha** của repo (`..\blush-api-trong.PublishSettings`), hoặc truyền `-PublishProfile <đường dẫn>`.
   File này chứa mật khẩu deploy: **không commit** (đã có trong `.gitignore`), không gửi qua chat.
   Lộ file → Overview → **Reset publish profile** rồi tải lại.

## Cấu hình trên Azure (không nằm trong code)

Mọi khóa bí mật đặt ở **App Service → Settings → Environment variables**, không để trong `appsettings.json`.
Tên biến dùng `__` thay cho `:` (VD `Payment:PayOs:ApiKey` → `Payment__PayOs__ApiKey`).

| Biến | Ghi chú |
|---|---|
| `ConnectionStrings` → `DefaultConnection` (tab Connection strings, kiểu SQLAzure) | `Server=tcp:blush-sql-trong.database.windows.net,1433;Database=BlushDb;User ID=...;Password=...;Encrypt=True;...` |
| `ASPNETCORE_ENVIRONMENT` | `Production` |
| `Jwt__SigningKey` | Chuỗi ngẫu nhiên ≥ 32 ký tự. Đổi = mọi người bị đăng xuất |
| `Gemini__ApiKey` | Key Google AI Studio |
| `Firebase__CredentialsJson` | **Nội dung** file JSON service account (server không có ổ D: như máy dev) |
| `Storage__LocalPath` | `/home/uploads` (thư mục `/home` giữ lại khi server khởi động lại) |
| `Smtp__Username`, `Smtp__Password` | Gmail + App Password |
| `Payment__Mode` | `Production` = tiền thật |
| `Payment__PublicBaseUrl` | Địa chỉ server (https) |
| `Payment__PayOs__ClientId` / `ApiKey` / `ChecksumKey` | Key PayOS |

Configuration → General settings: **Always on = On**, **HTTPS only = On**, SCM Basic Auth = On (để script upload được).

## Những chỗ hay vướng

- **Đổi địa chỉ server** (VD gắn tên miền riêng): phải build lại APK (`-Apk`), đổi Webhook URL trên my.payos.vn thành `<địa chỉ>/api/payment/payos/webhook`, đổi `Payment__PublicBaseUrl`.
- **Mở Query editor của Azure SQL báo "IP isn't allowed"**: IP mạng nhà đổi → bấm link *Allowlist IP* trong thông báo. App không bị ảnh hưởng.
- **Tạo Admin trên server thật**: đăng ký trong app → sửa email trong `database/promote_admin.sql` → chạy trong Query editor → đăng xuất, đăng nhập lại.
- **Tạo DB mới từ đầu**: chạy `database/build/blushdb_production.sql` (tạo bởi `database/make_production_sql.py`, không có tài khoản demo) trên database trống.
- **Lần gọi đầu sau khi DB ngủ hơi chậm** (~1 phút DB thức dậy): backend tự thử lại (`backend/DataAccess/WakeUpRetryStrategy.cs`).
- **Gói Azure for Students chỉ cho tạo tài nguyên ở**: koreacentral, indonesiacentral, japaneast, eastasia, centralindia.
- **Xem log server**: Azure Portal → App Service → Monitoring → **Log stream**.
