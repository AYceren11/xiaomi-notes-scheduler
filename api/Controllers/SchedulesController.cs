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
public class SchedulesController : BaseApiController
{
    private readonly AppDbContext _context;
    private readonly AuditService _audit;

    public SchedulesController(AppDbContext context, AuditService audit)
    {
        _context = context;
        _audit = audit;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] DateTime? date,
        [FromQuery] int? year,
        [FromQuery] int? month,
        [FromQuery] DateTime? startDate,
        [FromQuery] DateTime? endDate,
        [FromQuery] int? userId)
    {
        var targetUserId = (IsAdmin && userId.HasValue) ? userId.Value : CurrentUserId;

        var query = _context.Schedules
            .Include(s => s.Task)
            .Where(s => s.UserId == targetUserId)
            .AsQueryable();

        if (date.HasValue)
        {
            var d = date.Value.Date;
            query = query.Where(s => s.EventDate.Date == d);
        }
        else if (startDate.HasValue && endDate.HasValue)
        {
            var sDate = startDate.Value.Date;
            var eDate = endDate.Value.Date;
            query = query.Where(s => s.EventDate.Date >= sDate && s.EventDate.Date <= eDate);
        }
        else if (year.HasValue && month.HasValue)
        {
            query = query.Where(s => s.EventDate.Year == year.Value && s.EventDate.Month == month.Value);
        }
        else if (year.HasValue)
        {
            query = query.Where(s => s.EventDate.Year == year.Value);
        }

        var items = (await query
            .OrderBy(s => s.EventDate)
            .ToListAsync())
            .OrderBy(s => s.EventDate)
            .ThenBy(s => s.StartTime)
            .ToList();

        var result = items.Select(MapSchedule).ToList();
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var item = await _context.Schedules
            .Include(s => s.Task)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (item == null)
            return NotFound(new { message = "Zamanlayıcı kaydı bulunamadı." });

        if (!IsAdmin && item.UserId != CurrentUserId)
            return Forbid();

        return Ok(MapSchedule(item));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateScheduleDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        if (!TryParseTime(dto.StartTime, out var start) || !TryParseTime(dto.EndTime, out var end))
        {
            return BadRequest(new { message = "Saat formatı geçersiz. Örnek: 09:00 veya 14:30" });
        }

        if (end <= start)
        {
            return BadRequest(new { message = "Bitiş saati başlangıç saatinden sonra olmalıdır." });
        }

        var schedule = new Schedule
        {
            UserId = CurrentUserId,
            TaskId = dto.TaskId,
            Title = dto.Title.Trim(),
            StartTime = start,
            EndTime = end,
            EventDate = DateTime.SpecifyKind(dto.EventDate.Date, DateTimeKind.Utc),
            ReminderMinutes = dto.ReminderMinutes,
            ColorCode = dto.ColorCode
        };

        _context.Schedules.Add(schedule);
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "SCHEDULE_CREATED", "Schedules", schedule.Id, ClientIp);

        var created = await _context.Schedules.Include(s => s.Task).FirstAsync(s => s.Id == schedule.Id);
        return CreatedAtAction(nameof(GetById), new { id = schedule.Id }, MapSchedule(created));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateScheduleDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var schedule = await _context.Schedules.FindAsync(id);
        if (schedule == null)
            return NotFound(new { message = "Zamanlayıcı kaydı bulunamadı." });

        if (!IsAdmin && schedule.UserId != CurrentUserId)
            return Forbid();

        if (!TryParseTime(dto.StartTime, out var start) || !TryParseTime(dto.EndTime, out var end))
        {
            return BadRequest(new { message = "Saat formatı geçersiz. Örnek: 09:00" });
        }

        if (end <= start)
        {
            return BadRequest(new { message = "Bitiş saati başlangıç saatinden sonra olmalıdır." });
        }

        schedule.Title = dto.Title.Trim();
        schedule.StartTime = start;
        schedule.EndTime = end;
        schedule.EventDate = DateTime.SpecifyKind(dto.EventDate.Date, DateTimeKind.Utc);
        schedule.TaskId = dto.TaskId;
        schedule.ReminderMinutes = dto.ReminderMinutes;
        schedule.ColorCode = dto.ColorCode;

        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "SCHEDULE_UPDATED", "Schedules", schedule.Id, ClientIp);

        var updated = await _context.Schedules.Include(s => s.Task).FirstAsync(s => s.Id == schedule.Id);
        return Ok(MapSchedule(updated));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var schedule = await _context.Schedules.FindAsync(id);
        if (schedule == null)
            return NotFound(new { message = "Zamanlayıcı kaydı bulunamadı." });

        if (!IsAdmin && schedule.UserId != CurrentUserId)
            return Forbid();

        _context.Schedules.Remove(schedule);
        await _context.SaveChangesAsync();
        await _audit.LogAsync(CurrentUserId, "SCHEDULE_DELETED", "Schedules", id, ClientIp);

        return Ok(new { message = "Zamanlayıcı kaydı başarıyla silindi." });
    }

    private static bool TryParseTime(string input, out TimeSpan result)
    {
        if (TimeSpan.TryParse(input, out result))
            return true;

        var parts = input.Split(':');
        if (parts.Length >= 2 && int.TryParse(parts[0], out var h) && int.TryParse(parts[1], out var m))
        {
            if (h == 24 && m == 0)
            {
                result = new TimeSpan(23, 59, 0);
                return true;
            }
            if (h >= 0 && h <= 23 && m >= 0 && m <= 59)
            {
                result = new TimeSpan(h, m, 0);
                return true;
            }
        }
        result = TimeSpan.Zero;
        return false;
    }

    private static object MapSchedule(Schedule s) => new
    {
        s.Id,
        s.UserId,
        s.TaskId,
        TaskTitle = s.Task?.Title,
        s.Title,
        StartTime = s.StartTime.ToString(@"hh\:mm"),
        EndTime = s.EndTime.ToString(@"hh\:mm"),
        EventDate = s.EventDate.ToString("yyyy-MM-dd"),
        s.ReminderMinutes,
        s.ColorCode
    };
}
