import { useState } from "react";
import { api } from "../api/client.js";
import { Notice, walletIdOf } from "../components/Ui.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function TransferPage({ mode = "transfer", confirm = false }) {
  const auth = useAuth();
  const [form, setForm] = useState({ to_wallet_id: "", amount: "", description: "", passcode: "" });
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function submit(event) {
    event.preventDefault();
    setError("");
    try {
      await api.transfer({
        from_wallet_id: walletIdOf(auth.user),
        to_wallet_id: form.to_wallet_id,
        amount: Number(form.amount),
        description: form.description,
        passcode: form.passcode || undefined,
        channel: mode
      });
      setMessage("Transfer submitted.");
      await auth.refreshMe();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <section className="page-stack narrow">
      <div className="page-title"><h2>{confirm ? "Security code" : mode === "nfc" ? "NFC payment" : "Transfer"}</h2></div>
      <Notice type="success">{message}</Notice>
      <Notice type="error">{error}</Notice>
      <form className="panel form-panel" onSubmit={submit}>
        <label>Recipient wallet ID<input value={form.to_wallet_id} onChange={(e) => setForm({ ...form, to_wallet_id: e.target.value })} required /></label>
        <label>Amount<input type="number" min="1" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} required /></label>
        <label>Description<input value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></label>
        <label>Passcode<input type="password" inputMode="numeric" value={form.passcode} onChange={(e) => setForm({ ...form, passcode: e.target.value })} /></label>
        <button className="primary-button">Send</button>
      </form>
    </section>
  );
}
