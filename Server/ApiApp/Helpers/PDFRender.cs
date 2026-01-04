// ==================================================
// Program Name   : PDFRender.cs
// Purpose        : Renders PDF documents for reports
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

public class PdfRenderer
{
    public byte[] Render(MonthlyReportChart chart, string role, DateOnly month)
    {
        QuestPDF.Settings.License = LicenseType.Community;
        return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(24);
                page.DefaultTextStyle(x => x.FontSize(11));
                page.Header().Row(r =>
                {
                    r.RelativeItem().Text($"Monthly Report â€¢ {role.ToUpper()} {month:yyyy-MM}")
                        .SemiBold().FontSize(16);
                    r.ConstantItem(80).AlignRight().Text($"{DateTimeOffset.UtcNow:yyyy-MM-dd HH:mm} UTC").FontSize(9);
                });
                page.Content().Column(col =>
                {
                    col.Spacing(6);
                    col.Item().Text($"Currency: {chart.Currency}");
                    col.Item().Text($"Total Volume: {chart.TotalVolume:N2}");
                    col.Item().Text($"Transactions: {chart.TxCount}");
                    col.Item().Text($"Average Tx: {chart.AvgTx:N2}");
                    col.Item().Text($"Active Users: {chart.ActiveUsers} | Active Merchants: {chart.ActiveMerchants}");
                    col.Item().PaddingTop(10).Text("Daily Totals").SemiBold();
                    col.Item().Table(t =>
                    {
                        t.ColumnsDefinition(c =>
                        {
                            c.ConstantColumn(90);
                            c.RelativeColumn();
                            c.ConstantColumn(80);
                        });
                        t.Header(h =>
                        {
                            h.Cell().Text("Date").SemiBold();
                            h.Cell().Text("Total Amount").SemiBold();
                            h.Cell().Text("Tx Count").SemiBold();
                        });
                        foreach (var p in chart.Daily)
                        {
                            t.Cell().Text(p.Day.ToString("yyyy-MM-dd"));
                            t.Cell().Text(p.TotalAmount.ToString("N2"));
                            t.Cell().Text(p.TxCount.ToString());
                        }
                    });
                });
                page.Footer().AlignCenter().Text("UniPay  Confidential").FontSize(9).Light();
            });
        }).GeneratePdf();
    }
}
