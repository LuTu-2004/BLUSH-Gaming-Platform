using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace Blush.Api.DataAccess
{
    // Azure SQL gói free tự tạm dừng khi không ai dùng; câu lệnh đầu tiên lúc DB đang thức dậy báo lỗi 40613 ~1 phút.
    // Chiến lược này thử lại các lỗi tạm thời đó, NHƯNG chỉ khi không có transaction tự mở (BeginTransactionAsync):
    // thử lại giữa transaction là chạy lại nửa chừng -> các chỗ đó giữ nguyên như cũ (lỗi thì báo lỗi).
    // DB thức dậy luôn rơi vào câu đầu tiên của request, nằm trước mọi transaction, nên vẫn được thử lại.
    public class WakeUpRetryStrategy : SqlServerRetryingExecutionStrategy
    {
        public WakeUpRetryStrategy(ExecutionStrategyDependencies dependencies)
            : base(dependencies, maxRetryCount: 6, maxRetryDelay: TimeSpan.FromSeconds(20), errorNumbersToAdd: null)
        {
        }

        private bool InUserTransaction => Dependencies.CurrentContext.Context?.Database.CurrentTransaction != null;

        // Mặc định EF ném lỗi nếu đang có transaction tự mở; ở đây cho chạy, chỉ là không thử lại
        protected override void OnFirstExecution()
        {
            if (InUserTransaction)
            {
                ExceptionsEncountered.Clear();
                return;
            }
            base.OnFirstExecution();
        }

        protected override bool ShouldRetryOn(Exception exception) => !InUserTransaction && base.ShouldRetryOn(exception);
    }
}
