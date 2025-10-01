import { Router } from "express";
import { postLogin, postRegister } from "../modules/auth/auth.controller";
import { auth } from "../middlewares/auth";
import { listItems, createItem, deleteItem } from "../modules/items/items.controller";

export const router = Router();

// health check
router.get("/health", (_req, res) => res.json({ ok: true }));

// auth
router.post("/auth/register", postRegister);
router.post("/auth/login", postLogin);

// items (protected)
router.get("/items", auth, listItems);
router.post("/items", auth, createItem);
router.delete("/items/:id", auth, deleteItem);
