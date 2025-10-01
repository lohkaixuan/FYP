import { RegisterDTO, LoginDTO } from "./auth.dto";
import * as AuthService from "./auth.service";
import * as ResponseUtils from "../../utils/response";

async function authPostRegister(req: any, res: any) {
  const parse = RegisterDTO.safeParse(req.body);
  if (!parse.success) return res.status(400).json(ResponseUtils.fail("Invalid data"));
  try {
    const token = await AuthService.register(parse.data.email, parse.data.password);
    res.json(ResponseUtils.ok({ token }));
  } catch {
    res.status(409).json(ResponseUtils.fail("Email already in use"));
  }
}

async function authPostLogin(req: any, res: any) {
  const parse = LoginDTO.safeParse(req.body);
  if (!parse.success) return res.status(400).json(ResponseUtils.fail("Invalid data"));
  const token = await AuthService.login(parse.data.email, parse.data.password);
  if (!token) return res.status(401).json(ResponseUtils.fail("Invalid credentials"));
  res.json(ResponseUtils.ok({ token }));
}

export {
  authPostRegister as postRegister,
  authPostLogin as postLogin
};
