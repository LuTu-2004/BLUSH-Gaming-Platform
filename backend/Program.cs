using System.Text;
using Blush.Api.DataAccess;
using Blush.Api.Options;
using Blush.Api.Services.Implementations;
using Blush.Api.Services.Interfaces;
using Blush.Api.Services.Payments;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// 1. Đăng ký CSDL SQL Server EF Core (chuỗi kết nối nằm trong appsettings.json)
builder.Services.AddDbContext<BlushDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// 2. Đọc cấu hình JWT & Google từ appsettings.json
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection(JwtOptions.SectionName));
builder.Services.Configure<GoogleAuthOptions>(builder.Configuration.GetSection(GoogleAuthOptions.SectionName));
builder.Services.Configure<SmtpOptions>(builder.Configuration.GetSection(SmtpOptions.SectionName));
builder.Services.Configure<PaymentOptions>(builder.Configuration.GetSection(PaymentOptions.SectionName));
var jwt = builder.Configuration.GetSection(JwtOptions.SectionName).Get<JwtOptions>()
    ?? throw new InvalidOperationException("Thiếu mục 'Jwt' trong appsettings.json");
if (jwt.SigningKey.Length < 32)
{
    throw new InvalidOperationException("Jwt:SigningKey phải dài ít nhất 32 ký tự");
}

// 3. Đăng ký các Services theo mô hình 3 Layer (Dependency Injection)
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IQuestService, QuestService>();
builder.Services.AddScoped<IOtpService, OtpService>();
builder.Services.AddScoped<ITrustedDeviceService, TrustedDeviceService>();
builder.Services.AddScoped<IOnboardingService, OnboardingService>();
// Ghép đội: đổi sang class dùng AI (VD: GeminiMatchingService) ở dòng này khi tích hợp AI
builder.Services.AddScoped<IMatchingService, RuleBasedMatchingService>();

// Thanh toán: mỗi cổng 1 class (Services/Payments). Chế độ Mock/Sandbox chỉnh ở mục "Payment" trong appsettings.json
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddHttpClient<MomoGateway>(c => c.Timeout = TimeSpan.FromSeconds(20));
builder.Services.AddHttpClient<ZaloPayGateway>(c => c.Timeout = TimeSpan.FromSeconds(20));
builder.Services.AddSingleton<VnPayGateway>();
builder.Services.AddSingleton<VietQrGateway>();
builder.Services.AddTransient<IPaymentGateway>(sp => sp.GetRequiredService<MomoGateway>());
builder.Services.AddTransient<IPaymentGateway>(sp => sp.GetRequiredService<VnPayGateway>());
builder.Services.AddTransient<IPaymentGateway>(sp => sp.GetRequiredService<ZaloPayGateway>());
builder.Services.AddTransient<IPaymentGateway>(sp => sp.GetRequiredService<VietQrGateway>());
builder.Services.AddSingleton<ITokenService, TokenService>();
builder.Services.AddSingleton<IGoogleTokenValidator, GoogleTokenValidator>();

// Gửi email: đã cấu hình SMTP thì gửi thật, chưa thì in mã OTP ra terminal (tiện khi dev)
var smtp = builder.Configuration.GetSection(SmtpOptions.SectionName).Get<SmtpOptions>() ?? new SmtpOptions();
if (smtp.IsConfigured)
{
    builder.Services.AddSingleton<IEmailSender, SmtpEmailSender>();
}
else
{
    builder.Services.AddSingleton<IEmailSender, ConsoleEmailSender>();
}

// 4. Xác thực bằng JWT: request có header "Authorization: Bearer <token>" mới vào được API có [Authorize]
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false; // giữ nguyên tên claim "sub", "role" như lúc tạo token
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwt.Issuer,
            ValidateAudience = true,
            ValidAudience = jwt.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.SigningKey)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1),
            NameClaimType = "sub",
            RoleClaimType = "role",
        };
    });
builder.Services.AddAuthorization();

// 5. Controllers & Swagger (có nút "Authorize" để dán token khi test API)
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Dán accessToken lấy từ api/auth/login",
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } },
            Array.Empty<string>()
        }
    });
});

// 6. CORS: app Flutter trên điện thoại không cần CORS, nhưng Flutter Web (chạy trên Chrome)
//    dùng cổng ngẫu nhiên nên lúc dev cho phép mọi origin.
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevCors", policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseCors("DevCors");
}
else
{
    // Lúc dev, máy ảo Android gọi http://10.0.2.2:5000 nên không ép sang HTTPS
    app.UseHttpsRedirection();
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
