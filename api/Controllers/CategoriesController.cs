using Api.Data;
using Api.DTOs;
using Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CategoriesController : ControllerBase
{
    private readonly AppDbContext _context;

    public CategoriesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int? userId)
    {
        var query = _context.Categories.AsQueryable();
        if (userId.HasValue)
        {
            query = query.Where(c => c.UserId == userId.Value);
        }
        var list = await query.ToListAsync();
        return Ok(list);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CategoryDto dto, [FromQuery] int? userId)
    {
        int targetUserId = userId ?? 2;
        var category = new Category
        {
            UserId = targetUserId,
            Name = dto.Name,
            ColorCode = dto.ColorCode,
            Icon = dto.Icon,
            CreatedAt = DateTime.UtcNow
        };

        _context.Categories.Add(category);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAll), new { id = category.Id }, category);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var cat = await _context.Categories.FindAsync(id);
        if (cat == null) return NotFound();

        _context.Categories.Remove(cat);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Kategori silindi." });
    }
}
