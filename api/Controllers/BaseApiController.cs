using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

public abstract class BaseApiController : ControllerBase
{
    protected int CurrentUserId
    {
        get
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return int.TryParse(claim, out var id) ? id : 0;
        }
    }

    protected string CurrentUserRole => User.FindFirstValue(ClaimTypes.Role) ?? "User";

    protected bool IsAdmin => string.Equals(CurrentUserRole, "Admin", StringComparison.OrdinalIgnoreCase);

    protected string ClientIp => HttpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1";
}
