import { z } from "zod";

export const CreateItemDTO = z.object({
  name: z.string().min(1),
});

export type CreateItemInput = z.infer<typeof CreateItemDTO>;
