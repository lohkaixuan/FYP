import { useState } from "react";
import { api } from "../api/client.js";
import { Notice, walletIdOf } from "../components/Ui.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function ReportsPage() {
  const auth = useAuth();
  const now = new Date();
  const [form, setForm] = useState({ year: now.getFullYear(), month: now.getMonth() + 1 });
  const [report, setReport] = useState(null);
  const [error, setError] = useState("");

  async function submit(event) {
    event.preventDefault();
    setError("");
    try {
      const data = await api.generateMonthlyReport({
        wallet_id: walletIdOf(auth.user),
        year: Number(form.year),
        month: Number(form.month)
      });
      setReport(data);
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <section className="page-stack narrow">
      <div className="page-title"><h2>Financial report</h2></div>
      <Notice type="error">{error}</Notice>
      <form className="panel form-panel" onSubmit={submit}>
        <label>Year<input type="number" value={form.year} onChange={(e) => setForm({ ...form, year: e.target.value })} /></label>
        <label>Month<input type="number" min="1" max="12" value={form.month} onChange={(e) => setForm({ ...form, month: e.target.value })} /></label>
        <button className="primary-button">Generate</button>
      </form>
      {report && (
        <article className="panel detail-panel">
          {Object.entries(report).map(([key, value]) => <div key={key}><span>{key}</span><strong>{String(value ?? "-")}</strong></div>)}
        </article>
      )}
    </section>
  );
}
