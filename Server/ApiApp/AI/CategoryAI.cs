// Server/ApiApp/Helpers/CategoryAI.cs
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace ApiApp.AI
{
    // 1) Domain ---------------------------------------------------------------
    public enum Category { FB, Transport, Shopping, Bills, Entertainment, Health, Groceries, Other }

    public record TxInput(
        string? merchant,
        string? description,
        string? mcc,
        decimal amount,
        string currency = "MYR",
        string? country = "MY"
    );

    public record TxOutput(Category category, double confidence, string? rationale = null);

    public interface ICategorizer
    {
        Task<TxOutput> CategorizeAsync(TxInput tx, CancellationToken ct = default);
    }

    // 2) CSV / label normalizer ----------------------------------------------
    public static class CategoryParser
    {
        private static readonly Dictionary<string, Category> Map = new(StringComparer.OrdinalIgnoreCase)
        {
            ["fb"] = Category.FB, ["f&b"] = Category.FB, ["food & beverage"] = Category.FB,
            ["food and beverage"] = Category.FB, ["food"] = Category.FB,

            ["transport"] = Category.Transport,
            ["shopping"] = Category.Shopping,

            ["bills"] = Category.Bills, ["utilities"] = Category.Bills,

            ["entertainment"] = Category.Entertainment,

            ["health"] = Category.Health, ["healthcare"] = Category.Health,

            ["groceries"] = Category.Groceries, ["grocery"] = Category.Groceries,

            ["other"] = Category.Other
        };

        public static bool TryParse(string? csvValue, out Category cat)
        {
            cat = Category.Other;
            if (string.IsNullOrWhiteSpace(csvValue)) return false;

            var key = csvValue.Trim().ToLowerInvariant()
                              .Replace("_", " ").Replace("-", " ")
                              .Replace("  ", " ");
            key = key.Replace(" and ", " & ");
            return Map.TryGetValue(key, out cat);
        }

        public static Category FromCsv(string? csvValue, Category fallback = Category.Other)
            => TryParse(csvValue, out var cat) ? cat : fallback;
    }

    // 3) Rules-based placeholder (fast, offline) -----------------------------
    public sealed class RulesCategorizer : ICategorizer
    {
        private static readonly (Regex re, Category cat)[] Map = new[]
        {
            (new Regex("mcd|kfc|starbucks|tealive|kopitiam|mamak|foodpanda|grab ?food", RegexOptions.IgnoreCase), Category.FB),
            (new Regex("petronas|shell|bhp|grab(?!.*food)", RegexOptions.IgnoreCase), Category.Transport),
            (new Regex("lazada|shopee|uniqlo|mr ?diy", RegexOptions.IgnoreCase), Category.Shopping),
            (new Regex("tng|touch ?n ?go|maxis|celcom|digi|tm|tenaga|tnb", RegexOptions.IgnoreCase), Category.Bills),
            (new Regex("watsons|guardian|clinic|hospital|pharmacy", RegexOptions.IgnoreCase), Category.Health),
            (new Regex("jaya|aeon|tesco|lotus|mydin|giant", RegexOptions.IgnoreCase), Category.Groceries),
        };

        public Task<TxOutput> CategorizeAsync(TxInput tx, CancellationToken ct = default)
        {
            var hay = $"{tx.merchant} {tx.description}".ToLowerInvariant();
            foreach (var (re, cat) in Map)
                if (re.IsMatch(hay)) return Task.FromResult(new TxOutput(cat, 0.85));

            if (!string.IsNullOrWhiteSpace(tx.mcc) && tx.mcc.StartsWith("58")) // restaurant MCC
                return Task.FromResult(new TxOutput(Category.FB, 0.7));

            return Task.FromResult(new TxOutput(Category.Other, 0.3));
        }
    }

    // 4) Zero-shot (hosted; safe fallback to Rules on error) -----------------
    public sealed class ZeroShotCategorizer : ICategorizer
    {
        private readonly HttpClient _http;
        private readonly RulesCategorizer _fallback;
        private static readonly string[] Labels = Enum.GetNames(typeof(Category));

        public ZeroShotCategorizer(HttpClient http, RulesCategorizer fallback)
        {
            _http = http ?? throw new ArgumentNullException(nameof(http));
            _fallback = fallback ?? throw new ArgumentNullException(nameof(fallback));
        }

        public async Task<TxOutput> CategorizeAsync(TxInput tx, CancellationToken ct = default)
        {
            var text = $"{tx.merchant} {tx.description}".Trim();
            if (string.IsNullOrWhiteSpace(text))
                return await _fallback.CategorizeAsync(tx, ct);

            try
            {
                var req = new { inputs = text, parameters = new { candidate_labels = Labels } };

                using var r = await _http.PostAsJsonAsync(
                    "https://api-inference.huggingface.co/models/facebook/bart-large-mnli", req, ct);
                r.EnsureSuccessStatusCode();

                using var doc  = await JsonDocument.ParseAsync(await r.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
                var labels     = doc.RootElement.GetProperty("labels").EnumerateArray().Select(e => e.GetString()!).ToArray();
                var scores     = doc.RootElement.GetProperty("scores").EnumerateArray().Select(e => e.GetDouble()).ToArray();
                if (labels.Length == 0 || scores.Length == 0)
                    return await _fallback.CategorizeAsync(tx, ct);

                var idx        = Array.IndexOf(scores, scores.Max());
                var normalized = labels[idx].Replace("&", "").Replace(" ", "");
                var ok         = Enum.TryParse<Category>(normalized, true, out var parsed);
                var cat        = ok ? parsed : Category.Other;

                return new TxOutput(cat, scores[idx], $"ZSC: {text}");
            }
            catch
            {
                // 429/network/error → fall back so request still succeeds
                return await _fallback.CategorizeAsync(tx, ct);
            }
        }
    }
}
