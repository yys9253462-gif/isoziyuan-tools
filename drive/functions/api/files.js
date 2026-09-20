function checkAuth(request, env) {
  const adminPass = env.ADMIN_PASSWORD;
  if (!adminPass) return true; // 未设置密码则默认允许
  const authHeader = request.headers.get("Authorization") || "";
  return authHeader === adminPass;
}

export async function onRequestGet({ request, env }) {
  if (!checkAuth(request, env)) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  const url = new URL(request.url);
  const cursor = url.searchParams.get("cursor");
  const limit = Math.min(parseInt(url.searchParams.get("limit") || "100"), 100);

  const bucket = env.DRIVE_BUCKET;
  if (!bucket) {
    return new Response(JSON.stringify({ error: "R2 Bucket not bound" }), { status: 500 });
  }

  const listed = await bucket.list({
    limit,
    cursor: cursor || undefined,
  });

  return new Response(JSON.stringify(listed), {
    headers: { "Content-Type": "application/json" }
  });
}

export async function onRequestDelete({ request, env }) {
  if (!checkAuth(request, env)) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  const url = new URL(request.url);
  const key = url.searchParams.get("key");
  if (!key) {
    return new Response("Missing key", { status: 400 });
  }

  const bucket = env.DRIVE_BUCKET;
  await bucket.delete(key);
  return new Response("Deleted", { status: 200 });
}
