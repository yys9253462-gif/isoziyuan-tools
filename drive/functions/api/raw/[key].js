export async function onRequestGet({ params, env }) {
  const key = decodeURIComponent(params.key || "");
  if (!key) {
    return new Response("Not found", { status: 404 });
  }

  const bucket = env.DRIVE_BUCKET;
  if (!bucket) {
    return new Response("R2 Bucket not bound", { status: 500 });
  }

  const object = await bucket.get(key);
  if (!object) {
    return new Response("File not found", { status: 404 });
  }

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set("etag", object.httpEtag);
  headers.set("Cache-Control", "public, max-age=31536000");

  return new Response(object.body, { headers });
}
