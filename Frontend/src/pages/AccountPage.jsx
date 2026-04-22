import { Link } from "react-router-dom";
import { StatCard, balanceOf, formatCurrency } from "../components/Ui.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function AccountPage({ profile, edit, merchant, pin }) {
  const { user, role } = useAuth();

  return (
    <section className="page-stack">
      <div className="page-title"><h2>{profile ? "Profile" : edit ? "Update profile" : merchant ? "Merchant profile" : pin ? "Change PIN" : "Account"}</h2></div>
      <div className="stats-grid">
        <StatCard label="Name" value={user?.userName || user?.user_name || "User"} />
        <StatCard label="Role" value={role || "user"} tone="green" />
        <StatCard label="Wallet balance" value={formatCurrency(balanceOf(user))} tone="gold" />
      </div>
      <section className="content-grid two">
        <article className="panel detail-panel">
          {Object.entries(user || {}).slice(0, 12).map(([key, value]) => <div key={key}><span>{key}</span><strong>{String(value ?? "-")}</strong></div>)}
        </article>
        <article className="panel account-actions">
          <Link className="secondary-button" to="/merchant-apply">Apply merchant</Link>
          <Link className="secondary-button" to="/account/profile">View profile</Link>
          <Link className="secondary-button" to="/account/update">Update profile</Link>
          <Link className="secondary-button" to="/account/change-pin">Change PIN</Link>
          <Link className="secondary-button" to="/bank/link">Link bank</Link>
        </article>
      </section>
    </section>
  );
}
