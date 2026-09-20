export async function onRequestPost({ request, env }) {
  const adminPass = env.ADMIN_PASSWORD;
  if (adminPass) {
    const auth = request.headers.get("Authorization") || "";
    if (auth !== adminPass) return new Response("Unauthorized", { status: 401 });
  }

  const bucket = env.MEDIA_BUCKET;
  if (!bucket) return new Response("R2 Media Bucket not bound", { status: 500 });

  const formData = await request.formData();
  const file = formData.get("file");
  if (!file) return new Response("No file uploaded", { status: 400 });

  const ext = file.name.split('.').pop() || 'png';
  const key = `images/${Date.now()}-${crypto.randomUUID().slice(0, 8)}.${ext}`;

  await bucket.put(key, file.stream(), {
    httpMetadata: { contentType: file.type || "image/png" }
  });

  const url = `/api/raw/${key}`;
  return new Response(JSON.stringify({ success: true, url, key }), {
    headers: { "Content-Type": "application/json" }
  });
}
