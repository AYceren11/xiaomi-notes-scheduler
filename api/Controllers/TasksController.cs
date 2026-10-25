using Api.Data;
using Api.DTOs;
using Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TasksController : ControllerBase
{
    private readonly AppDbContext _context;

    public TasksController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int? userId)
    {
        var query = _context.Tasks.AsQueryable();

        if (userId.HasValue)
        {
            query = query.Where(t => t.UserId == userId.Value);
        }

        var tasks = await query.OrderBy(t => t.OrderIndex)
                               .ThenBy(t => t.CreatedAt)
                               .ToListAsync();

        return Ok(tasks);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null)
        {
            return NotFound(new { message = "Görev bulunamadı." });
        }
        return Ok(task);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTaskDto dto, [FromQuery] int? userId)
    {
        int targetUserId = userId ?? 2;

        var maxOrder = await _context.Tasks
            .Where(t => t.UserId == targetUserId && t.ParentId == dto.ParentId)
            .Select(t => (int?)t.OrderIndex)
            .MaxAsync() ?? -1;

        var task = new TaskItem
        {
            UserId = targetUserId,
            NoteId = dto.NoteId,
            ParentId = dto.ParentId,
            Title = dto.Title,
            Priority = dto.Priority,
            DueDate = dto.DueDate,
            IsCompleted = false,
            OrderIndex = maxOrder + 1,
            CreatedAt = DateTime.UtcNow
        };

        _context.Tasks.Add(task);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = task.Id }, task);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateTaskDto dto)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null)
        {
            return NotFound(new { message = "Görev bulunamadı." });
        }

        task.Title = dto.Title;
        task.IsCompleted = dto.IsCompleted;
        task.Priority = dto.Priority;
        task.DueDate = dto.DueDate;
        task.ParentId = dto.ParentId;
        task.OrderIndex = dto.OrderIndex;

        if (task.IsCompleted && task.CompletedAt == null)
        {
            task.CompletedAt = DateTime.UtcNow;
        }
        else if (!task.IsCompleted)
        {
            task.CompletedAt = null;
        }

        await _context.SaveChangesAsync();
        return Ok(task);
    }

    [HttpPatch("{id}/toggle-complete")]
    public async Task<IActionResult> ToggleComplete(int id)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null)
        {
            return NotFound(new { message = "Görev bulunamadı." });
        }

        task.IsCompleted = !task.IsCompleted;
        task.CompletedAt = task.IsCompleted ? DateTime.UtcNow : null;

        await _context.SaveChangesAsync();
        return Ok(task);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null)
        {
            return NotFound(new { message = "Görev bulunamadı." });
        }

        // Also delete subtasks if any
        var subtasks = await _context.Tasks.Where(t => t.ParentId == id).ToListAsync();
        _context.Tasks.RemoveRange(subtasks);

        _context.Tasks.Remove(task);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Görev ve alt görevleri başarıyla silindi." });
    }
}
