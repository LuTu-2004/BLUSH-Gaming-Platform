using System.Net;
using System.Text.Json;
using System.Text.Json.Nodes;
using Blush.Api.Options;
using Blush.Api.Services.Interfaces;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // Gọi Gemini qua REST: POST /v1beta/models/{model}:generateContent (header x-goog-api-key)
    // Lỗi tạm thời (429 quá tải, 5xx) thì thử lại 1 lần sau 1 giây; vẫn lỗi thì trả null.
    // ============================================================
    public class GeminiTextGenerator : IAiTextGenerator
    {
        private const string BaseUrl = "https://generativelanguage.googleapis.com/v1beta/models/";

        private readonly HttpClient _http;
        private readonly GeminiOptions _options;
        private readonly ILogger<GeminiTextGenerator> _logger;

        public GeminiTextGenerator(HttpClient http, IOptions<GeminiOptions> options, ILogger<GeminiTextGenerator> logger)
        {
            _http = http;
            _options = options.Value;
            _logger = logger;
            _http.Timeout = TimeSpan.FromSeconds(_options.TimeoutSeconds);
        }

        public bool IsConfigured => _options.IsConfigured;

        public async Task<AiTextResult?> GenerateAsync(string systemPrompt, string userPrompt, bool jsonOutput, CancellationToken ct = default)
        {
            if (!IsConfigured) return null;

            var body = new JsonObject
            {
                ["systemInstruction"] = new JsonObject { ["parts"] = new JsonArray(new JsonObject { ["text"] = systemPrompt }) },
                ["contents"] = new JsonArray(new JsonObject
                {
                    ["role"] = "user",
                    ["parts"] = new JsonArray(new JsonObject { ["text"] = userPrompt }),
                }),
                ["generationConfig"] = new JsonObject
                {
                    ["temperature"] = 0.8,
                    ["maxOutputTokens"] = 600,
                    ["responseMimeType"] = jsonOutput ? "application/json" : "text/plain",
                },
            };

            for (var attempt = 1; attempt <= 2; attempt++)
            {
                try
                {
                    using var request = new HttpRequestMessage(HttpMethod.Post, $"{BaseUrl}{_options.Model}:generateContent")
                    {
                        Content = new StringContent(body.ToJsonString(), System.Text.Encoding.UTF8, "application/json"),
                    };
                    request.Headers.Add("x-goog-api-key", _options.ApiKey);
                    using var response = await _http.SendAsync(request, ct);

                    if (response.StatusCode == HttpStatusCode.TooManyRequests || (int)response.StatusCode >= 500)
                    {
                        _logger.LogWarning("Gemini tạm thời lỗi {Status} (lần {Attempt})", (int)response.StatusCode, attempt);
                        if (attempt == 1) await Task.Delay(1000, ct);
                        continue;
                    }
                    if (!response.IsSuccessStatusCode)
                    {
                        // 400/401/403: sai key, sai tên model... -> lỗi cấu hình, thử lại cũng vô ích
                        _logger.LogError("Gemini lỗi {Status}: {Body}", (int)response.StatusCode, await response.Content.ReadAsStringAsync(ct));
                        return null;
                    }

                    using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
                    var root = doc.RootElement;
                    var text = root.GetProperty("candidates")[0].GetProperty("content").GetProperty("parts")[0].GetProperty("text").GetString();
                    var tokens = root.TryGetProperty("usageMetadata", out var usage) && usage.TryGetProperty("totalTokenCount", out var total) ? total.GetInt32() : 0;
                    return string.IsNullOrWhiteSpace(text) ? null : new AiTextResult(text.Trim(), tokens);
                }
                catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or JsonException or KeyNotFoundException or InvalidOperationException or IndexOutOfRangeException)
                {
                    // Mất mạng, quá thời gian chờ, hoặc câu trả lời bị chặn bởi bộ lọc an toàn (không có "content")
                    _logger.LogWarning(ex, "Gọi Gemini thất bại (lần {Attempt})", attempt);
                    if (ct.IsCancellationRequested) return null;
                }
            }
            return null;
        }
    }
}
