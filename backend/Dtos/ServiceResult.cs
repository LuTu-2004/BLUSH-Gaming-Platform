namespace Blush.Api.Dtos
{
    // Kết quả trả về từ tầng Service: thành công kèm dữ liệu, hoặc thất bại kèm mã lỗi HTTP + lời nhắn.
    // Controller chỉ cần chuyển nó thành response, không phải tự đoán lỗi gì.
    public class ServiceResult<T>
    {
        public bool Success { get; private init; }
        public int StatusCode { get; private init; }
        public string? Error { get; private init; }

        /// Mã lỗi để app xử lý tiếp (VD: "EMAIL_NOT_VERIFIED" -> chuyển sang màn nhập OTP)
        public string? ErrorCode { get; private init; }
        public T? Data { get; private init; }

        public static ServiceResult<T> Ok(T data) => new() { Success = true, StatusCode = 200, Data = data };

        public static ServiceResult<T> Fail(int statusCode, string error, string? errorCode = null) =>
            new() { Success = false, StatusCode = statusCode, Error = error, ErrorCode = errorCode };
    }

    public static class ErrorCodes
    {
        public const string EmailNotVerified = "EMAIL_NOT_VERIFIED";
        public const string TwoFactorRequired = "TWO_FACTOR_REQUIRED";
        public const string OnboardingRequired = "ONBOARDING_REQUIRED";
    }
}
