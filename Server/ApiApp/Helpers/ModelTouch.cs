// ==================================================
// Program Name   : ModelTouch.cs
// Purpose        : Sets entity timestamps and audit fields
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
namespace ApiApp.Helpers;

public static class ModelTouch
{
    public static void Touch(object entity)
    {
        var now = DateTime.UtcNow;
        var t = entity.GetType();
        var p1 = t.GetProperty("LastUpdate");
        if (p1 is not null && p1.PropertyType == typeof(DateTime)) p1.SetValue(entity, now);
        var p2 = t.GetProperty("last_update");
        if (p2 is not null && p2.PropertyType == typeof(DateTime)) p2.SetValue(entity, now);
    }
}
