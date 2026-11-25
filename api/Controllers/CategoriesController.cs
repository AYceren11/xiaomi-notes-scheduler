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
public class CategoriesController : BaseApiController
{
    private readonly AppDbContext _context;
    private readonly AuditService _audit;

    public CategoriesController(AppDbContext context, AuditService audit)
    {
        _context = context;
        _audit = audit;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int? userId)
    {
        var targetUserId = (IsAdmin && userId.HasValue) ? userId.Value : CurrentUserId;
        var list = await _context.Categories
            .Where(c => c.UserId == targetUserId)
            .OrderBy(c => c.CreatedAt)
            .ToListAsync();
        return Ok(list);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var cat = await _context.Categories.FindAsync(id);
        if (cat == null) return NotFound(new { message = "Kategori bulunamadı." });
        if (!IsAdmin && cat.UserId != CurrentUserId) return Forbid();
        return Ok(cat);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CategoryDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var category = new Category
        {
            UserId = CurrentUserId,
            Name = dto.Name.Trim(),
            ColorCode = dto.ColorCode,
            Icon = dto.Icon,
            CreatedAt = DateTime.UtcNow
        };

        _context.Categories.Add(category);
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "CATEGORY_CREATED", "Categories", category.Id, ClientIp);

        return CreatedAtAction(nameof(GetById), new { id = category.Id }, category);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CategoryDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var cat = await _context.Categories.FindAsync(id);
        if (cat == null) return NotFound(new { message = "Kategori bulunamadı." });
        if (!IsAdmin && cat.UserId != CurrentUserId) return Forbid();

        cat.Name = dto.Name.Trim();
        cat.ColorCode = dto.ColorCode;
        cat.Icon = dto.Icon;

        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "CATEGORY_UPDATED", "Categories", cat.Id, ClientIp);

        return Ok(cat);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var cat = await _context.Categories.FindAsync(id);
        if (cat == null) return NotFound(new { message = "Kategori bulunamadı." });
        if (!IsAdmin && cat.UserId != CurrentUserId) return Forbid();

        _context.Categories.Remove(cat);
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "CATEGORY_DELETED", "Categories", id, ClientIp);

        return Ok(new { message = "Kategori başarıyla silindi." });
    }
}
