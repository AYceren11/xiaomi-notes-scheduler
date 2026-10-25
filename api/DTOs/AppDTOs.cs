namespace Api.DTOs;

public record CreateNoteDto(
    string Title,
    string ContentJson,
    int? CategoryId,
    string ColorHex = "#FFF9E6",
    bool IsPinned = false,
    bool IsVault = false,
    string? MindMapData = null,
    string? AudioUrl = null
);

public record UpdateNoteDto(
    string Title,
    string ContentJson,
    int? CategoryId,
    string ColorHex,
    bool IsPinned,
    bool IsVault,
    string? MindMapData = null,
    string? AudioUrl = null
);

public record CreateTaskDto(
    string Title,
    int? NoteId = null,
    int? ParentId = null,
    string Priority = "Orta",
    DateTime? DueDate = null
);

public record UpdateTaskDto(
    string Title,
    bool IsCompleted,
    string Priority,
    DateTime? DueDate,
    int? ParentId = null,
    int OrderIndex = 0
);

public record CategoryDto(
    string Name,
    string ColorCode = "#FF6900",
    string Icon = "folder"
);
