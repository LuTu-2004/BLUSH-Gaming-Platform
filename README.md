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
| POST | `/api/account/delete` | Tự xóa tài khoản (`password`, hoặc `googleIdToken` nếu chỉ dùng Google). Xóa dữ liệu cá nhân, giữ thanh toán + báo cáo ở dạng ẩn danh. Staff/Admin không tự xóa được 🔒 |
| POST | `/api/profile` | Lưu giới thiệu + 2 câu hỏi cá nhân (`bio`, `sundayAnswer`, `overthinkAnswer`, tối đa 500 ký tự, để trống = xóa) → trả về user mới 🔒 |
| POST | `/api/quest/claim-daily` | Điểm danh hằng ngày 🔒 |
| GET | `/api/quest` | Nhiệm vụ ngày/tuần/mùa + tiến độ kỳ hiện tại (hiện chỉ "Ghép đội 1 lần" tự cộng khi xem gợi ý đồng đội) 🔒 |
| POST | `/api/quest/{id}/claim` | Nhận quà nhiệm vụ đã hoàn thành (mỗi kỳ 1 lần) → cộng Coins/EXP 🔒 |
| GET | `/api/payment/packages` | Danh sách gói VIP (29K/tháng, 49K/tháng, 129K/3 tháng) 🔒 |
| GET | `/api/payment/methods` | Phương thức thanh toán: MoMo, VietQR (`isAvailable`) 🔒 |
| POST | `/api/payment/checkout` | Tạo giao dịch (`packageCode`, `method`) → link thanh toán / mã VietQR 🔒 |
| GET | `/api/payment/transactions` | Lịch sử thanh toán của mình 🔒 |
| GET | `/api/payment/transactions/{orderCode}` | Trạng thái 1 giao dịch (app hỏi lại 3 giây/lần khi đang chờ) 🔒 |
| POST | `/api/payment/transactions/{orderCode}/cancel` | Hủy giao dịch đang chờ 🔒 |
| POST | `/api/payment/mock/{orderCode}/complete` | **Chỉ chế độ Mock**: giả lập cổng báo thành công/thất bại 🔒 |
| POST/GET | `/api/payment/momo/ipn`, `/momo/return`, `/payos/webhook`, `/payos/return` | MoMo/PayOS gọi về, kiểm tra bằng chữ ký HMAC-SHA256 |
| GET | `/api/admin/payments/summary?days=30` | Dashboard: doanh thu hôm nay/tháng/kỳ, theo ngày, theo phương thức, theo gói, tỉ lệ thành công, VIP đang dùng 👑 |
| GET | `/api/admin/payments/transactions?status=&method=&search=&page=` | Danh sách giao dịch (lọc, tìm email/tên/mã đơn, phân trang) 👑 |
| POST | `/api/admin/payments/transactions/{orderCode}/confirm` | Xác nhận đã nhận chuyển khoản VietQR → kích hoạt VIP 👑 |
| GET | `/api/admin/users?search=&role=&status=&page=` | Danh sách người dùng (tìm email/tên, lọc vai trò, trạng thái `Active`/`Suspended`/`Banned`) + số liệu thành viên, VIP, đang bị khóa 👑 |
| POST | `/api/admin/users/{id}/status` | Khóa: `{"status":"Banned"}`, tạm khóa: `{"status":"Suspended","suspendDays":7}`, mở khóa: `{"status":"Active"}` 👑 |
| POST | `/api/admin/ai/playstyles?max=50` | AI đọc phong cách chơi (nghiêm túc / thích trò chuyện / thích đùa) cho hồ sơ cũ chưa phân tích. Hồ sơ mới tự phân tích khi lưu khảo sát / hồ sơ 👑 |
| POST | `/api/admin/users/{id}/role` | Đổi vai trò `User`/`Staff`/`Admin` (không tự khóa / tự đổi vai trò chính mình) 👑 |
| GET | `/api/chat/rooms` | Danh sách cuộc trò chuyện của mình (mới nhắn lên đầu, kèm tin cuối) 🔒 |
| POST | `/api/chat/rooms` | Mở phòng chat 1-1 `{userId}` (có rồi thì trả phòng cũ, phòng mới được gắn 1 câu hỏi phá băng ngẫu nhiên) 🔒 |
| GET/POST | `/api/chat/rooms/{id}/messages?before=&limit=` | Lịch sử tin nhắn (cũ → mới) / gửi tin `{content}` (tối đa 2000 ký tự). Chỉ 2 thành viên mới xem được 🔒 |
| POST | `/api/chat/rooms/{id}/icebreaker` | Trả lời câu phá băng `{choice:"A"\|"B"}`; lựa chọn của người kia chỉ hiện khi mình đã chọn 🔒 |
| WS | `/hubs/chat?access_token=` | SignalR nhận tin thời gian thực: sự kiện `message`, `room`. App mất kết nối thì tự hỏi lại 5 giây/lần 🔒 |
| GET | `/api/zones` | Danh sách Zone (cộng đồng theo game + mục đích): đã tham gia chưa, có vào được không (Zone kín: BLUSH Pass Pro) 🔒 |
| POST/DELETE | `/api/zones/{id}/join` | Tham gia / rời Zone. Khảo sát xong được tự xếp vào Zone theo game + mục đích 🔒 |
| GET/POST | `/api/zones/{id}/posts`, `/api/zones/feed` | Bài trong 1 Zone / bảng tin các Zone đã tham gia (20 bài/lần, `before=` để tải thêm); đăng bài `{content}` 🔒 |
| POST/DELETE | `/api/posts/{id}/like`, `/api/posts/{id}` | Thả / bỏ tim; gỡ bài (người đăng hoặc Staff/Admin) 🔒 |
| GET/POST/DELETE | `/api/posts/{id}/comments`, `/api/comments/{id}` | Bình luận. Đăng bài, thả tim, bình luận bài người khác được tính vào nhiệm vụ 🔒 |
| GET | `/api/notifications`, `/api/notifications/summary` | Thông báo trong app (thả tim, bình luận, cảnh báo, báo cáo đã xử lý, nhiệm vụ, VIP) + số chưa đọc cho 🔔 và số cuộc trò chuyện chưa đọc cho 💬. Thông báo mới đẩy qua SignalR (`notification`) 🔒 |
| POST | `/api/notifications/{id}/read`, `/api/notifications/read-all`, `/api/chat/rooms/{id}/read` | Đánh dấu đã đọc thông báo / phòng chat 🔒 |
| GET | `/api/badges/me` | Huy hiệu: đã nhận (kèm ngày) / chưa (kèm điều kiện). Backend tự kiểm tra + trao khi gọi API này hoặc khi mở app (`/api/notifications/summary`), có thông báo 🔔 🔒 |
| GET | `/api/matches`, `/api/matches/options` | Nhật ký trận: trận chờ mình xác nhận + lịch sử; đồng đội có thể chọn (người đã chat) + game của mình kèm danh sách rank 🔒 |
| POST | `/api/matches`, `/api/matches/{id}/confirm` | Ghi trận `{teammateId, gameId, result: Win\|Loss}` (tối đa 20/ngày) → đồng đội xác nhận `{confirm}` mới tính nhiệm vụ chơi 3 trận, chuỗi thắng, hỗ trợ tân thủ và huy hiệu Chúa Tryhard 🔒 |
| POST | `/api/matches/rank` | Khai rank `{gameId, rank}` từ danh sách rank thật của game; Cao Thủ (hoặc tương đương) → nhiệm vụ mùa 🔒 |
| GET | `/api/ai/usage` | Hạn mức AI: số lượt hôm nay (Free 3, Basic 10, Pro không giới hạn) và tokens tháng này 🔒 |
| POST | `/api/ai/chat/{roomId}/suggest` | AI gợi ý 3 câu trong phòng chat (chưa nhắn: câu mở đầu, đã nhắn: nối chuyện). Hết lượt → 429 `AI_QUOTA_EXCEEDED`; AI chưa bật/đang bận → 503 `AI_UNAVAILABLE` (không trừ lượt) 🔒 |
| POST | `/api/ai/match/{userId}/explain` | AI giải thích vì sao 2 người hợp nhau 🔒 |
| POST | `/api/ai/logs/{id}/report` | Báo cáo câu trả lời AI không phù hợp 🔒 |
| GET/POST/DELETE | `/api/blocks`, `/api/blocks/{userId}` | Người đã chặn / chặn / bỏ chặn. Chặn có tác dụng 2 chiều: không nhắn tin, phòng chat cũ bị ẩn, không gợi ý ghép đội 🔒 |
| GET | `/api/reports/reasons` | Lý do báo cáo vi phạm (mỗi lý do ứng với 1 mức độ: Cao / Trung bình / Thấp) 🔒 |
| POST | `/api/reports` | Báo cáo 1 người chơi (`reportedUserId`, `reasonCode`, `detail`); mỗi người chỉ có 1 báo cáo đang chờ cho cùng 1 người 🔒 |
| GET | `/api/staff/reports?status=&page=` | Báo cáo vi phạm (chưa xử lý và mức nặng lên trước) + số liệu 🛡️ |
| POST | `/api/staff/reports/{id}/resolve` | Xử lý: `Warn` / `Suspend` (tạm khóa game thủ 3 ngày) / `Dismiss` 🛡️ |
| GET/POST | `/api/staff/icebreakers`, `/icebreakers/categories` | Danh sách / thêm câu hỏi phá băng (câu hỏi + 2 lựa chọn A/B) 🛡️ |
| POST/DELETE | `/api/staff/icebreakers/{id}/active`, `/api/staff/icebreakers/{id}` | Bật/tắt, xóa (câu đã dùng trong phòng chat thì chỉ tắt được) 🛡️ |
| GET | `/api/onboarding/options` | Danh sách game (kèm vị trí), mục đích, khung giờ, khu vực, sở thích cho màn khảo sát 🔒 |
| GET | `/api/onboarding` | Câu trả lời khảo sát đã lưu (để sửa lại trong Hồ sơ) 🔒 |
| POST | `/api/onboarding` | Lưu khảo sát sau đăng ký (game, khung giờ, khu vực, mic, sở thích, mô tả đồng đội; `dateOfBirth` bắt buộc nếu tài khoản Google chưa có, dưới 16 tuổi bị chặn) → `onboardingCompleted = true` 🔒 |
| GET | `/api/match/suggestions?gameId=&limit=` | Gợi ý đồng đội: điểm hợp 0-100 (Game 35, Mục đích 15, Khung giờ 15, Phong cách chơi do AI đọc 15, Khu vực 10, Sở thích 10) + lý do (chưa làm khảo sát → lỗi `ONBOARDING_REQUIRED`) 🔒 |
| GET | `/api/leaderboard?region=&gameId=&limit=` | Bảng xếp hạng theo EXP (chỉ gamer đã làm khảo sát; `region` = `HCM`/`HN`, bằng EXP thì cùng hạng) + hạng của mình (`me`, null nếu không có trong bảng) 🔒 |

🔒 = cần header `Authorization: Bearer <accessToken>`. Mỗi request đều kiểm tra lại tài khoản trong DB: bị khóa hoặc đổi vai trò thì token cũ bị từ chối ngay (401), app tự đăng xuất. 🛡️ = Staff hoặc Admin. 👑 = chỉ tài khoản Admin (Staff/User bị 403). Backend luôn lấy Id người dùng từ token, không nhận `userId` từ app.

**Thanh toán (MoMo + VietQR qua PayOS)** - chỉnh `Payment:Mode` trong `appsettings.json`:
- `Mock` (mặc định): không gọi cổng thật, app hiện trang giả lập → demo không cần mạng hay key. Giao dịch vẫn lưu DB và kích hoạt VIP thật trong DB.
- `Sandbox` / `Production`: thu tiền thật qua PayOS (VietQR) và MoMo. **Xem hướng dẫn từng bước: [PAYMENT_SETUP.md](PAYMENT_SETUP.md)** (đăng ký key, user-secrets, ngrok, webhook).
- Mỗi cổng là 1 class trong `backend/Services/Payments/` (cài `IPaymentGateway`). Kích hoạt VIP chỉ 1 lần dù cổng báo về nhiều lần; mua lại cùng gói khi còn hạn thì cộng dồn thời hạn.

### 2. Dành cho Frontend Mobile Developer (Thư mục `frontend/mobile_flutter/`):
1. Mở thư mục `frontend/mobile_flutter/` bằng VS Code / Android Studio có cài Flutter SDK.
2. Chạy `flutter pub get` để cài các gói thư viện.
3. Bật backend trước, rồi chạy `flutter run`.
   - Máy ảo Android: tự dùng `http://10.0.2.2:5000/api`, không cần cấu hình.
   - Điện thoại thật (cùng Wi-Fi với máy chạy backend): `flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:5000/api`
4. Đăng nhập thử: `gamer@blush.vn` / `staff@blush.vn` / `admin@blush.vn`, mật khẩu `123456`.
   `gamer@blush.vn` chưa làm khảo sát nên đăng nhập sẽ vào màn **Tạo hồ sơ chơi game** (4 bước) trước; làm xong mới vào trang chủ, tab **Đồng đội** hiện gợi ý từ 8 người chơi mẫu.
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

### 5. Bật AI (Google Gemini)
1. Tạo key miễn phí tại https://aistudio.google.com → **Get API key**.
2. Trong thư mục `backend/` chạy (key lưu trên máy, **không** bị đẩy lên GitHub):
   ```powershell
   dotnet user-secrets set "Gemini:ApiKey" "<key>"
   ```
3. Model + hạn mức chỉnh ở mục `Gemini` trong `appsettings.json` (`Model`, `FreeDailyLimit`, `BasicDailyLimit`, `ProDailyLimit` = 0 là không giới hạn, `FreeMonthlyTokens`; gói VIP dùng `VipPackages.AiTokenLimit`).
- Chưa có key: nút AI vẫn hiện, app dùng câu gợi ý có sẵn. Gemini quá tải: backend thử lại 1 lần, vẫn lỗi thì báo "AI đang bận" và không trừ lượt.
- Gói miễn phí của Gemini có giới hạn lượt/phút và Google có thể dùng dữ liệu gửi lên để cải thiện sản phẩm: khi phát hành thật nên bật tính phí trên Google Cloud.

### 6. Trước khi deploy thật
- **Khóa ký token (JWT):** `Jwt:SigningKey` trong `appsettings.json` là khóa mẫu `DEV_ONLY_...` nằm công khai trên GitHub, ai có nó cũng tự ký được token Admin. Chạy ngoài môi trường Development mà vẫn dùng khóa này thì backend **từ chối khởi động**. Đặt khóa mới (không commit):
  ```powershell
  # Tạo chuỗi ngẫu nhiên 64 ký tự
  [Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }))
  # Máy chủ: biến môi trường (hai dấu gạch dưới thay cho dấu hai chấm)
  $env:Jwt__SigningKey = "<chuỗi vừa tạo>"
  ```
  Đổi khóa thì mọi token cũ hết hiệu lực, người dùng phải đăng nhập lại.
- **Token trên điện thoại** được lưu mã hóa (Android Keystore / iOS Keychain qua `flutter_secure_storage`). Bản app cũ lưu ở SharedPreferences sẽ tự chuyển sang lần mở đầu tiên, không bắt đăng nhập lại.
- Thanh toán thật: xem [PAYMENT_SETUP.md](PAYMENT_SETUP.md).
