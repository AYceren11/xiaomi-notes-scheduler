using Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Api.Data;

public static class DbInitializer
{
    public static void Initialize(AppDbContext context)
    {
        // Ensure database exists or tables are created
        context.Database.EnsureCreated();

        if (context.Users.Any())
        {
            return; // DB already seeded
        }

        // Seed Users
        var admin = new User
        {
            FullName = "Sistem Yöneticisi",
            Email = "admin@xiaomi.com",
            PasswordHash = BCryptOrSimpleHash("Admin123!"),
            Role = "Admin",
            CreatedAt = DateTime.UtcNow,
            IsActive = true
        };

        var user = new User
        {
            FullName = "Ayşe Ceren Şenel",
            Email = "user@xiaomi.com",
            PasswordHash = BCryptOrSimpleHash("User123!"),
            Role = "User",
            CreatedAt = DateTime.UtcNow,
            IsActive = true
        };

        context.Users.AddRange(admin, user);
        context.SaveChanges();

        // Seed Categories
        var catImportant = new Category { UserId = user.Id, Name = "Önemli", ColorCode = "#FF6900", Icon = "star" };
        var catWork = new Category { UserId = user.Id, Name = "İş", ColorCode = "#2196F3", Icon = "work" };
        var catPersonal = new Category { UserId = user.Id, Name = "Kişisel", ColorCode = "#4CAF50", Icon = "person" };
        var catStudy = new Category { UserId = user.Id, Name = "Dersler", ColorCode = "#9C27B0", Icon = "book" };

        context.Categories.AddRange(catImportant, catWork, catPersonal, catStudy);
        context.SaveChanges();

        // Seed Notes
        var note1 = new Note
        {
            UserId = user.Id,
            CategoryId = catImportant.Id,
            Title = "⚡ Xiaomi Hızlı Not & Zamanlayıcı",
            ContentJson = "• Sol kenardaki turuncu çubuktan diğer uygulamaların üzerinde hızlıca not ve görev ekleyebilirsiniz.\n• Görevler tamamlandığında silinmez, üstü çizili kalır.\n• Görevlerin sırasını değiştirebilir ve bir görevi başka bir görevin altına alt görev olarak taşıyabilirsiniz.\n• 24 saatlik dikey zaman matrisinde görevlerinizi saatlere sürükleyebilirsiniz.",
            ColorHex = "#FFF9E6",
            IsPinned = true,
            IsVault = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        var note2 = new Note
        {
            UserId = user.Id,
            CategoryId = catStudy.Id,
            Title = "BLM4587 Dönem Projesi Mimarisi",
            ContentJson = "Backend: ASP.NET Core 8 Web API + PostgreSQL + EF Core Code-First.\nFrontend: Flutter (Dart) + Dio + Provider/Riverpod.\nKimlik Doğrulama: JWT Token tabanlı (Admin ve User rolleri).\nÖzellikler: Zengin metin düzenleyici, 24 saatlik ajanda, şifreli kasa.",
            ColorHex = "#E3F2FD",
            IsPinned = true,
            IsVault = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        context.Notes.AddRange(note1, note2);
        context.SaveChanges();

        // Seed Tasks
        var task1 = new TaskItem
        {
            UserId = user.Id,
            NoteId = note2.Id,
            Title = "Proje mimarisinin kurulması ve API uç noktaları",
            IsCompleted = true,
            Priority = "Yüksek",
            DueDate = DateTime.UtcNow.AddDays(2),
            CreatedAt = DateTime.UtcNow,
            CompletedAt = DateTime.UtcNow
        };

        var task2 = new TaskItem
        {
            UserId = user.Id,
            Title = "Flutter arayüz tasarımı ve Xiaomi MIUI teması",
            IsCompleted = false,
            Priority = "Yüksek",
            DueDate = DateTime.UtcNow.AddDays(4),
            CreatedAt = DateTime.UtcNow
        };

        var task3 = new TaskItem
        {
            UserId = user.Id,
            Title = "Haftalık Alışveriş Listesi",
            IsCompleted = false,
            Priority = "Orta",
            DueDate = DateTime.UtcNow.AddDays(1),
            CreatedAt = DateTime.UtcNow
        };

        context.Tasks.AddRange(task1, task2, task3);
        context.SaveChanges();

        // Seed AuditLog
        context.AuditLogs.Add(new AuditLog
        {
            UserId = admin.Id,
            Action = "SYSTEM_INITIALIZED",
            EntityName = "Database",
            RecordId = 1,
            Timestamp = DateTime.UtcNow,
            IpAddress = "127.0.0.1"
        });
        context.SaveChanges();
    }

    public static string BCryptOrSimpleHash(string password)
    {
        // Simple secure hash for demo seeding
        using var sha256 = System.Security.Cryptography.SHA256.Create();
        var bytes = System.Text.Encoding.UTF8.GetBytes(password);
        var hash = sha256.ComputeHash(bytes);
        return Convert.ToBase64String(hash);
    }
}
