# 🚀 BLUSH GAMING PLATFORM - SKELETON BOILERPLATE (EXE201)

Đây là khung sườn dự án (Boilerplate Repository) chuẩn cho dự án **BLUSH**. 
Repository được chia sẵn 3 phần riêng biệt vô cùng dễ quản lý và phân công công việc:

1. **`backend/`** (ASP.NET Core 8 Web API - C#)
2. **`frontend/`** (Flutter Mobile App - Dart)
3. **`database/`** (SQL Server Scripts & Documentation)

---

## 📂 SƠ ĐỒ CẤU TRÚC THƯ MỤC REPOSITORY

```text
BLUSH-Gaming-Platform/
│
├── 📁 backend/                        <-- CỐT LÕI BACKEND (.NET 8 WEB API)
│   ├── 📁 Controllers/                <-- Tầng 1: API Controllers (UserController, QuestController...)
│   ├── 📁 Services/                   <-- Tầng 2: Business Logic Services (Interfaces & Implementations)
│   ├── 📁 DataAccess/                 <-- Tầng 3: EF Core DbContext & Entities (SQL Server)
│   ├── 📁 Dtos/                       <-- Dữ liệu vào/ra API (không trả entity có PasswordHash)
│   ├── 📄 Program.cs                  <-- Cấu hình Dependency Injection & Swagger UI
│   ├── 📄 appsettings.json            <-- Chuỗi kết nối Database & Secret keys
│   └── 📄 Blush.Api.csproj
│
├── 📁 frontend/
│   ├── 📁 mobile_flutter/             <-- FRONTEND MOBILE APP (FLUTTER / DART)
│   │   ├── 📁 lib/
│   │   │   ├── 📄 main.dart
│   │   │   ├── 📁 api/                <-- Kết nối RESTful API với Backend .NET
│   │   │   ├── 📁 models/             <-- Model dữ liệu (User, Quest, Zone)
│   │   │   ├── 📁 services/           <-- State dùng chung (Auth, Quest, Theme) qua Provider
│   │   │   └── 📁 screens/            <-- Màn hình App (Auth, Dashboard, Chat, Profile, VIP...)
│   │   ├── 📁 test/                   <-- Unit test + test chống tràn giao diện
│   │   └── 📄 pubspec.yaml
│   └── 📁 web_react/                  <-- Bản web React cũ (EXE101 demo)
│
└── 📁 database/                       <-- CƠ SỞ DỮ LIỆU SQL SERVER
    ├── 📄 script_database.sql         <-- Script T-SQL khởi tạo BlushDb (6 Modules + Seed Data)
    └── 📄 README.md                   <-- Hướng dẫn chạy script trên SSMS
```

---

## 🛠️ HƯỚNG DẪN CHẠY VÀ PHÂN CÔNG CÔNG VIỆC

### 1. Dành cho Backend Developer (Thư mục `backend/` & `database/`):
1. Chạy `database/script_database.sql` trên **SSMS** để tạo CSDL `BlushDb` (xem `database/README.md`).
   Máy đã có `BlushDb` từ trước: chạy lần lượt các file trong `database/migrations/` (`001` → `002` → `003`...), chỉ thêm, không mất dữ liệu.
2. Mở thư mục `backend/` bằng Visual Studio 2022 hoặc VS Code.
3. Chạy lệnh `dotnet run` hoặc bấm **F5**. Trang Swagger API mở tại `http://localhost:5000/swagger`.
4. Test API cần đăng nhập trên Swagger: gọi `POST /api/auth/login` → copy `accessToken` → bấm nút **Authorize** → dán token.
5. Entity trong `backend/DataAccess/Entities` phải khớp 100% với bảng trong `script_database.sql` — sửa bên này thì sửa luôn bên kia.

**API xác thực hiện có:**

| Method | Đường dẫn | Mô tả |
|---|---|---|
| POST | `/api/auth/register` | Đăng ký (email, mật khẩu, tên, ngày sinh ≥ 16 tuổi, xem `Services/AgePolicy.cs`) → gửi mã OTP, **chưa** đăng nhập |
| POST | `/api/auth/verify-email` | Nhập mã OTP → xác minh email + đăng nhập |
| POST | `/api/auth/resend-otp` | Gửi lại mã (`VerifyEmail` / `ResetPassword`), 60 giây/lần |
| POST | `/api/auth/login` | Đăng nhập email + mật khẩu (sai 5 lần → khóa 15 phút; chưa xác minh → lỗi `EMAIL_NOT_VERIFIED`) |
| POST | `/api/auth/login-2fa` | Bước 2 khi đã bật xác thực 2 bước: nhập mã từ email (+ "tin cậy thiết bị 30 ngày") |
| POST | `/api/auth/two-factor/enable` | Bật 2 bước, bước 1: mật khẩu → gửi mã xác nhận về email 🔒 |
| POST | `/api/auth/two-factor/confirm` | Bật 2 bước, bước 2: nhập mã → bật 🔒 |
| POST | `/api/auth/two-factor/disable` | Tắt 2 bước (mật khẩu), hủy các thiết bị tin cậy 🔒 |
| POST | `/api/auth/google` | Đăng nhập bằng Google (gửi `idToken`), không hỏi mã 2 bước vì Google tự bảo vệ |
| POST | `/api/auth/forgot-password` | Gửi mã đặt lại mật khẩu |
| POST | `/api/auth/reset-password` | Nhập mã + mật khẩu mới |
| GET | `/api/auth/me` | Thông tin người đang đăng nhập 🔒 |
| POST | `/api/quest/claim-daily` | Điểm danh hằng ngày 🔒 |
| POST | `/api/payment/create-checkout` | Tạo mã QR thanh toán VIP 🔒 |

🔒 = cần header `Authorization: Bearer <accessToken>`. Backend luôn lấy Id người dùng từ token, không nhận `userId` từ app.

### 2. Dành cho Frontend Mobile Developer (Thư mục `frontend/mobile_flutter/`):
1. Mở thư mục `frontend/mobile_flutter/` bằng VS Code / Android Studio có cài Flutter SDK.
2. Chạy `flutter pub get` để cài các gói thư viện.
3. Bật backend trước, rồi chạy `flutter run`.
   - Máy ảo Android: tự dùng `http://10.0.2.2:5000/api`, không cần cấu hình.
   - Điện thoại thật (cùng Wi-Fi với máy chạy backend): `flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:5000/api`
4. Đăng nhập thử: `gamer@blush.vn` / `staff@blush.vn` / `admin@blush.vn`, mật khẩu `123456`.
5. Trước khi push code: chạy `flutter analyze` (phải ra *No issues found*) và `flutter test`.

### 3. Cấu hình Đăng nhập Google (làm 1 lần cho cả nhóm)
1. Vào [Google Cloud Console](https://console.cloud.google.com/) → tạo project **BLUSH**.
2. **APIs & Services → OAuth consent screen**: chọn *External*, điền tên app, email hỗ trợ. Thêm email các thành viên vào *Test users*.
3. **APIs & Services → Credentials → Create credentials → OAuth client ID**, tạo 2 cái:
   - **Web application** → copy *Client ID* (dạng `xxx.apps.googleusercontent.com`). Đây là ID dùng ở cả backend và app.
   - **Android** → Package name: `vn.blush.app`, SHA-1: chạy `cd frontend/mobile_flutter/android && ./gradlew signingReport` rồi copy dòng SHA1 của `debug`. **Mỗi máy dev có SHA-1 khác nhau → mỗi người thêm SHA-1 của mình vào client Android này.**
4. Backend: dán Web Client ID vào `backend/appsettings.json` → `GoogleAuth:WebClientId`.
5. Flutter: Client ID đã để mặc định trong `lib/config/app_config.dart` (đổi bằng `--dart-define=GOOGLE_WEB_CLIENT_ID=...` nếu cần).
6. iOS (cần máy Mac): tạo thêm client **iOS**, rồi thêm `GIDClientID` và URL scheme vào `ios/Runner/Info.plist` theo [hướng dẫn google_sign_in_ios](https://pub.dev/packages/google_sign_in_ios).

### 4. Gửi email mã OTP (xác minh email, quên mật khẩu)
- **Chưa cấu hình gì:** backend KHÔNG gửi mail mà in mã ra terminal đang chạy `dotnet run`, dòng có chữ `📧 [EMAIL GIẢ LẬP ...] ... Mã của bạn là: 123456`. Đủ để test.
- **Gửi mail thật bằng Gmail** (làm trên máy chạy backend):
  1. Tạo 1 Gmail riêng cho nhóm (VD: `blush.noreply@gmail.com`), bật **Xác minh 2 bước**.
  2. Vào https://myaccount.google.com/apppasswords → tạo **Mật khẩu ứng dụng** (16 ký tự).
  3. Trong thư mục `backend/` chạy (mật khẩu lưu trên máy, **không** bị đẩy lên GitHub):
     ```powershell
     dotnet user-secrets set "Smtp:Username" "blush.noreply@gmail.com"
     dotnet user-secrets set "Smtp:Password" "<mật khẩu ứng dụng 16 ký tự>"
     ```
  4. Chạy lại `dotnet run` → email OTP được gửi thật.

> ⚠️ Trước khi deploy thật: đổi `Jwt:SigningKey` trong `appsettings.json` thành chuỗi bí mật mới và không commit lên Git (dùng biến môi trường hoặc `dotnet user-secrets`).
