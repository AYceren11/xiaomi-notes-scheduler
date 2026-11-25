using Api.Data;
using Api.Models;

namespace Api.Services;

public class AuditService
{
    private readonly AppDbContext _context;

    public AuditService(AppDbContext context)
    {
        _context = context;
    }

    public async Task LogAsync(int userId, string action, string entityName, int recordId, string? ipAddress = null)
    {
        try
        {
            _context.AuditLogs.Add(new AuditLog
            {
                UserId = userId,
                Action = action,
                EntityName = entityName,
                RecordId = recordId,
                Timestamp = DateTime.UtcNow,
                IpAddress = string.IsNullOrWhiteSpace(ipAddress) ? "127.0.0.1" : ipAddress
            });
            await _context.SaveChangesAsync();
        }
        catch
        {
            // Audit failure must never break core request flow
        }
    }
}
