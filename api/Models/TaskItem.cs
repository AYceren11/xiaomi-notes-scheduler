namespace Api.Models;

public class TaskItem
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public int? NoteId { get; set; }
    public Note? Note { get; set; }
    public int? ParentId { get; set; }
    public string Title { get; set; } = string.Empty;
    public bool IsCompleted { get; set; } = false;
    public string Priority { get; set; } = "Orta"; // "Düşük", "Orta", "Yüksek"
    public int OrderIndex { get; set; } = 0;
    public DateTime? DueDate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }

    public ICollection<Schedule> Schedules { get; set; } = new List<Schedule>();
}
