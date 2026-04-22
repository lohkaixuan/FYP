import { useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { Notice } from "../components/Ui.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function LoginPage() {
  const auth = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [form, setForm] = useState({ account: "", password: "" });
  const [error, setError] = useState("");

  async function submit(event) {
    event.preventDefault();
    setError("");
    try {
      const isEmail = form.account.includes("@");
      const result = await auth.login({
        email: isEmail ? form.account : null,
        phone: isEmail ? null : form.account,
        password: form.password
      });
      const role = String(result.role || "").toLowerCase();
      const fallback = role.includes("admin") ? "/admin" : role.includes("provider") ? "/provider" : "/home";
      navigate(location.state?.from?.pathname || fallback, { replace: true });
    } catch (err) {
      setError(err.message || "Invalid credentials.");
    }
  }

  return (
    <main className="auth-page">
      <section className="auth-visual">
        <img src="/logo.png" alt="" />
        <h1>UniPay</h1>
        <p>QR, NFC, transfer, budgets, reports, and linked bank balances in one web app.</p>
      </section>
      <form className="auth-card" onSubmit={submit}>
        <h2>Login</h2>
        <Notice type="error">{error}</Notice>
        <label>
          Email or phone
          <input value={form.account} onChange={(e) => setForm({ ...form, account: e.target.value })} required />
        </label>
        <label>
          Password
          <input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required />
        </label>
        <button className="primary-button" disabled={auth.status === "loading"}>
          {auth.status === "loading" ? "Signing in..." : "Sign in"}
        </button>
        <Link to="/signup">Create an account</Link>
      </form>
    </main>
  );
}
