namespace Api.DTOs;

public record RegisterDto(string FullName, string Email, string Password, string Role = "User");
public record LoginDto(string Email, string Password);
public record AuthResponseDto(int Id, string FullName, string Email, string Role, string Token);
