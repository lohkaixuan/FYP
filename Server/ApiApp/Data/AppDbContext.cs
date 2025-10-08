using Microsoft.EntityFrameworkCore;
using ApiApp.Models;

namespace ApiApp.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Note> Notes => Set<Note>();
}
