export async function onRequestPut({ request, env }) {
  const adminPass = env.ADMIN_PASSWORD;
  if (adminPass) {
    const authHeader = request.headers.get("Authorization") || "";
    if (authHeader !== adminPass) {
      return new Response("Unauthorized", { status: 401 });
    }
  }

  const url = new URL(request.url);
  const key = url.searchParams.get("key");
  if (!key) {
    return new Response("Missing key parameter", { status: 400 });
  }

  const bucket = env.DRIVE_BUCKET;
  if (!bucket) {
    return new Response("R2 Bucket not bound", { status: 500 });
  }

  const contentType = request.headers.get("Content-Type") || "application/octet-stream";
  await bucket.put(key, request.body, {
    httpMetadata: { contentType }
  });

  return new Response(JSON.stringify({ success: true, key }), {
    headers: { "Content-Type": "application/json" }
  });
}
