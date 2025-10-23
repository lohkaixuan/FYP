// Server/ApiApp/Controllers/CategoryController.cs
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using ApiApp.AI;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/tx")]
public sealed class CategoryController : ControllerBase
{
    private readonly ICategorizer _cat;
    public CategoryController(ICategorizer cat) => _cat = cat;

    [HttpPost("categorize")]
    public async Task<ActionResult<TxOutput>> Categorize([FromBody] TxInput tx, CancellationToken ct)
        => Ok(await _cat.CategorizeAsync(tx, ct));
}
