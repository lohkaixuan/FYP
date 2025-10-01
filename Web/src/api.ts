import axios from "axios";

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
});

export const setAuthToken = (token?: string) => {
  if (token) api.defaults.headers.common.Authorization = `Bearer ${token}`;
  else delete api.defaults.headers.common.Authorization;
};

export type ApiSuccess<T> = { success: true; data: T };
export type ApiError = { success: false; error: string; code?: number };
export type ApiResult<T> = ApiSuccess<T> | ApiError;
