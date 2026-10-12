import { errorResponse, filePayload, isAdmin, json, normalizePath, requireAdmin } from "../_lib.js";

export async function onRequestGet({ request, env }) {
  const denied = requireAdmin(await isAdmin(request, env));
  if (denied) return denied;
  const folder = normalizePath(new URL(request.url).searchParams.get("folder"), true);
  const storage = new URL(request.url).searchParams.get("storage") === "aws" ? "aws" : "r2";
  try {
    const now = Math.floor(Date.now() / 1000);
    const result = await env.DB.prepare("SELECT *, (SELECT COUNT(*) FROM shares WHERE shares.file_id = files.id) AS share_count, (SELECT COUNT(*) FROM shares WHERE shares.file_id = files.id AND (expires_at = 0 OR expires_at > ?2)) AS share_active FROM files WHERE storage = ?1 AND folder = ?3 ORDER BY kind DESC, name COLLATE NOCASE ASC").bind(storage, now, folder).all();
    return json({ folder, storage, files: (result.results || []).map(filePayload) });
  } catch (error) {
    return errorResponse(error, "无法读取文件列表");
  }
}
