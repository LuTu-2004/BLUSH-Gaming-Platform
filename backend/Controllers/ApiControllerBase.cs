using Blush.Api.Dtos;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public abstract class ApiControllerBase : ControllerBase
    {
        // Đổi ServiceResult thành HTTP response: thành công -> 200 + dữ liệu, thất bại -> mã lỗi + { message }
        protected IActionResult ToActionResult<T>(ServiceResult<T> result) =>
            result.Success
                ? Ok(result.Data)
                : StatusCode(result.StatusCode, new { message = result.Error });
    }
}
