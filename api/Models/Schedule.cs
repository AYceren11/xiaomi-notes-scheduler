namespace Api.Models;

public class Schedule
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public int? TaskId { get; set; }
    public TaskItem? Task { get; set; }
    public string Title { get; set; } = string.Empty;
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public DateTime EventDate { get; set; }
    public int ReminderMinutes { get; set; } = 15;
    public string ColorCode { get; set; } = "#FF6900";
}
