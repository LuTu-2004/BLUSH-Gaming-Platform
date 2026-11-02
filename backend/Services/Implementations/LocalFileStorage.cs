using Blush.Api.Options;
using Blush.Api.Services.Interfaces;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Implementations
{
    // Lưu file vào thư mục Storage:LocalPath trên máy chạy backend; Program.cs phát thư mục này ở /uploads
    public class LocalFileStorage : IFileStorage
    {
        public const string UrlPrefix = "/uploads/";

        private readonly string _root;
        private readonly ILogger<LocalFileStorage> _logger;

        public LocalFileStorage(IOptions<StorageOptions> options, IWebHostEnvironment env, ILogger<LocalFileStorage> logger)
        {
            _root = ResolveRoot(options.Value, env);
            _logger = logger;
        }

        public static string ResolveRoot(StorageOptions options, IWebHostEnvironment env) =>
            Path.GetFullPath(Path.Combine(env.ContentRootPath, options.LocalPath));

        public async Task<string> SaveAsync(string folder, string fileName, Stream content, CancellationToken ct = default)
        {
            var dir = Path.Combine(_root, folder);
            Directory.CreateDirectory(dir);
            await using (var file = File.Create(Path.Combine(dir, fileName)))
            {
                await content.CopyToAsync(file, ct);
            }
            return $"{UrlPrefix}{folder}/{fileName}";
        }

        public Task DeleteAsync(string? url)
        {
            if (url == null || !url.StartsWith(UrlPrefix, StringComparison.Ordinal)) return Task.CompletedTask;
            // Chặn "../" trong URL: chỉ xóa file nằm trong thư mục uploads
            var path = Path.GetFullPath(Path.Combine(_root, url[UrlPrefix.Length..]));
            if (!path.StartsWith(_root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)) return Task.CompletedTask;
            try
            {
                File.Delete(path);
            }
            catch (IOException ex)
            {
                _logger.LogWarning(ex, "Không xóa được file cũ {Path}", path);
            }
            return Task.CompletedTask;
        }
    }
}
