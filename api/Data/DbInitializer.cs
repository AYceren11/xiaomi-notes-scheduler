using Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Api.Data;

public static class DbInitializer
{
    public static void Initialize(AppDbContext context)
    {
        context.Database.Migrate();

        if (context.Users.Any())
        {
            return;
        }

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

        // Seed Categories for standard user and admin
        var catImportant = new Category { UserId = user.Id, Name = "Önemli", ColorCode = "#FF6900", Icon = "star" };
        var catWork = new Category { UserId = user.Id, Name = "İş", ColorCode = "#2196F3", Icon = "work" };
        var catPersonal = new Category { UserId = user.Id, Name = "Kişisel", ColorCode = "#4CAF50", Icon = "person" };
        var catStudy = new Category { UserId = user.Id, Name = "Dersler", ColorCode = "#9C27B0", Icon = "book" };

        var adminCatGeneral = new Category { UserId = admin.Id, Name = "Yönetim", ColorCode = "#FF6900", Icon = "star" };
        var adminCatSystem = new Category { UserId = admin.Id, Name = "Sistem", ColorCode = "#2196F3", Icon = "work" };

        context.Categories.AddRange(catImportant, catWork, catPersonal, catStudy, adminCatGeneral, adminCatSystem);
        context.SaveChanges();

        // Seed Notes (Quill Delta JSON format for rich text editor + MindMap + Vault sample)
        var sampleMindMap = "{\"id\":\"root\",\"text\":\"BLM4587 Dönem Projesi\",\"color\":\"#FF6900\",\"children\":[{\"id\":\"n1\",\"text\":\"ASP.NET Core API\",\"color\":\"#2196F3\",\"children\":[{\"id\":\"n1a\",\"text\":\"PostgreSQL & EF Core\",\"color\":\"#4CAF50\",\"children\":[]},{\"id\":\"n1b\",\"text\":\"JWT & Roller\",\"color\":\"#9C27B0\",\"children\":[]}]},{\"id\":\"n2\",\"text\":\"Flutter Mobil\",\"color\":\"#4CAF50\",\"children\":[{\"id\":\"n2a\",\"text\":\"Zengin Metin & Çizim\",\"color\":\"#FF9800\",\"children\":[]},{\"id\":\"n2b\",\"text\":\"24s Zamanlayıcı & Kasa\",\"color\":\"#E91E63\",\"children\":[]}]}]}";

        var note1 = new Note
        {
            UserId = user.Id,
            CategoryId = catImportant.Id,
            Title = "Xiaomi Hızlı Not & Zamanlayıcı",
            ContentJson = "[{\"insert\":\"Xiaomi Notes & Scheduler Özellikleri\",\"attributes\":{\"bold\":true}},{\"insert\":\"\\nSol kenardaki turuncu çubuğu sağa kaydırarak hızlıca not ve görev ekleyebilirsiniz.\\nGörevler tamamlandığında üstü çizili kalır ve sıralanabilir.\\n24 saatlik dikey zaman matrisine görevlerinizi sürükleyip bırakabilirsiniz.\\n\"}]",
            ColorHex = "#FFF9E6",
            IsPinned = true,
            IsVault = false,
            CreatedAt = DateTime.UtcNow.AddHours(-5),
            UpdatedAt = DateTime.UtcNow.AddMinutes(-15)
        };

        var note2 = new Note
        {
            UserId = user.Id,
            CategoryId = catStudy.Id,
            Title = "BLM4587 Dönem Projesi Mimarisi",
            ContentJson = "[{\"insert\":\"Backend: \",\"attributes\":{\"bold\":true}},{\"insert\":\"ASP.NET Core Web API + PostgreSQL + EF Core Migrations\\n\"},{\"insert\":\"Frontend: \",\"attributes\":{\"bold\":true}},{\"insert\":\"Flutter (Dart) + Provider MVVM + Dio\\n\"},{\"insert\":\"Özellikler: \",\"attributes\":{\"bold\":true}},{\"insert\":\"Zengin metin, zihin haritası, sesli not, çizim, biyometrik kasa ve 24 saatlik ajanda.\\n\"}]",
            MindMapData = sampleMindMap,
            ColorHex = "#E3F2FD",
            IsPinned = true,
            IsVault = false,
            CreatedAt = DateTime.UtcNow.AddDays(-1),
            UpdatedAt = DateTime.UtcNow.AddHours(-2)
        };

        var vaultNote = new Note
        {
            UserId = user.Id,
            CategoryId = catPersonal.Id,
            Title = "Gizli Kasa - Özel Notlarım",
            ContentJson = "[{\"insert\":\"Bu not biyometrik doğrulama (Parmak İzi / Yüz Tanıma / PIN) ile korunan Gizli Kasa içinde saklanır.\\n\"}]",
            ColorHex = "#EDE7F6",
            IsPinned = false,
            IsVault = true,
            CreatedAt = DateTime.UtcNow.AddHours(-10),
            UpdatedAt = DateTime.UtcNow.AddHours(-3)
        };

        var adminNote = new Note
        {
            UserId = admin.Id,
            CategoryId = adminCatGeneral.Id,
            Title = "Yönetici Kontrol Listesi",
            ContentJson = "[{\"insert\":\"Sistem durumu, kullanıcı rolleri ve denetim günlükleri Yönetici Paneli üzerinden takip edilir.\\n\"}]",
            ColorHex = "#FFF3E0",
            IsPinned = true,
            IsVault = false,
            CreatedAt = DateTime.UtcNow.AddHours(-2),
            UpdatedAt = DateTime.UtcNow.AddMinutes(-30)
        };

        context.Notes.AddRange(note1, note2, vaultNote, adminNote);
        context.SaveChanges();

        // Seed Tasks + Subtasks
        var task1 = new TaskItem
        {
            UserId = user.Id,
            NoteId = note2.Id,
            Title = "Web API uç noktaları ve Swagger testleri",
            IsCompleted = true,
            Priority = "Yüksek",
            OrderIndex = 0,
            DueDate = DateTime.UtcNow.AddDays(2),
            CreatedAt = DateTime.UtcNow.AddDays(-1),
            CompletedAt = DateTime.UtcNow
        };

        var task2 = new TaskItem
        {
            UserId = user.Id,
            NoteId = note2.Id,
            Title = "Flutter Xiaomi MIUI arayüzü ve zengin editör",
            IsCompleted = false,
            Priority = "Yüksek",
            OrderIndex = 1,
            DueDate = DateTime.UtcNow.AddDays(3),
            CreatedAt = DateTime.UtcNow
        };

        var task3 = new TaskItem
        {
            UserId = user.Id,
            Title = "Haftalık ders çalışma planını zamanlayıcıya ata",
            IsCompleted = false,
            Priority = "Orta",
            OrderIndex = 2,
            DueDate = DateTime.UtcNow.AddDays(1),
            CreatedAt = DateTime.UtcNow
        };

        var task4 = new TaskItem
        {
            UserId = user.Id,
            Title = "Proje sunum videosunu Drive'a yükle",
            IsCompleted = false,
            Priority = "Düşük",
            OrderIndex = 3,
            DueDate = DateTime.UtcNow.AddDays(5),
            CreatedAt = DateTime.UtcNow
        };

        context.Tasks.AddRange(task1, task2, task3, task4);
        context.SaveChanges();

        // Seed Subtasks for task2
        context.Tasks.AddRange(
            new TaskItem
            {
                UserId = user.Id,
                ParentId = task2.Id,
                Title = "Masonry ızgara ve klasör filtreleri",
                IsCompleted = true,
                Priority = "Orta",
                OrderIndex = 0,
                CreatedAt = DateTime.UtcNow
            },
            new TaskItem
            {
                UserId = user.Id,
                ParentId = task2.Id,
                Title = "24 saatlik zaman matrisi sürükle-bırak",
                IsCompleted = false,
                Priority = "Yüksek",
                OrderIndex = 1,
                CreatedAt = DateTime.UtcNow
            }
        );
        context.SaveChanges();

        // Seed Schedules for today
        var today = DateTime.UtcNow.Date;
        context.Schedules.AddRange(
            new Schedule
            {
                UserId = user.Id,
                TaskId = task2.Id,
                Title = "BLM4587 Mobil Uygulama Dersi",
                StartTime = new TimeSpan(9, 0, 0),
                EndTime = new TimeSpan(10, 30, 0),
                EventDate = today,
                ReminderMinutes = 15,
                ColorCode = "#2196F3"
            },
            new Schedule
            {
                UserId = user.Id,
                TaskId = task1.Id,
                Title = "Web API & PostgreSQL Migration Testi",
                StartTime = new TimeSpan(11, 0, 0),
                EndTime = new TimeSpan(12, 0, 0),
                EventDate = today,
                ReminderMinutes = 10,
                ColorCode = "#FF6900"
            },
            new Schedule
            {
                UserId = user.Id,
                TaskId = task3.Id,
                Title = "Xiaomi Notes UI & Zihin Haritası Çalışması",
                StartTime = new TimeSpan(14, 0, 0),
                EndTime = new TimeSpan(15, 30, 0),
                EventDate = today,
                ReminderMinutes = 15,
                ColorCode = "#4CAF50"
            },
            new Schedule
            {
                UserId = admin.Id,
                Title = "Sistem Denetim & Yedekleme Kontrolü",
                StartTime = new TimeSpan(10, 0, 0),
                EndTime = new TimeSpan(11, 0, 0),
                EventDate = today,
                ReminderMinutes = 15,
                ColorCode = "#9C27B0"
            }
        );
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
        using var sha256 = System.Security.Cryptography.SHA256.Create();
        var bytes = System.Text.Encoding.UTF8.GetBytes(password);
        var hash = sha256.ComputeHash(bytes);
        return Convert.ToBase64String(hash);
    }
}
