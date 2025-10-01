import jwt from "jsonwebtoken";
import { fail } from "../utils/response";

const JWT_SECRET_MIDDLEWARE = process.env.JWT_SECRET!;

interface AuthedRequest extends Request {
  userId?: string;
}

export function auth(req: any, res: any, next: any) {
  const h = req.headers.authorization || "";
  const token = h.startsWith("Bearer ") ? h.slice(7) : null;
  if (!token) return res.status(401).json(fail("No token"));
  try {
    const payload = jwt.verify(token, JWT_SECRET_MIDDLEWARE) as any;
    req.userId = payload.sub;
    next();
  } catch {
    res.status(401).json(fail("Invalid token"));
  }
}
