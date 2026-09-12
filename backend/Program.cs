using Blush.Api.DataAccess;
using Blush.Api.Services.Implementations;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// 1. Đăng ký CSDL SQL Server EF Core
builder.Services.AddDbContext<BlushDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection") 
        ?? "Server=(localdb)\\mssqllocaldb;Database=BlushDb;Trusted_Connection=True;MultipleActiveResultSets=true"));

// 2. Đăng ký các Services theo mô hình 3 Layer (Dependency Injection)
builder.Services.AddScoped<IQuestService, QuestService>();

// 3. Đăng ký Controllers & Swagger API Documentation
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 4. Đăng ký CORS cho phép React Frontend (port 5173) gọi API
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowReactApp", policy =>
    {
        policy.WithOrigins("http://localhost:5173", "http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

// Enable Swagger UI trong môi trường Dev
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowReactApp");
app.UseAuthorization();
app.MapControllers();

app.Run();
