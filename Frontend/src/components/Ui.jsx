export function StatCard({ label, value, tone = "blue" }) {
  return (
    <article className={`stat-card ${tone}`}>
      <span>{label}</span>
      <strong>{value}</strong>
    </article>
  );
}

export function EmptyState({ title, text }) {
  return (
    <div className="empty-state">
      <h3>{title}</h3>
      <p>{text}</p>
    </div>
  );
}

export function Notice({ type = "info", children }) {
  if (!children) return null;
  return <div className={`notice ${type}`}>{children}</div>;
}

export function formatCurrency(value) {
  const amount = Number(value || 0);
  return new Intl.NumberFormat("en-MY", {
    style: "currency",
    currency: "MYR"
  }).format(amount);
}

export function userIdOf(user) {
  return user?.userId || user?.user_id || "";
}

export function walletIdOf(user) {
  return (
    user?.walletId ||
    user?.wallet_id ||
    user?.userWalletId ||
    user?.user_wallet_id ||
    user?.merchantWalletId ||
    user?.merchant_wallet_id ||
    ""
  );
}

export function balanceOf(user) {
  return (
    user?.userWalletBalance ??
    user?.user_wallet_balance ??
    user?.walletBalance ??
    user?.wallet_balance ??
    user?.balance ??
    user?.user_balance ??
    0
  );
}
