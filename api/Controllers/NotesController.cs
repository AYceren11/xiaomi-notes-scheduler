using Api.Data;
using Api.DTOs;
using Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class NotesController : ControllerBase
{
    private readonly AppDbContext _context;

    public NotesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? search, [FromQuery] int? categoryId, [FromQuery] int? userId)
    {
        var query = _context.Notes.Include(n => n.Category).AsQueryable();

        if (userId.HasValue)
        {
            query = query.Where(n => n.UserId == userId.Value);
        }

        if (categoryId.HasValue)
        {
            query = query.Where(n => n.CategoryId == categoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(n => n.Title.Contains(search) || n.ContentJson.Contains(search));
        }

        var notes = await query.OrderByDescending(n => n.IsPinned)
                               .ThenByDescending(n => n.UpdatedAt)
                               .ToListAsync();

        return Ok(notes);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var note = await _context.Notes.Include(n => n.Category).FirstOrDefaultAsync(n => n.Id == id);
        if (note == null)
        {
            return NotFound(new { message = "Not bulunamadı." });
        }
        return Ok(note);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateNoteDto dto, [FromQuery] int? userId)
    {
        int targetUserId = userId ?? 2; // Default to seeded student user

        var note = new Note
        {
            UserId = targetUserId,
            CategoryId = dto.CategoryId,
            Title = dto.Title,
            ContentJson = dto.ContentJson,
            ColorHex = dto.ColorHex,
            IsPinned = dto.IsPinned,
            IsVault = dto.IsVault,
            MindMapData = dto.MindMapData,
            AudioUrl = dto.AudioUrl,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Notes.Add(note);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = note.Id }, note);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateNoteDto dto)
    {
        var note = await _context.Notes.FindAsync(id);
        if (note == null)
        {
            return NotFound(new { message = "Not bulunamadı." });
        }

        note.Title = dto.Title;
        note.ContentJson = dto.ContentJson;
        note.CategoryId = dto.CategoryId;
        note.ColorHex = dto.ColorHex;
        note.IsPinned = dto.IsPinned;
        note.IsVault = dto.IsVault;
        note.MindMapData = dto.MindMapData;
        note.AudioUrl = dto.AudioUrl;
        note.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return Ok(note);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var note = await _context.Notes.FindAsync(id);
        if (note == null)
        {
            return NotFound(new { message = "Not bulunamadı." });
        }

        _context.Notes.Remove(note);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Not başarıyla silindi." });
    }

    [HttpPatch("{id}/toggle-pin")]
    public async Task<IActionResult> TogglePin(int id)
    {
        var note = await _context.Notes.FindAsync(id);
        if (note == null)
        {
            return NotFound(new { message = "Not bulunamadı." });
        }

        note.IsPinned = !note.IsPinned;
        note.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(note);
    }
}
