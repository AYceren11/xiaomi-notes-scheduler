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
public class NotesController : BaseApiController
{
    private readonly AppDbContext _context;
    private readonly AuditService _audit;
    private readonly IWebHostEnvironment _env;

    public NotesController(AppDbContext context, AuditService audit, IWebHostEnvironment env)
    {
        _context = context;
        _audit = audit;
        _env = env;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? search,
        [FromQuery] int? categoryId,
        [FromQuery] bool? isVault,
        [FromQuery] int? userId)
    {
        var targetUserId = (IsAdmin && userId.HasValue) ? userId.Value : CurrentUserId;

        var query = _context.Notes
            .Include(n => n.Category)
            .Where(n => n.UserId == targetUserId)
            .AsQueryable();

        if (isVault.HasValue)
        {
            query = query.Where(n => n.IsVault == isVault.Value);
        }

        if (categoryId.HasValue)
        {
            query = query.Where(n => n.CategoryId == categoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(n =>
                n.Title.ToLower().Contains(term) ||
                n.ContentJson.ToLower().Contains(term));
        }

        var notes = await query
            .OrderByDescending(n => n.IsPinned)
            .ThenByDescending(n => n.UpdatedAt)
            .ToListAsync();

        return Ok(notes);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var note = await _context.Notes
            .Include(n => n.Category)
            .FirstOrDefaultAsync(n => n.Id == id);

        if (note == null)
            return NotFound(new { message = "Not bulunamadı." });

        if (!IsAdmin && note.UserId != CurrentUserId)
            return Forbid();

        return Ok(note);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateNoteDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var note = new Note
        {
            UserId = CurrentUserId,
            CategoryId = dto.CategoryId,
            Title = dto.Title.Trim(),
            ContentJson = dto.ContentJson,
            ColorHex = dto.ColorHex,
            IsPinned = dto.IsPinned,
            IsVault = dto.IsVault,
            MindMapData = dto.MindMapData,
            AudioUrl = dto.AudioUrl,
            DrawingData = dto.DrawingData,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Notes.Add(note);
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "NOTE_CREATED", "Notes", note.Id, ClientIp);

        return CreatedAtAction(nameof(GetById), new { id = note.Id }, note);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateNoteDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var note = await _context.Notes.FindAsync(id);
        if (note == null)
            return NotFound(new { message = "Not bulunamadı." });

        if (!IsAdmin && note.UserId != CurrentUserId)
            return Forbid();

        note.Title = dto.Title.Trim();
        note.ContentJson = dto.ContentJson;
        note.CategoryId = dto.CategoryId;
        note.ColorHex = dto.ColorHex;
        note.IsPinned = dto.IsPinned;
        note.IsVault = dto.IsVault;
        note.MindMapData = dto.MindMapData;
        note.AudioUrl = dto.AudioUrl;
        note.DrawingData = dto.DrawingData;
        note.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "NOTE_UPDATED", "Notes", note.Id, ClientIp);

        return Ok(note);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var note = await _context.Notes.FindAsync(id);
        if (note == null)
            return NotFound(new { message = "Not bulunamadı." });

        if (!IsAdmin && note.UserId != CurrentUserId)
            return Forbid();

        _context.Notes.Remove(note);
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "NOTE_DELETED", "Notes", id, ClientIp);

        return Ok(new { message = "Not başarıyla silindi." });
    }

    [HttpPatch("{id}/toggle-pin")]
    public async Task<IActionResult> TogglePin(int id)
    {
        var note = await _context.Notes.FindAsync(id);
        if (note == null)
            return NotFound(new { message = "Not bulunamadı." });

        if (!IsAdmin && note.UserId != CurrentUserId)
            return Forbid();

        note.IsPinned = !note.IsPinned;
        note.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(note);
    }

    [HttpPatch("{id}/toggle-vault")]
    public async Task<IActionResult> ToggleVault(int id)
    {
        var note = await _context.Notes.FindAsync(id);
        if (note == null)
            return NotFound(new { message = "Not bulunamadı." });

        if (!IsAdmin && note.UserId != CurrentUserId)
            return Forbid();

        note.IsVault = !note.IsVault;
        note.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, note.IsVault ? "NOTE_LOCKED_IN_VAULT" : "NOTE_UNLOCKED_FROM_VAULT", "Notes", note.Id, ClientIp);

        return Ok(note);
    }

    [HttpPost("upload-audio")]
    [RequestSizeLimit(25 * 1024 * 1024)]
    public async Task<IActionResult> UploadAudio(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = "Ses dosyası bulunamadı." });

        var allowedExts = new[] { ".m4a", ".aac", ".wav", ".mp3", ".ogg", ".opus" };
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (string.IsNullOrEmpty(ext) || !allowedExts.Contains(ext))
        {
            ext = ".m4a";
        }

        var webRoot = string.IsNullOrEmpty(_env.WebRootPath)
            ? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot")
            : _env.WebRootPath;
        var uploadDir = Path.Combine(webRoot, "uploads", "audio");
        Directory.CreateDirectory(uploadDir);

        var fileName = $"voice_{CurrentUserId}_{Guid.NewGuid():N}{ext}";
        var fullPath = Path.Combine(uploadDir, fileName);

        await using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        var relativeUrl = $"/uploads/audio/{fileName}";
        await _audit.LogAsync(CurrentUserId, "AUDIO_UPLOADED", "Notes", 0, ClientIp);
        return Ok(new { audioUrl = relativeUrl });
    }
}
