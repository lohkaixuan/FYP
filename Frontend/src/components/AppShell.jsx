import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { Icon } from "./Icons.jsx";
import { useAuth } from "../state/AuthContext.jsx";

function navForRole(auth) {
  if (auth.isAdmin) {
    return [
      ["Dashboard", "/admin", "home"],
      ["API", "/admin?tab=api", "key"],
      ["Users", "/admin?tab=users", "user"],
      ["Providers", "/admin?tab=providers", "bank"]
    ];
  }

  if (auth.isProvider) {
    return [
      ["Dashboard", "/provider", "home"],
      ["Reports", "/provider/reports", "chart"],
      ["API Keys", "/provider/api-key", "key"],
      ["Account", "/account", "user"]
    ];
  }

  return [
    ["Home", "/home", "home"],
    ["Transactions", "/transactions", "receipt"],
    ["QR", "/pay", "qr"],
    ["Reports", "/reports", "chart"],
    ["Account", "/account", "user"]
  ];
}

export default function AppShell() {
  const auth = useAuth();
  const navigate = useNavigate();
  const items = navForRole(auth);

  async function handleLogout() {
    await auth.logout();
    navigate("/login", { replace: true });
  }

  return (
    <div className="app-shell">
      <aside className="side-nav">
        <button className="brand-button" onClick={() => navigate("/home")}>
          <img src="/logo.png" alt="" />
          <span>UniPay</span>
        </button>
        <nav>
          {items.map(([label, to, icon]) => (
            <NavLink key={label} to={to} className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}>
              <Icon name={icon} />
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>
        <button className="nav-item logout" onClick={handleLogout}>
          <Icon name="logout" />
          <span>Logout</span>
        </button>
      </aside>

      <main className="app-main">
        <header className="top-bar">
          <div>
            <p>{auth.role || "user"}</p>
            <h1>UniPay</h1>
          </div>
          <button className="icon-button" onClick={() => navigate("/bank/link")} title="Link bank">
            <Icon name="bank" />
          </button>
        </header>
        <Outlet />
      </main>

      <nav className="bottom-nav">
        {items.map(([label, to, icon]) => (
          <NavLink key={label} to={to} className={({ isActive }) => `bottom-item ${isActive ? "active" : ""}`}>
            <Icon name={icon} size={21} />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
