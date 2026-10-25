namespace Api.Models;

public class Category
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ColorCode { get; set; } = "#FF6900";
    public string Icon { get; set; } = "folder";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Note> Notes { get; set; } = new List<Note>();
}
