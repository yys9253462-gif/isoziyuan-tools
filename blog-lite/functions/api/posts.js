function checkAuth(request, env) {
  const adminPass = env.ADMIN_PASSWORD;
  if (!adminPass) return true;
  const auth = request.headers.get("Authorization") || "";
  return auth === adminPass;
}

export async function onRequestGet({ env }) {
  const db = env.DB;
  if (!db) return new Response("DB not bound", { status: 500 });
  const { results } = await db.prepare("SELECT * FROM posts WHERE published = 1 ORDER BY created_at DESC").all();
  return new Response(JSON.stringify(results || []), {
    headers: { "Content-Type": "application/json" }
  });
}

export async function onRequestPost({ request, env }) {
  if (!checkAuth(request, env)) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  const db = env.DB;
  if (!db) return new Response("DB not bound", { status: 500 });

  const data = await request.json().catch(() => ({}));
  const title = String(data.title || "").trim();
  const content = String(data.content || "").trim();
  const tags = String(data.tags || "").trim();
  const summary = String(data.summary || content.slice(0, 150)).trim();

  if (!title || !content) {
    return new Response("Missing title or content", { status: 400 });
  }

  const id = crypto.randomUUID();
  const slug = data.slug || `post-${Date.now()}`;
  const now = Date.now();

  await db.prepare(
    "INSERT INTO posts (id, title, slug, summary, content, tags, published, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)"
  ).bind(id, title, slug, summary, content, tags, now, now).run();

  return new Response(JSON.stringify({ success: true, id }), {
    headers: { "Content-Type": "application/json" }
  });
}

export async function onRequestDelete({ request, env }) {
  if (!checkAuth(request, env)) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  const url = new URL(request.url);
  const id = url.searchParams.get("id");
  if (!id) return new Response("Missing id", { status: 400 });

  const db = env.DB;
  await db.prepare("DELETE FROM posts WHERE id = ?").bind(id).run();
  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" }
  });
}
