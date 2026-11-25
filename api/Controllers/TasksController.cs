using Api.Data;
using Api.DTOs;
using Api.Models;
using Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class TasksController : BaseApiController
{
    private readonly AppDbContext _context;
    private readonly AuditService _audit;

    public TasksController(AppDbContext context, AuditService audit)
    {
        _context = context;
        _audit = audit;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int? userId, [FromQuery] bool flat = false)
    {
        var targetUserId = (IsAdmin && userId.HasValue) ? userId.Value : CurrentUserId;

        var allTasks = await _context.Tasks
            .Where(t => t.UserId == targetUserId)
            .OrderBy(t => t.OrderIndex)
            .ThenBy(t => t.CreatedAt)
            .ToListAsync();

        if (flat)
        {
            return Ok(allTasks);
        }

        var lookup = allTasks.Where(t => t.ParentId.HasValue).GroupBy(t => t.ParentId!.Value).ToDictionary(g => g.Key, g => g.ToList());
        var roots = allTasks.Where(t => t.ParentId == null).Select(t => new
        {
            t.Id,
            t.UserId,
            t.NoteId,
            t.ParentId,
            t.Title,
            t.IsCompleted,
            t.Priority,
            t.OrderIndex,
            t.DueDate,
            t.CreatedAt,
            t.CompletedAt,
            Subtasks = lookup.TryGetValue(t.Id, out var children) ? children : new List<TaskItem>()
        }).ToList();

        return Ok(roots);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null)
            return NotFound(new { message = "Görev bulunamadı." });

        if (!IsAdmin && task.UserId != CurrentUserId)
            return Forbid();

        return Ok(task);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTaskDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var maxOrder = await _context.Tasks
            .Where(t => t.UserId == CurrentUserId && t.ParentId == dto.ParentId)
            .Select(t => (int?)t.OrderIndex)
            .MaxAsync() ?? -1;

        var task = new TaskItem
        {
            UserId = CurrentUserId,
            NoteId = dto.NoteId,
            ParentId = dto.ParentId,
            Title = dto.Title.Trim(),
            Priority = dto.Priority,
            DueDate = dto.DueDate,
            IsCompleted = false,
            OrderIndex = maxOrder + 1,
            CreatedAt = DateTime.UtcNow
        };

        _context.Tasks.Add(task);
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "TASK_CREATED", "Tasks", task.Id, ClientIp);

        return CreatedAtAction(nameof(GetById), new { id = task.Id }, task);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateTaskDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var task = await _context.Tasks.FindAsync(id);
        if (task == null)
            return NotFound(new { message = "Görev bulunamadı." });

        if (!IsAdmin && task.UserId != CurrentUserId)
            return Forbid();

        task.Title = dto.Title.Trim();
        task.IsCompleted = dto.IsCompleted;
        task.Priority = dto.Priority;
        task.DueDate = dto.DueDate;
        task.NoteId = dto.NoteId;
        task.ParentId = dto.ParentId;
        task.OrderIndex = dto.OrderIndex;

        if (task.IsCompleted && task.CompletedAt == null)
            task.CompletedAt = DateTime.UtcNow;
        else if (!task.IsCompleted)
            task.CompletedAt = null;

        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "TASK_UPDATED", "Tasks", task.Id, ClientIp);

        return Ok(task);
    }

    [HttpPatch("{id}/toggle-complete")]
    public async Task<IActionResult> ToggleComplete(int id)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null)
            return NotFound(new { message = "Görev bulunamadı." });

        if (!IsAdmin && task.UserId != CurrentUserId)
            return Forbid();

        task.IsCompleted = !task.IsCompleted;
        task.CompletedAt = task.IsCompleted ? DateTime.UtcNow : null;

        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, task.IsCompleted ? "TASK_COMPLETED" : "TASK_REOPENED", "Tasks", task.Id, ClientIp);

        return Ok(task);
    }

    [HttpPatch("reorder")]
    public async Task<IActionResult> Reorder([FromBody] ReorderTasksDto dto)
    {
        if (!ModelState.IsValid || dto.Items == null || dto.Items.Count == 0)
            return BadRequest(new { message = "Sıralama listesi boş olamaz." });

        var ids = dto.Items.Select(i => i.Id).ToList();
        var tasks = await _context.Tasks
            .Where(t => ids.Contains(t.Id) && (IsAdmin || t.UserId == CurrentUserId))
            .ToListAsync();

        var map = tasks.ToDictionary(t => t.Id);
        foreach (var item in dto.Items)
        {
            if (map.TryGetValue(item.Id, out var task))
            {
                task.OrderIndex = item.OrderIndex;
                if (item.ParentId != task.Id)
                {
                    task.ParentId = item.ParentId;
                }
            }
        }

        await _context.SaveChangesAsync();
        return Ok(new { message = "Görev sırası güncellendi." });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null)
            return NotFound(new { message = "Görev bulunamadı." });

        if (!IsAdmin && task.UserId != CurrentUserId)
            return Forbid();

        var subtasks = await _context.Tasks.Where(t => t.ParentId == id).ToListAsync();
        _context.Tasks.RemoveRange(subtasks);

        _context.Tasks.Remove(task);
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "TASK_DELETED", "Tasks", id, ClientIp);

        return Ok(new { message = "Görev ve alt görevleri başarıyla silindi." });
    }
}
