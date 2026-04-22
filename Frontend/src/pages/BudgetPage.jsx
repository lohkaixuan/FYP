import { useEffect, useState } from "react";
import { api } from "../api/client.js";
import { Notice, formatCurrency, walletIdOf } from "../components/Ui.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function BudgetPage() {
  const auth = useAuth();
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ category: "", amount: "" });
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function load() {
    const data = await api.budgets();
    setItems(Array.isArray(data) ? data : []);
  }

  useEffect(() => { load().catch((err) => setError(err.message)); }, []);

  async function submit(event) {
    event.preventDefault();
    setError("");
    try {
      await api.upsertBudget({
        wallet_id: walletIdOf(auth.user),
        category: form.category,
        amount: Number(form.amount)
      });
      setMessage("Budget saved.");
      setForm({ category: "", amount: "" });
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <section className="page-stack">
      <div className="page-title"><h2>Budget</h2></div>
      <Notice type="success">{message}</Notice>
      <Notice type="error">{error}</Notice>
      <section className="content-grid two">
        <form className="panel form-panel" onSubmit={submit}>
          <h3>Create budget</h3>
          <label>Category<input value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} required /></label>
          <label>Amount<input type="number" min="1" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} required /></label>
          <button className="primary-button">Save</button>
        </form>
        <article className="panel">
          <h3>Current budgets</h3>
          <div className="list">
            {items.map((item, index) => (
              <div className="list-row" key={item.budget_id || index}>
                <span>{item.category || item.budget_category || "Budget"}</span>
                <strong>{formatCurrency(item.amount || item.budget_amount || item.limit)}</strong>
              </div>
            ))}
          </div>
        </article>
      </section>
    </section>
  );
}
