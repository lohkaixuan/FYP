import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api } from "../api/client.js";
import { Notice, StatCard } from "../components/Ui.jsx";

export default function AdminPage() {
  const [params] = useSearchParams();
  const activeTab = params.get("tab") || "dashboard";
  const [users, setUsers] = useState([]);
  const [thirdParty, setThirdParty] = useState({ user_name: "", user_email: "", user_password: "", user_phone_number: "" });
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function load() {
    const data = await api.users();
    setUsers(Array.isArray(data) ? data : []);
  }

  useEffect(() => { load().catch((err) => setError(err.message)); }, []);

  const counts = useMemo(() => ({
    users: users.length,
    merchants: users.filter((u) => String(u.roleName || u.role_name || "").includes("merchant")).length,
    providers: users.filter((u) => String(u.roleName || u.role_name || "").includes("provider")).length
  }), [users]);

  async function registerProvider(event) {
    event.preventDefault();
    setError("");
    try {
      await api.registerThirdParty(thirdParty);
      setMessage("Third-party provider registered.");
      setThirdParty({ user_name: "", user_email: "", user_password: "", user_phone_number: "" });
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <section className="page-stack">
      <div className="page-title"><h2>Admin dashboard</h2></div>
      <Notice type="success">{message}</Notice>
      <Notice type="error">{error}</Notice>
      <div className="stats-grid">
        <StatCard label="Accounts" value={counts.users} />
        <StatCard label="Merchants" value={counts.merchants} tone="gold" />
        <StatCard label="Providers" value={counts.providers} tone="green" />
      </div>

      {activeTab === "providers" ? (
        <form className="panel form-panel" onSubmit={registerProvider}>
          <h3>Register third-party provider</h3>
          <label>Name<input value={thirdParty.user_name} onChange={(e) => setThirdParty({ ...thirdParty, user_name: e.target.value })} required /></label>
          <label>Email<input type="email" value={thirdParty.user_email} onChange={(e) => setThirdParty({ ...thirdParty, user_email: e.target.value })} /></label>
          <label>Phone<input value={thirdParty.user_phone_number} onChange={(e) => setThirdParty({ ...thirdParty, user_phone_number: e.target.value })} /></label>
          <label>Password<input type="password" value={thirdParty.user_password} onChange={(e) => setThirdParty({ ...thirdParty, user_password: e.target.value })} required /></label>
          <button className="primary-button">Register</button>
        </form>
      ) : (
        <article className="panel">
          <h3>{activeTab === "api" ? "API users" : "Users"}</h3>
          <div className="table-list">
            {users.map((user) => (
              <div className="table-row" key={user.userId || user.user_id}>
                <span>{user.userName || user.user_name || "User"}</span>
                <span>{user.email || user.user_email || user.phone || user.user_phone_number || "-"}</span>
                <strong>{user.roleName || user.role_name || "user"}</strong>
              </div>
            ))}
          </div>
        </article>
      )}
    </section>
  );
}
