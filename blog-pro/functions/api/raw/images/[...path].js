export async function onRequestGet({ params, env }) {
  const key = `images/${params.path.join('/')}`;
  const bucket = env.MEDIA_BUCKET;
  if (!bucket) return new Response("Bucket not found", { status: 500 });

  const object = await bucket.get(key);
  if (!object) return new Response("Not found", { status: 404 });

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set("Cache-Control", "public, max-age=31536000");
  return new Response(object.body, { headers });
}
