import { useState } from "react";
import { api } from "../api/client.js";
import { Notice, userIdOf } from "../components/Ui.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function MerchantApplyPage() {
  const auth = useAuth();
  const [form, setForm] = useState({ merchant_name: "", merchant_phone_number: "", merchant_doc: null });
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function submit(event) {
    event.preventDefault();
    const data = new FormData();
    data.append("owner_user_id", userIdOf(auth.user));
    data.append("merchant_name", form.merchant_name);
    if (form.merchant_phone_number) data.append("merchant_phone_number", form.merchant_phone_number);
    if (form.merchant_doc) data.append("merchant_doc", form.merchant_doc);
    try {
      await api.merchantApply(data);
      setMessage("Merchant application submitted.");
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <section className="page-stack narrow">
      <div className="page-title"><h2>Merchant application</h2></div>
      <Notice type="success">{message}</Notice>
      <Notice type="error">{error}</Notice>
      <form className="panel form-panel" onSubmit={submit}>
        <label>Merchant name<input value={form.merchant_name} onChange={(e) => setForm({ ...form, merchant_name: e.target.value })} required /></label>
        <label>Merchant phone<input value={form.merchant_phone_number} onChange={(e) => setForm({ ...form, merchant_phone_number: e.target.value })} /></label>
        <label>Document<input type="file" onChange={(e) => setForm({ ...form, merchant_doc: e.target.files?.[0] || null })} /></label>
        <button className="primary-button">Submit</button>
      </form>
    </section>
  );
}
