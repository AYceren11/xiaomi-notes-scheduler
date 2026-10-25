using Api.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _context;

    public AdminController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var totalUsers = await _context.Users.CountAsync();
        var totalNotes = await _context.Notes.CountAsync();
        var totalTasks = await _context.Tasks.CountAsync();
        var completedTasks = await _context.Tasks.CountAsync(t => t.IsCompleted);
        var totalCategories = await _context.Categories.CountAsync();
        var recentLogs = await _context.AuditLogs.OrderByDescending(l => l.Timestamp).Take(5).ToListAsync();

        return Ok(new
        {
            TotalUsers = totalUsers,
            TotalNotes = totalNotes,
            TotalTasks = totalTasks,
            CompletedTasks = completedTasks,
            TotalCategories = totalCategories,
            RecentLogs = recentLogs
        });
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers()
    {
        var users = await _context.Users
            .Select(u => new
            {
                u.Id,
                u.FullName,
                u.Email,
                u.Role,
                u.IsActive,
                u.CreatedAt,
                NotesCount = u.Notes.Count,
                TasksCount = u.Tasks.Count
            })
            .ToListAsync();

        return Ok(users);
    }

    [HttpGet("audit-logs")]
    public async Task<IActionResult> GetAuditLogs()
    {
        var logs = await _context.AuditLogs
            .Include(l => l.User)
            .OrderByDescending(l => l.Timestamp)
            .Take(50)
            .ToListAsync();

        return Ok(logs);
    }

    [HttpPost("users/{id}/toggle-status")]
    public async Task<IActionResult> ToggleUserStatus(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();

        user.IsActive = !user.IsActive;
        await _context.SaveChangesAsync();

        return Ok(new { message = $"Kullanıcı durumu güncellendi: {(user.IsActive ? "Aktif" : "Pasif")}" });
    }
}
