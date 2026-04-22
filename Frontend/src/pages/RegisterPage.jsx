import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../api/client.js";
import { Notice } from "../components/Ui.jsx";

export default function RegisterPage() {
  const navigate = useNavigate();
  const [form, setForm] = useState({
    user_name: "",
    user_email: "",
    user_phone_number: "",
    user_ic_number: "",
    user_password: ""
  });
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function submit(event) {
    event.preventDefault();
    setError("");
    setMessage("");
    try {
      await api.registerUser(form);
      setMessage("Registration completed. You can login now.");
      setTimeout(() => navigate("/login"), 900);
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <main className="auth-page">
      <section className="auth-visual">
        <img src="/logo.png" alt="" />
        <h1>Create UniPay</h1>
        <p>Start with a user wallet, then link banks and apply as a merchant from account settings.</p>
      </section>
      <form className="auth-card" onSubmit={submit}>
        <h2>Sign up</h2>
        <Notice type="success">{message}</Notice>
        <Notice type="error">{error}</Notice>
        <label>Name<input value={form.user_name} onChange={(e) => setForm({ ...form, user_name: e.target.value })} required /></label>
        <label>Email<input type="email" value={form.user_email} onChange={(e) => setForm({ ...form, user_email: e.target.value })} /></label>
        <label>Phone<input value={form.user_phone_number} onChange={(e) => setForm({ ...form, user_phone_number: e.target.value })} /></label>
        <label>IC number<input value={form.user_ic_number} onChange={(e) => setForm({ ...form, user_ic_number: e.target.value })} required /></label>
        <label>Password<input type="password" value={form.user_password} onChange={(e) => setForm({ ...form, user_password: e.target.value })} required /></label>
        <button className="primary-button">Register</button>
        <Link to="/login">Back to login</Link>
      </form>
    </main>
  );
}
