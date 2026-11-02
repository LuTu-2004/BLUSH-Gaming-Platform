"""Tạo script CSDL cho server thật (Azure SQL...) từ script_database.sql.

    python database/make_production_sql.py
    -> database/build/blushdb_production.sql

Khác bản dev:
  - Bỏ CREATE DATABASE / USE BlushDb: Azure SQL không cho chạy 2 lệnh này trong script
    (tạo database trên trang Azure trước, rồi chạy script khi đã kết nối vào database đó).
  - Cắt toàn bộ phần dữ liệu demo (tài khoản mật khẩu '123456') từ dòng đánh dấu "-- >>> DỮ LIỆU DEMO".
Chỉ sửa script_database.sql, chạy lại file này là có bản mới.
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = HERE / "script_database.sql"
OUTPUT = HERE / "build" / "blushdb_production.sql"
DEMO_MARKER = "-- >>> DỮ LIỆU DEMO"
SKIP_LINES = {"CREATE DATABASE BlushDb;", "USE BlushDb;"}


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")  # cửa sổ lệnh Windows mặc định không in được tiếng Việt
    text = SOURCE.read_text(encoding="utf-8")
    if DEMO_MARKER not in text:
        raise SystemExit(f"Không thấy dòng đánh dấu '{DEMO_MARKER}' trong {SOURCE.name}")
    schema = text.split(DEMO_MARKER, 1)[0]

    lines = [line for line in schema.splitlines() if line.strip() not in SKIP_LINES]
    body = "\n".join(lines).rstrip()
    for word in ("@demo.blush.vn", "@blush.vn", "$2a$"):
        if word in body:
            raise SystemExit(f"Phần không phải demo vẫn còn '{word}', kiểm tra lại vị trí dòng đánh dấu")

    header = (
        "-- ============================================================================\n"
        "-- BLUSH - CSDL CHO SERVER THẬT (tự tạo bởi database/make_production_sql.py, ĐỪNG sửa tay)\n"
        "-- Chạy khi ĐÃ kết nối vào database trống (VD Azure SQL), không có tài khoản demo.\n"
        "-- Tạo Admin: đăng ký tài khoản trong app rồi chạy database/promote_admin.sql.\n"
        "-- ============================================================================\n"
    )
    footer = "\nGO\n\nPRINT N'✅ Khởi tạo CSDL BLUSH (server thật) thành công!';\nGO\n"
    OUTPUT.parent.mkdir(exist_ok=True)
    OUTPUT.write_text(header + body + footer, encoding="utf-8")
    print(f"Đã tạo {OUTPUT.relative_to(HERE.parent)} ({len(lines)} dòng)")


if __name__ == "__main__":
    main()
