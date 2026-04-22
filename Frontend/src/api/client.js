const DEFAULT_API_BASE = "https://fyp-1-izlh.onrender.com";

export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, "") || DEFAULT_API_BASE;

function authHeaders(isFormData = false) {
  const token = localStorage.getItem("unipay_token");
  const headers = {
    Accept: "application/json"
  };

  if (!isFormData) headers["Content-Type"] = "application/json";
  if (token) headers.Authorization = `Bearer ${token}`;
  return headers;
}

async function parseResponse(response) {
  const contentType = response.headers.get("content-type") || "";
  const isJson = contentType.includes("application/json");
  const payload = isJson ? await response.json() : await response.text();

  if (!response.ok) {
    const message =
      payload?.message ||
      payload?.title ||
      payload?.error ||
      response.statusText ||
      "Request failed";
    throw new Error(message);
  }

  return payload;
}

export async function apiRequest(path, options = {}) {
  const isFormData = options.body instanceof FormData;
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      ...authHeaders(isFormData),
      ...(options.headers || {})
    }
  });

  return parseResponse(response);
}

export const api = {
  login: ({ email, phone, password }) =>
    apiRequest("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({
        user_email: email || null,
        user_phone_number: phone || null,
        user_password: password
      })
    }),

  logout: () => apiRequest("/api/auth/logout", { method: "POST" }),
  me: () => apiRequest("/api/users/me"),
  users: () => apiRequest("/api/users"),
  allUsers: () => apiRequest("/api/users/all-users"),
  userDirectory: () => apiRequest("/api/users/directory"),
  updateUser: (id, data) =>
    apiRequest(`/api/users/${id}`, { method: "PUT", body: JSON.stringify(data) }),
  resetPassword: (id, data) =>
    apiRequest(`/api/users/${id}/reset-password`, {
      method: "POST",
      body: JSON.stringify(data)
    }),

  registerUser: (data) =>
    apiRequest("/api/auth/register/user", {
      method: "POST",
      body: JSON.stringify(data)
    }),
  registerThirdParty: (data) =>
    apiRequest("/api/auth/register/thirdparty", {
      method: "POST",
      body: JSON.stringify(data)
    }),
  merchantApply: (formData) =>
    apiRequest("/api/auth/register/merchant-apply", {
      method: "POST",
      body: formData
    }),
  approveMerchant: (merchantId) =>
    apiRequest(`/api/auth/admin/approve-merchant/${merchantId}`, { method: "POST" }),
  rejectMerchant: (merchantId) =>
    apiRequest(`/api/auth/admin/reject-merchant/${merchantId}`, { method: "POST" }),
  approveThirdParty: (userId) =>
    apiRequest(`/api/auth/admin/approve-thirdparty/${userId}`, { method: "POST" }),

  wallet: (id) => apiRequest(`/api/wallet/${id}`),
  walletLookup: (params) => apiRequest(`/api/wallet/lookup?${new URLSearchParams(params)}`),
  reload: (data) =>
    apiRequest("/api/wallet/reload", { method: "POST", body: JSON.stringify(data) }),
  pay: (data) =>
    apiRequest("/api/wallet/pay", { method: "POST", body: JSON.stringify(data) }),
  transfer: (data) =>
    apiRequest("/api/wallet/transfer", { method: "POST", body: JSON.stringify(data) }),

  transactions: (params = {}) => {
    const query = new URLSearchParams(params);
    return apiRequest(`/api/transactions${query.toString() ? `?${query}` : ""}`);
  },
  transaction: (id) => apiRequest(`/api/transactions/${id}`),
  createTransaction: (data) =>
    apiRequest("/api/transactions", { method: "POST", body: JSON.stringify(data) }),
  categorize: (data) =>
    apiRequest("/api/transactions/categorize", {
      method: "POST",
      body: JSON.stringify(data)
    }),

  budgets: (params = {}) => {
    const query = new URLSearchParams(params);
    return apiRequest(`/api/budget${query.toString() ? `?${query}` : ""}`);
  },
  upsertBudget: (data) =>
    apiRequest("/api/budget/upsert", { method: "POST", body: JSON.stringify(data) }),

  bankAccounts: (userId) => apiRequest(`/api/bankaccount?userId=${userId}`),
  createBankAccount: (data) =>
    apiRequest("/api/bankaccount", { method: "POST", body: JSON.stringify(data) }),
  linkProvider: (data) =>
    apiRequest("/api/bankaccount/link-provider", {
      method: "POST",
      body: JSON.stringify(data)
    }),
  providerBalance: (data) =>
    apiRequest("/api/bankaccount/provider/balance", {
      method: "POST",
      body: JSON.stringify(data)
    }),
  providerTransfer: (data) =>
    apiRequest("/api/bankaccount/provider/transfer", {
      method: "POST",
      body: JSON.stringify(data)
    }),

  providers: () => apiRequest("/api/providergateway"),
  provider: (id) => apiRequest(`/api/providergateway/${id}`),
  updateProviderSecrets: (id, data) =>
    apiRequest(`/api/providergateway/${id}/secrets`, {
      method: "PUT",
      body: JSON.stringify(data)
    }),

  generateMonthlyReport: (data) =>
    apiRequest("/api/report/monthly/generate", {
      method: "POST",
      body: JSON.stringify(data)
    }),
  downloadReportUrl: (id) => `${API_BASE_URL}/api/report/${id}/download`,
  merchantDocumentUrl: (merchantId) =>
    `${API_BASE_URL}/api/auth/merchants/${merchantId}/doc`,
  health: () => apiRequest("/healthz")
};
