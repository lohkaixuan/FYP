import { z } from "zod";

export const RegisterDTO = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

export const LoginDTO = RegisterDTO;

export type RegisterInput = z.infer<typeof RegisterDTO>;
export type LoginInput = z.infer<typeof LoginDTO>;
