using Api.Data;
using Api.DTOs;
using Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/[controller]")]
public class AdminController : BaseApiController
{
    private readonly AppDbContext _context;
    private readonly AuditService _audit;

    public AdminController(AppDbContext context, AuditService audit)
    {
        _context = context;
        _audit = audit;
    }

    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var totalUsers = await _context.Users.CountAsync();
        var activeUsers = await _context.Users.CountAsync(u => u.IsActive);
        var totalNotes = await _context.Notes.CountAsync();
        var vaultNotes = await _context.Notes.CountAsync(n => n.IsVault);
        var totalTasks = await _context.Tasks.CountAsync();
        var completedTasks = await _context.Tasks.CountAsync(t => t.IsCompleted);
        var totalSchedules = await _context.Schedules.CountAsync();
        var totalCategories = await _context.Categories.CountAsync();

        var recentLogs = await _context.AuditLogs
            .Include(l => l.User)
            .OrderByDescending(l => l.Timestamp)
            .Take(20)
            .Select(l => new
            {
                l.Id,
                l.UserId,
                UserName = l.User != null ? l.User.FullName : "Sistem",
                l.Action,
                l.EntityName,
                l.RecordId,
                l.Timestamp,
                l.IpAddress
            })
            .ToListAsync();

        return Ok(new
        {
            TotalUsers = totalUsers,
            ActiveUsers = activeUsers,
            TotalNotes = totalNotes,
            VaultNotes = vaultNotes,
            TotalTasks = totalTasks,
            CompletedTasks = completedTasks,
            TotalSchedules = totalSchedules,
            TotalCategories = totalCategories,
            RecentLogs = recentLogs
        });
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers()
    {
        var users = await _context.Users
            .OrderByDescending(u => u.CreatedAt)
            .Select(u => new
            {
                u.Id,
                u.FullName,
                u.Email,
                u.Role,
                u.IsActive,
                u.CreatedAt,
                NotesCount = u.Notes.Count,
                TasksCount = u.Tasks.Count,
                SchedulesCount = u.Schedules.Count
            })
            .ToListAsync();

        return Ok(users);
    }

    [HttpGet("notes")]
    public async Task<IActionResult> GetAllNotes()
    {
        var notes = await _context.Notes
            .Include(n => n.User)
            .Include(n => n.Category)
            .OrderByDescending(n => n.UpdatedAt)
            .Select(n => new
            {
                n.Id,
                n.Title,
                n.IsVault,
                n.IsPinned,
                n.ColorHex,
                n.UpdatedAt,
                CategoryName = n.Category != null ? n.Category.Name : "Klasörsüz",
                AuthorName = n.User != null ? n.User.FullName : "Bilinmiyor",
                AuthorEmail = n.User != null ? n.User.Email : ""
            })
            .ToListAsync();

        return Ok(notes);
    }

    [HttpDelete("notes/{id}")]
    public async Task<IActionResult> DeleteAnyNote(int id)
    {
        var note = await _context.Notes.FindAsync(id);
        if (note == null) return NotFound(new { message = "Not bulunamadı." });

        _context.Notes.Remove(note);
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "ADMIN_NOTE_DELETED", "Notes", id, ClientIp);

        return Ok(new { message = "Not yönetici tarafından silindi." });
    }

    [HttpGet("audit-logs")]
    public async Task<IActionResult> GetAuditLogs()
    {
        var logs = await _context.AuditLogs
            .Include(l => l.User)
            .OrderByDescending(l => l.Timestamp)
            .Take(100)
            .Select(l => new
            {
                l.Id,
                l.UserId,
                UserName = l.User != null ? l.User.FullName : "Sistem",
                l.Action,
                l.EntityName,
                l.RecordId,
                l.Timestamp,
                l.IpAddress
            })
            .ToListAsync();

        return Ok(logs);
    }

    [HttpPost("users/{id}/toggle-status")]
    public async Task<IActionResult> ToggleUserStatus(int id)
    {
        if (id == CurrentUserId)
            return BadRequest(new { message = "Kendi hesabınızı pasif yapamazsınız." });

        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Kullanıcı bulunamadı." });

        user.IsActive = !user.IsActive;
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, user.IsActive ? "ADMIN_USER_ACTIVATED" : "ADMIN_USER_DEACTIVATED", "Users", user.Id, ClientIp);

        return Ok(new
        {
            user.Id,
            user.IsActive,
            message = $"Kullanıcı durumu güncellendi: {(user.IsActive ? "Aktif" : "Pasif")}"
        });
    }

    [HttpPatch("users/{id}/role")]
    public async Task<IActionResult> ChangeUserRole(int id, [FromBody] UpdateUserRoleDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);
        if (id == CurrentUserId)
            return BadRequest(new { message = "Kendi rolünüzü değiştiremezsiniz." });

        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Kullanıcı bulunamadı." });

        user.Role = string.Equals(dto.Role, "Admin", StringComparison.OrdinalIgnoreCase) ? "Admin" : "User";
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, $"ADMIN_ROLE_CHANGED_TO_{user.Role.ToUpperInvariant()}", "Users", user.Id, ClientIp);

        return Ok(new { user.Id, user.Role, message = $"Kullanıcı rolü '{user.Role}' olarak güncellendi." });
    }

    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        if (id == CurrentUserId)
            return BadRequest(new { message = "Kendi yönetici hesabınızı silemezsiniz." });

        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Kullanıcı bulunamadı." });

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "ADMIN_USER_DELETED", "Users", id, ClientIp);

        return Ok(new { message = "Kullanıcı başarıyla silindi." });
    }
}
