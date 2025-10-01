import { prisma } from "../../lib/prisma";  // <- fix: named import & correct path
import { ok, fail } from "../../utils/response";
import { CreateItemDTO } from "./items.dto";

export async function listItems(req: any, res: any) {
  const items = await prisma.item.findMany({ where: { userId: req.userId } });
  res.json(ok(items));
}

export async function createItem(req: any, res: any) {
  const parse = CreateItemDTO.safeParse(req.body);
  if (!parse.success) return res.status(400).json(fail("Invalid data"));
  const item = await prisma.item.create({
    data: { name: parse.data.name, userId: req.userId }
  });
  res.status(201).json(ok(item));
}

export async function deleteItem(req: any, res: any) {
  const existing = await prisma.item.findUnique({ where: { id: req.params.id } });
  if (!existing || existing.userId !== req.userId)
    return res.status(404).json(fail("Not found"));
  await prisma.item.delete({ where: { id: req.params.id } });
  res.status(204).send();
}
