using System.Text;
using System.Text.Json.Serialization;
using Api.Data;
using Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// 1. Add DbContext (PostgreSQL + EF Core ORM)
var pgConn = builder.Configuration.GetConnectionString("PostgreSql");
if (string.IsNullOrWhiteSpace(pgConn))
    pgConn = Environment.GetEnvironmentVariable("ConnectionStrings__PostgreSql");
if (string.IsNullOrWhiteSpace(pgConn))
    throw new InvalidOperationException("PostgreSQL bağlantı dizesi tanımlı değil. Lütfen appsettings.Development.json içine 'ConnectionStrings:PostgreSql' ekleyin.");

builder.Services.AddDbContext<AppDbContext>(options => options.UseNpgsql(pgConn));

builder.Services.AddScoped<AuditService>();

// 2. Add JWT Authentication & Role-Based Authorization
var jwtKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKey))
    jwtKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY");
if (string.IsNullOrWhiteSpace(jwtKey))
    throw new InvalidOperationException("JWT gizli anahtarı tanımlı değil. Lütfen appsettings.Development.json içine 'Jwt:Key' veya JWT_SECRET_KEY ortam değişkeni ekleyin.");
var keyBytes = Encoding.UTF8.GetBytes(jwtKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "XiaomiNotesApi",
        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"] ?? "XiaomiNotesClient",
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("UserOnly", policy => policy.RequireRole("User"));
});

// 3. Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 4. Add Controllers with Cycle-Safe JSON Serialization
builder.Services.AddControllers()
    .AddJsonOptions(opts =>
    {
        opts.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        opts.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
    });

// 5. Add Swagger / OpenAPI with JWT Bearer Auth
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Xiaomi Notes & Scheduler API",
        Version = "v1",
        Description = "BLM4587 Dönem Projesi Web API Katmanı — Notes, Tasks, Schedules, Categories, Users & Admin CRUD"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Örnek: 'Bearer {token}'",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// Ensure wwwroot/uploads exists for voice notes
var uploadsDir = Path.Combine(app.Environment.ContentRootPath, "wwwroot", "uploads", "audio");
Directory.CreateDirectory(uploadsDir);

// 6. Apply EF Core Migrations & Seed Database on startup
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    try
    {
        DbInitializer.Initialize(context);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Database initialization error: {ex.Message}");
    }
}

// 7. HTTP Request Pipeline
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Xiaomi Notes & Scheduler API v1");
    c.RoutePrefix = "swagger";
});

app.UseStaticFiles();
app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Health check endpoint for quick mobile connection testing
app.MapGet("/api/health", () => Results.Ok(new
{
    status = "ok",
    service = "Xiaomi Notes & Scheduler API",
    database = "PostgreSQL",
    timestamp = DateTime.UtcNow
}));

app.Run();
