import { useEffect, useState } from "react";
import { api } from "../api/client.js";
import { Notice, StatCard } from "../components/Ui.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function ProviderPage({ tab = "dashboard" }) {
  const { user } = useAuth();
  const [providers, setProviders] = useState([]);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [secret, setSecret] = useState({ id: "", api_key: "", api_secret: "" });

  useEffect(() => {
    api.providers().then((data) => setProviders(Array.isArray(data) ? data : [])).catch((err) => setError(err.message));
  }, []);

  async function saveSecret(event) {
    event.preventDefault();
    setError("");
    try {
      await api.updateProviderSecrets(secret.id || user?.providerId || user?.provider_id, {
        api_key: secret.api_key,
        api_secret: secret.api_secret
      });
      setMessage("Provider API secrets updated.");
    } catch (err) {
      setError(err.message);
    }
  }

  if (tab === "api") {
    return (
      <section className="page-stack narrow">
        <div className="page-title"><h2>API keys</h2></div>
        <Notice type="success">{message}</Notice>
        <Notice type="error">{error}</Notice>
        <form className="panel form-panel" onSubmit={saveSecret}>
          <label>Provider ID<input value={secret.id} onChange={(e) => setSecret({ ...secret, id: e.target.value })} placeholder={user?.providerId || user?.provider_id || ""} /></label>
          <label>API key<input value={secret.api_key} onChange={(e) => setSecret({ ...secret, api_key: e.target.value })} required /></label>
          <label>API secret<input type="password" value={secret.api_secret} onChange={(e) => setSecret({ ...secret, api_secret: e.target.value })} required /></label>
          <button className="primary-button">Save</button>
        </form>
      </section>
    );
  }

  if (tab === "reports") {
    return (
      <section className="page-stack">
        <div className="page-title"><h2>Provider reports</h2></div>
        <article className="panel">
          <h3>Gateway records</h3>
          <div className="table-list">
            {providers.map((provider) => (
              <div className="table-row" key={provider.providerId || provider.provider_id}>
                <span>{provider.name || provider.provider_name || "Provider"}</span>
                <span>{provider.baseUrl || provider.provider_base_url || "-"}</span>
                <strong>{provider.enabled === false ? "Disabled" : "Enabled"}</strong>
              </div>
            ))}
          </div>
        </article>
      </section>
    );
  }

  return (
    <section className="page-stack">
      <div className="page-title"><h2>Provider dashboard</h2></div>
      <Notice type="error">{error}</Notice>
      <div className="stats-grid">
        <StatCard label="Provider" value={user?.userName || user?.user_name || "Provider"} />
        <StatCard label="Gateways" value={providers.length} tone="green" />
        <StatCard label="Status" value="Connected" tone="gold" />
      </div>
      <article className="panel">
        <h3>Recent gateway list</h3>
        <div className="table-list">
          {providers.map((provider) => (
            <div className="table-row" key={provider.providerId || provider.provider_id}>
              <span>{provider.name || provider.provider_name || "Provider"}</span>
              <span>{provider.baseUrl || provider.provider_base_url || "-"}</span>
              <strong>{provider.enabled === false ? "Disabled" : "Enabled"}</strong>
            </div>
          ))}
        </div>
      </article>
    </section>
  );
}
