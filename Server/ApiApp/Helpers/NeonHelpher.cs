using Microsoft.EntityFrameworkCore;
using ApiApp.Data;
using ApiApp.Models;

namespace ApiApp.Services;

public interface INoteHelper
{
    Task<List<Note>> GetAllAsync();
    Task<Note?> GetByIdAsync(int id);
    Task<Note> CreateAsync(string text);
    Task<bool> UpdateAsync(int id, string text);
    Task<bool> DeleteAsync(int id);
}

public class NoteHelper : INoteHelper
{
    private readonly AppDbContext _db;
    public NoteHelper(AppDbContext db) => _db = db;

    public async Task<List<Note>> GetAllAsync() =>
        await _db.Notes.OrderByDescending(n => n.Id).ToListAsync();

    public async Task<Note?> GetByIdAsync(int id) =>
        await _db.Notes.FindAsync(id);

    public async Task<Note> CreateAsync(string text)
    {
        var note = new Note { Text = text };
        _db.Notes.Add(note);
        await _db.SaveChangesAsync();
        return note;
    }

    public async Task<bool> UpdateAsync(int id, string text)
    {
        var note = await _db.Notes.FindAsync(id);
        if (note is null) return false;
        note.Text = text;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var note = await _db.Notes.FindAsync(id);
        if (note is null) return false;
        _db.Remove(note);
        await _db.SaveChangesAsync();
        return true;
    }
}
