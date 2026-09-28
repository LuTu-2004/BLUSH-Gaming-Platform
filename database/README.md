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
