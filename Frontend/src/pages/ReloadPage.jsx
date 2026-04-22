import { useState } from "react";
import { api } from "../api/client.js";
import { Notice, walletIdOf } from "../components/Ui.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function ReloadPage() {
  const auth = useAuth();
  const [form, setForm] = useState({ amount: "", provider_id: "", external_source_id: "" });
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function submit(event) {
    event.preventDefault();
    setError("");
    try {
      await api.reload({
        wallet_id: walletIdOf(auth.user),
        amount: Number(form.amount),
        provider_id: form.provider_id,
        external_source_id: form.external_source_id
      });
      setMessage("Reload request sent.");
      await auth.refreshMe();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <section className="page-stack narrow">
      <div className="page-title"><h2>Reload wallet</h2></div>
      <Notice type="success">{message}</Notice>
      <Notice type="error">{error}</Notice>
      <form className="panel form-panel" onSubmit={submit}>
        <label>Amount<input type="number" min="1" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} required /></label>
        <label>Provider ID<input value={form.provider_id} onChange={(e) => setForm({ ...form, provider_id: e.target.value })} required /></label>
        <label>External source ID<input value={form.external_source_id} onChange={(e) => setForm({ ...form, external_source_id: e.target.value })} required /></label>
        <button className="primary-button">Reload</button>
      </form>
    </section>
  );
}
