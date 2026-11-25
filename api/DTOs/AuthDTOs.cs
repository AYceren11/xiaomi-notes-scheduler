using System.ComponentModel.DataAnnotations;

namespace Api.DTOs;

public record RegisterDto(
    [Required(ErrorMessage = "Ad Soyad zorunludur.")]
    [MinLength(2, ErrorMessage = "Ad Soyad en az 2 karakter olmalıdır.")]
    [MaxLength(100, ErrorMessage = "Ad Soyad en fazla 100 karakter olabilir.")]
    string FullName,

    [Required(ErrorMessage = "E-posta adresi zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    [MaxLength(150)]
    string Email,

    [Required(ErrorMessage = "Şifre zorunludur.")]
    [MinLength(6, ErrorMessage = "Şifre en az 6 karakter olmalıdır.")]
    [MaxLength(100)]
    string Password,

    [RegularExpression("^(User|Admin)$", ErrorMessage = "Rol yalnızca 'User' veya 'Admin' olabilir.")]
    string Role = "User"
);

public record LoginDto(
    [Required(ErrorMessage = "E-posta adresi zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    string Email,

    [Required(ErrorMessage = "Şifre zorunludur.")]
    string Password
);

public record AuthResponseDto(
    int Id,
    string FullName,
    string Email,
    string Role,
    string Token
);
