export type ApiSuccess<T> = { success: true; data: T };
export type ApiError = { success: false; error: string };

const ok = <T>(data: T): ApiSuccess<T> => ({ success: true, data });
const fail = (message: string, code?: number) => ({
  success: false,
  error: message,
  code
});

export { ok, fail };
