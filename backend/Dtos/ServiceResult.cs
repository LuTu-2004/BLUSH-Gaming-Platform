namespace Blush.Api.Dtos
{
    // Kết quả trả về từ tầng Service: thành công kèm dữ liệu, hoặc thất bại kèm mã lỗi HTTP + lời nhắn.
    // Controller chỉ cần chuyển nó thành response, không phải tự đoán lỗi gì.
    public class ServiceResult<T>
    {
        public bool Success { get; private init; }
        public int StatusCode { get; private init; }
        public string? Error { get; private init; }
        public T? Data { get; private init; }

        public static ServiceResult<T> Ok(T data) => new() { Success = true, StatusCode = 200, Data = data };

        public static ServiceResult<T> Fail(int statusCode, string error) =>
            new() { Success = false, StatusCode = statusCode, Error = error };
    }
}
