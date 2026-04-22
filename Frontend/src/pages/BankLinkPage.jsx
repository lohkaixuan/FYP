import { useEffect, useState } from "react";
import { api } from "../api/client.js";
import { Notice, userIdOf } from "../components/Ui.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function BankLinkPage() {
  const auth = useAuth();
  const [accounts, setAccounts] = useState([]);
  const [form, setForm] = useState({ provider_id: "", external_account_ref: "" });
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function load() {
    const id = userIdOf(auth.user);
    if (!id) return;
    const data = await api.bankAccounts(id);
    setAccounts(Array.isArray(data) ? data : []);
  }

  useEffect(() => { load().catch((err) => setError(err.message)); }, [auth.user]);

  async function submit(event) {
    event.preventDefault();
    try {
      await api.linkProvider({ user_id: userIdOf(auth.user), ...form });
      setMessage("Bank provider linked.");
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <section className="page-stack">
      <div className="page-title"><h2>Linked banks</h2></div>
      <Notice type="success">{message}</Notice>
      <Notice type="error">{error}</Notice>
      <section className="content-grid two">
        <form className="panel form-panel" onSubmit={submit}>
          <h3>Link provider</h3>
          <label>Provider ID<input value={form.provider_id} onChange={(e) => setForm({ ...form, provider_id: e.target.value })} required /></label>
          <label>External account ref<input value={form.external_account_ref} onChange={(e) => setForm({ ...form, external_account_ref: e.target.value })} required /></label>
          <button className="primary-button">Link</button>
        </form>
        <article className="panel">
          <h3>Accounts</h3>
          <div className="list">
            {accounts.map((account, index) => (
              <div className="list-row" key={account.bankAccountId || account.bank_account_id || index}>
                <span>{account.bankName || account.bank_name || "Bank account"}</span>
                <strong>{account.bankAccountNumber || account.bank_account_number || "-"}</strong>
              </div>
            ))}
          </div>
        </article>
      </section>
    </section>
  );
}
