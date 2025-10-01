import { useEffect, useState } from "react";
import { api, setAuthToken, type ApiResult } from "./api";

type Item = { id: string; name: string; createdAt?: string };

export default function App() {
  const [email, setEmail] = useState("a@a.com");
  const [password, setPassword] = useState("secret123");
  const [token, setToken] = useState<string | null>(null);

  const [items, setItems] = useState<Item[]>([]);
  const [newItem, setNewItem] = useState("");
  const [msg, setMsg] = useState<string | null>(null);

  useEffect(() => setAuthToken(token || undefined), [token]);

  const health = async () => {
    try {
      const { data } = await api.get("/health");
      setMsg(JSON.stringify(data));
    } catch (e: any) {
      setMsg(e?.message ?? "Health failed");
    }
  };

  const register = async () => {
    const { data } = await api.post<ApiResult<{ token: string }>>("/auth/register", { email, password });
    if ("success" in data && data.success) {
      setToken(data.data.token);
      setMsg("Registered ✓");
    } else setMsg(data.error);
  };

  const login = async () => {
    const { data } = await api.post<ApiResult<{ token: string }>>("/auth/login", { email, password });
    if ("success" in data && data.success) {
      setToken(data.data.token);
      setMsg("Logged in ✓");
    } else setMsg(data.error);
  };

  const loadItems = async () => {
    const { data } = await api.get<ApiResult<Item[]>>("/items");
    if ("success" in data && data.success) setItems(data.data);
  };

  const addItem = async () => {
    if (!newItem.trim()) return;
    const { data } = await api.post<ApiResult<Item>>("/items", { name: newItem });
    if ("success" in data && data.success) {
      setNewItem("");
      loadItems();
    } else setMsg(data.error);
  };

  const logout = () => {
    setToken(null);
    setItems([]);
    setMsg("Logged out");
  };

  return (
    <div style={{ maxWidth: 640, margin: "40px auto", fontFamily: "system-ui", padding: 16 }}>
      <h1>Web ↔ API (Neon)</h1>
      <button onClick={health} style={{ marginBottom: 16 }}>Health Check</button>
      {msg && <div style={{ background: "#f2f2f2", padding: 8, marginBottom: 12 }}>{msg}</div>}

      {!token ? (
        <section style={{ border: "1px solid #ddd", padding: 16, borderRadius: 8 }}>
          <h3>Login / Register</h3>
          <div style={{ display: "grid", gap: 8 }}>
            <input placeholder="email" value={email} onChange={e => setEmail(e.target.value)} />
            <input placeholder="password" type="password" value={password} onChange={e => setPassword(e.target.value)} />
            <div style={{ display: "flex", gap: 8 }}>
              <button onClick={login}>Login</button>
              <button onClick={register}>Register</button>
            </div>
          </div>
        </section>
      ) : (
        <section style={{ border: "1px solid #ddd", padding: 16, borderRadius: 8 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <h3>Items</h3>
            <button onClick={logout}>Logout</button>
          </div>
          <div style={{ display: "flex", gap: 8, marginBottom: 12 }}>
            <input placeholder="New item..." value={newItem} onChange={e => setNewItem(e.target.value)} />
            <button onClick={addItem}>Add</button>
            <button onClick={loadItems}>Refresh</button>
          </div>
          <ul>
            {items.map(i => <li key={i.id}>{i.name}</li>)}
          </ul>
        </section>
      )}
    </div>
  );
}
