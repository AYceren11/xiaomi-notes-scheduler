using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Api.Data;
using Api.DTOs;
using Api.Models;
using Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : BaseApiController
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly AuditService _audit;

    public AuthController(AppDbContext context, IConfiguration configuration, AuditService audit)
    {
        _context = context;
        _configuration = configuration;
        _audit = audit;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var normalizedEmail = dto.Email.Trim().ToLowerInvariant();
        if (await _context.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail))
        {
            return BadRequest(new { message = "Bu e-posta adresi zaten kayıtlı." });
        }

        var user = new User
        {
            FullName = dto.FullName.Trim(),
            Email = normalizedEmail,
            PasswordHash = DbInitializer.BCryptOrSimpleHash(dto.Password),
            Role = string.Equals(dto.Role, "Admin", StringComparison.OrdinalIgnoreCase) ? "Admin" : "User",
            CreatedAt = DateTime.UtcNow,
            IsActive = true
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        // Create default Xiaomi folders for the new user
        _context.Categories.AddRange(
            new Category { UserId = user.Id, Name = "Önemli", ColorCode = "#FF6900", Icon = "star" },
            new Category { UserId = user.Id, Name = "İş", ColorCode = "#2196F3", Icon = "work" },
            new Category { UserId = user.Id, Name = "Kişisel", ColorCode = "#4CAF50", Icon = "person" },
            new Category { UserId = user.Id, Name = "Dersler", ColorCode = "#9C27B0", Icon = "book" }
        );
        await _context.SaveChangesAsync();

        await _audit.LogAsync(user.Id, "USER_REGISTERED", "Users", user.Id, ClientIp);

        var token = GenerateJwtToken(user);
        return Ok(new AuthResponseDto(user.Id, user.FullName, user.Email, user.Role, token));
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var hash = DbInitializer.BCryptOrSimpleHash(dto.Password);
        var normalizedEmail = dto.Email.Trim().ToLowerInvariant();
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail);

        if (user == null || user.PasswordHash != hash)
        {
            return Unauthorized(new { message = "E-posta veya şifre hatalı." });
        }

        if (!user.IsActive)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = "Hesabınız yönetici tarafından pasif hale getirilmiştir." });
        }

        await _audit.LogAsync(user.Id, "LOGIN_SUCCESS", "Users", user.Id, ClientIp);

        var token = GenerateJwtToken(user);
        return Ok(new AuthResponseDto(user.Id, user.FullName, user.Email, user.Role, token));
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var user = await _context.Users
            .Where(u => u.Id == CurrentUserId)
            .Select(u => new
            {
                u.Id,
                u.FullName,
                u.Email,
                u.Role,
                u.IsActive,
                u.CreatedAt
            })
            .FirstOrDefaultAsync();

        if (user == null)
            return NotFound(new { message = "Kullanıcı bulunamadı." });

        return Ok(user);
    }

    private string GenerateJwtToken(User user)
    {
        var jwtKey = _configuration["Jwt:Key"];
        if (string.IsNullOrWhiteSpace(jwtKey))
            jwtKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY");
        if (string.IsNullOrWhiteSpace(jwtKey))
            throw new InvalidOperationException("JWT gizli anahtarı tanımlı değil.");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim(ClaimTypes.Role, user.Role)
        };

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"] ?? "XiaomiNotesApi",
            audience: _configuration["Jwt:Audience"] ?? "XiaomiNotesClient",
            claims: claims,
            expires: DateTime.UtcNow.AddDays(30),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
