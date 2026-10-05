# 💾 BLUSH DATABASE MODULE (SQL SERVER)

Thư mục này chứa toàn bộ Scripts khởi tạo CSDL và tài liệu cấu trúc dữ liệu cho dự án **BLUSH AI Gaming Platform**.

---

## 📂 Danh mục File:

- 📄 **`script_database.sql`**: Script T-SQL khởi tạo Database `BlushDb` gồm 7 Modules (Roles, Users, UserLogins, UserProfiles, Hobbies, UserHobbies, Games, Zones, UserGameProfiles, IceBreakerQuestions, ChatRooms, Messages, Quests, UserQuests, Badges, UserBadges, AiLogs, VipPackages, Transactions, UserSubscriptions, Reports) kèm dữ liệu mẫu khởi tạo (Seed Data).

---

## 🛠️ Hướng dẫn Khởi tạo CSDL (SQL Server):

1. Mở phần mềm **SQL Server Management Studio (SSMS)** hoặc **Azure Data Studio**.
2. Kết nối tới SQL Server Database Engine của bạn.
3. Nếu máy đã có `BlushDb` bản cũ: mở `script_database.sql`, bỏ comment 3 dòng `DROP DATABASE` ở đầu file (sẽ **xóa hết dữ liệu cũ**).
4. Nhấn **Execute (F5)** để chạy script.
5. CSDL `BlushDb` sẽ được khởi tạo kèm các tài khoản mẫu:
   - ⚙️ **Super Admin:** `admin@blush.vn` | Mật khẩu: `123456`
   - 🛡️ **Staff:** `staff@blush.vn` | Mật khẩu: `123456`
   - 🎮 **Gamer:** `gamer@blush.vn` | Mật khẩu: `123456`

### Đã có `BlushDb` từ trước?
Không cần xóa DB. Mở và chạy (F5) lần lượt các file trong thư mục `migrations/` theo số thứ tự:
- `001_email_otp_and_lockout.sql`: thêm bảng mã OTP email + cột chống dò mật khẩu.
- `002_remove_age_limit.sql`: bỏ ràng buộc 18+ trong DB (tuổi tối thiểu giờ là 16, do backend kiểm tra ở `Services/AgePolicy.cs`).
- `003_two_factor_email.sql`: xác thực 2 bước qua email + bảng thiết bị tin cậy.
- `004_onboarding_matching.sql`: khảo sát sau đăng ký (cột `UsesMic`, `TeammateWish`, `OnboardingCompletedAt` trong UserProfiles + bảng `UserPlayTimes`) và 8 người chơi mẫu `*@demo.blush.vn` (mật khẩu `123456`) để demo ghép đội.
- `005_payment_gateways.sql`: thêm cột `GatewayTransactionId`, `FailureReason`, `ExpiresAt` cho Transactions, giới hạn `PaymentMethod` (MoMo/VNPay/ZaloPay/VietQR) và gói `quarter_pro` (129.000đ/3 tháng).

Các file migration chỉ **thêm** cột/bảng, chạy lại nhiều lần cũng không sao.

> Dùng `sqlcmd` thay SSMS thì nhớ thêm cờ `-I` (bật QUOTED_IDENTIFIER), nếu không sẽ lỗi khi thêm dữ liệu vào bảng `Users`.

## 📐 Quy ước thiết kế (v2)

- **Users** chỉ chứa thông tin đăng nhập + điểm game. Hồ sơ hiển thị nằm ở **UserProfiles** (1-1).
- **Đăng nhập Google** lưu ở **UserLogins** (Provider + mã Google). User chỉ dùng Google thì `PasswordHash = NULL`.
- **CurrentLevel** là cột tự tính `Exp / 100 + 1` — không bao giờ UPDATE tay.
- **VIP**: user là VIP khi có dòng trong **UserSubscriptions** với `EndAt` > hiện tại.
- **Nhiệm vụ**: mỗi kỳ (ngày/tuần/mùa) là 1 dòng mới trong **UserQuests** (`PeriodStart`) → tự reset.
- Thời gian lưu **UTC**; "một ngày" (điểm danh) tính theo giờ Việt Nam ở backend.
- **Transactions** không xóa dây chuyền theo User (chứng từ tài chính).
- **Onboarding**: `UserProfiles.OnboardingCompletedAt` NULL = gamer chưa làm khảo sát → app bắt làm trước khi vào trang chủ. Dữ liệu ghép đội nằm ở **UserGameProfiles** (game + vị trí + mục đích), **UserPlayTimes** (khung giờ), **UserHobbies**, `UserProfiles.Region/UsesMic`.
- **Ghép đội** (`backend/Services/Implementations/RuleBasedMatchingService.cs`): cùng game 40 + cùng mục đích 20 + trùng khung giờ 20 + cùng khu vực 10 + trùng sở thích 10. `TeammateWish` (tự viết) để dành cho AI đọc khi tích hợp Gemini.
