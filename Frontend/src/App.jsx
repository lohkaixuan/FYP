import { Navigate, Route, Routes } from "react-router-dom";
import AppShell from "./components/AppShell.jsx";
import ProtectedRoute from "./components/ProtectedRoute.jsx";
import AccountPage from "./pages/AccountPage.jsx";
import AdminPage from "./pages/AdminPage.jsx";
import BankLinkPage from "./pages/BankLinkPage.jsx";
import BudgetPage from "./pages/BudgetPage.jsx";
import ChartDetailsPage from "./pages/ChartDetailsPage.jsx";
import LoginPage from "./pages/LoginPage.jsx";
import MerchantApplyPage from "./pages/MerchantApplyPage.jsx";
import ProviderPage from "./pages/ProviderPage.jsx";
import QrPayPage from "./pages/QrPayPage.jsx";
import RegisterPage from "./pages/RegisterPage.jsx";
import ReloadPage from "./pages/ReloadPage.jsx";
import ReportsPage from "./pages/ReportsPage.jsx";
import SplashPage from "./pages/SplashPage.jsx";
import TransactionDetailsPage from "./pages/TransactionDetailsPage.jsx";
import TransactionsPage from "./pages/TransactionsPage.jsx";
import TransferPage from "./pages/TransferPage.jsx";

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/splash" replace />} />
      <Route path="/splash" element={<SplashPage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<RegisterPage />} />

      <Route element={<ProtectedRoute />}>
        <Route element={<AppShell />}>
          <Route path="/home" element={<ChartDetailsPage home />} />
          <Route path="/home/debit-credit-details" element={<ChartDetailsPage title="Debit and Credit Details" />} />
          <Route path="/home/spendingDetails" element={<ChartDetailsPage title="Spending Details" />} />
          <Route path="/home/budget-details" element={<BudgetPage />} />
          <Route path="/transactions" element={<TransactionsPage />} />
          <Route path="/transactionDetails/:id" element={<TransactionDetailsPage />} />
          <Route path="/pay" element={<QrPayPage />} />
          <Route path="/pay/nfc" element={<TransferPage mode="nfc" />} />
          <Route path="/reports" element={<ReportsPage />} />
          <Route path="/account" element={<AccountPage />} />
          <Route path="/account/profile" element={<AccountPage profile />} />
          <Route path="/account/update" element={<AccountPage edit />} />
          <Route path="/account/merchant-profile" element={<AccountPage merchant />} />
          <Route path="/account/change-pin" element={<AccountPage pin />} />
          <Route path="/reload" element={<ReloadPage />} />
          <Route path="/transfer" element={<TransferPage mode="transfer" />} />
          <Route path="/security-code" element={<TransferPage confirm />} />
          <Route path="/merchant-apply" element={<MerchantApplyPage />} />
          <Route path="/bank/link" element={<BankLinkPage />} />
          <Route path="/admin" element={<AdminPage />} />
          <Route path="/provider" element={<ProviderPage />} />
          <Route path="/provider/dashboard" element={<ProviderPage />} />
          <Route path="/provider/reports" element={<ProviderPage tab="reports" />} />
          <Route path="/provider/api-key" element={<ProviderPage tab="api" />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/splash" replace />} />
    </Routes>
  );
}
