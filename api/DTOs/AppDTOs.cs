using System.ComponentModel.DataAnnotations;

namespace Api.DTOs;

public record CreateNoteDto(
    [Required(ErrorMessage = "Not başlığı zorunludur.")]
    [MaxLength(200, ErrorMessage = "Başlık en fazla 200 karakter olabilir.")]
    string Title,

    string ContentJson = "",
    int? CategoryId = null,

    [RegularExpression("^#[0-9A-Fa-f]{6}$", ErrorMessage = "Geçerli bir HEX renk kodu giriniz (örn. #FFF9E6).")]
    string ColorHex = "#FFF9E6",

    bool IsPinned = false,
    bool IsVault = false,
    string? MindMapData = null,
    string? AudioUrl = null,
    string? DrawingData = null
);

public record UpdateNoteDto(
    [Required(ErrorMessage = "Not başlığı zorunludur.")]
    [MaxLength(200, ErrorMessage = "Başlık en fazla 200 karakter olabilir.")]
    string Title,

    string ContentJson = "",
    int? CategoryId = null,

    [RegularExpression("^#[0-9A-Fa-f]{6}$", ErrorMessage = "Geçerli bir HEX renk kodu giriniz (örn. #FFF9E6).")]
    string ColorHex = "#FFF9E6",

    bool IsPinned = false,
    bool IsVault = false,
    string? MindMapData = null,
    string? AudioUrl = null,
    string? DrawingData = null
);

public record CreateTaskDto(
    [Required(ErrorMessage = "Görev başlığı zorunludur.")]
    [MinLength(1, ErrorMessage = "Görev başlığı boş olamaz.")]
    [MaxLength(250, ErrorMessage = "Görev başlığı en fazla 250 karakter olabilir.")]
    string Title,

    int? NoteId = null,
    int? ParentId = null,

    [RegularExpression("^(Düşük|Orta|Yüksek)$", ErrorMessage = "Öncelik 'Düşük', 'Orta' veya 'Yüksek' olmalıdır.")]
    string Priority = "Orta",

    DateTime? DueDate = null
);

public record UpdateTaskDto(
    [Required(ErrorMessage = "Görev başlığı zorunludur.")]
    [MaxLength(250)]
    string Title,

    bool IsCompleted,

    [RegularExpression("^(Düşük|Orta|Yüksek)$", ErrorMessage = "Öncelik 'Düşük', 'Orta' veya 'Yüksek' olmalıdır.")]
    string Priority = "Orta",

    DateTime? DueDate = null,
    int? NoteId = null,
    int? ParentId = null,
    int OrderIndex = 0
);

public record TaskOrderItemDto(int Id, int OrderIndex, int? ParentId = null);

public record ReorderTasksDto(
    [Required]
    List<TaskOrderItemDto> Items
);

public record CategoryDto(
    [Required(ErrorMessage = "Kategori adı zorunludur.")]
    [MinLength(1)]
    [MaxLength(60, ErrorMessage = "Kategori adı en fazla 60 karakter olabilir.")]
    string Name,

    [RegularExpression("^#[0-9A-Fa-f]{6}$", ErrorMessage = "Geçerli bir HEX renk kodu giriniz.")]
    string ColorCode = "#FF6900",

    [MaxLength(40)]
    string Icon = "folder"
);

public record CreateScheduleDto(
    [Required(ErrorMessage = "Etkinlik başlığı zorunludur.")]
    [MaxLength(200)]
    string Title,

    [Required(ErrorMessage = "Başlangıç saati zorunludur (HH:mm veya HH:mm:ss).")]
    string StartTime,

    [Required(ErrorMessage = "Bitiş saati zorunludur (HH:mm veya HH:mm:ss).")]
    string EndTime,

    [Required(ErrorMessage = "Etkinlik tarihi zorunludur.")]
    DateTime EventDate,

    int? TaskId = null,

    [Range(0, 1440, ErrorMessage = "Hatırlatıcı 0 ile 1440 dakika arasında olmalıdır.")]
    int ReminderMinutes = 15,

    [RegularExpression("^#[0-9A-Fa-f]{6}$", ErrorMessage = "Geçerli bir HEX renk kodu giriniz.")]
    string ColorCode = "#FF6900"
);

public record UpdateScheduleDto(
    [Required(ErrorMessage = "Etkinlik başlığı zorunludur.")]
    [MaxLength(200)]
    string Title,

    [Required]
    string StartTime,

    [Required]
    string EndTime,

    [Required]
    DateTime EventDate,

    int? TaskId = null,

    [Range(0, 1440)]
    int ReminderMinutes = 15,

    [RegularExpression("^#[0-9A-Fa-f]{6}$")]
    string ColorCode = "#FF6900"
);

public record CreateUserDto(
    [Required(ErrorMessage = "Ad Soyad zorunludur.")]
    [MinLength(2)]
    [MaxLength(100)]
    string FullName,

    [Required(ErrorMessage = "E-posta adresi zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    [MaxLength(150)]
    string Email,

    [Required(ErrorMessage = "Şifre zorunludur.")]
    [MinLength(6, ErrorMessage = "Şifre en az 6 karakter olmalıdır.")]
    string Password,

    [RegularExpression("^(User|Admin)$", ErrorMessage = "Rol 'User' veya 'Admin' olmalıdır.")]
    string Role = "User",

    bool IsActive = true
);

public record UpdateUserDto(
    [Required(ErrorMessage = "Ad Soyad zorunludur.")]
    [MinLength(2)]
    [MaxLength(100)]
    string FullName,

    [Required(ErrorMessage = "E-posta adresi zorunludur.")]
    [EmailAddress]
    [MaxLength(150)]
    string Email,

    [RegularExpression("^(User|Admin)$")]
    string? Role = null,

    bool? IsActive = null,
    string? NewPassword = null
);

public record UpdateUserRoleDto(
    [Required]
    [RegularExpression("^(User|Admin)$", ErrorMessage = "Rol 'User' veya 'Admin' olmalıdır.")]
    string Role
);
