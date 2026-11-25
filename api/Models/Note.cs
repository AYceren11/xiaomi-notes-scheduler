namespace Api.Models;

public class Note
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public int? CategoryId { get; set; }
    public Category? Category { get; set; }
    public string Title { get; set; } = string.Empty;
    public string ContentJson { get; set; } = string.Empty;
    public string? MindMapData { get; set; }
    public string? AudioUrl { get; set; }
    public string? DrawingData { get; set; }
    public string ColorHex { get; set; } = "#FFF9E6";
    public bool IsVault { get; set; } = false;
    public bool IsPinned { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<TaskItem> Tasks { get; set; } = new List<TaskItem>();
}
