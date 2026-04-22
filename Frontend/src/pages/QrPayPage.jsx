import { useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client.js";
import { Notice, walletIdOf } from "../components/Ui.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function QrPayPage() {
  const auth = useAuth();
  const [form, setForm] = useState({ to_wallet_id: "", amount: "" });
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function submit(event) {
    event.preventDefault();
    setError("");
    try {
      await api.pay({
        from_wallet_id: walletIdOf(auth.user),
        to_wallet_id: form.to_wallet_id,
        amount: Number(form.amount),
        method: "qr"
      });
      setMessage("QR payment submitted.");
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <section className="page-stack">
      <div className="page-title"><h2>QR payment</h2><Link className="secondary-button" to="/pay/nfc">NFC</Link></div>
      <Notice type="success">{message}</Notice>
      <Notice type="error">{error}</Notice>
      <section className="content-grid two">
        <article className="panel qr-card">
          <div className="fake-qr" aria-hidden="true" />
          <p>{walletIdOf(auth.user) || "Wallet QR"}</p>
        </article>
        <form className="panel form-panel" onSubmit={submit}>
          <h3>Pay by wallet ID</h3>
          <label>Merchant wallet ID<input value={form.to_wallet_id} onChange={(e) => setForm({ ...form, to_wallet_id: e.target.value })} required /></label>
          <label>Amount<input type="number" min="1" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} required /></label>
          <button className="primary-button">Pay</button>
        </form>
      </section>
    </section>
  );
}
