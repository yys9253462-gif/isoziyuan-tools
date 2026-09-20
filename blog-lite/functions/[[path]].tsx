/** @jsxImportSource hono/jsx */
import { Hono } from 'hono';
import { handle } from 'hono/cloudflare-pages';
import { getCookie, setCookie, deleteCookie } from 'hono/cookie';
import { drizzle } from 'drizzle-orm/d1';
import { eq, desc } from 'drizzle-orm';
import { posts } from '../db/schema'; // Ensure this path is correct
import type { Post } from '../db/schema';

// --- Types ---
type Env = {
    Bindings: {
        DB: D1Database;
        ADMIN_PASSWORD?: string;
        SESSION_PASSWORD?: string;
    };
};

const app = new Hono<Env>();

// --- Layout ---
const Layout = (props: { title: string; children: any; isLoggedIn?: boolean }) => {
    return (
        <html lang="zh-CN">
            <head>
                <meta charset="UTF-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <title>{props.title}</title>
                <script src="https://cdn.tailwindcss.com"></script>
                <style dangerouslySetInnerHTML={{
                    __html: `
          body { font-family: 'Inter', sans-serif; }
        ` }} />
            </head>
            <body class="bg-gray-50 min-h-screen text-gray-900">
                <header class="bg-white border-b border-gray-200">
                    <div class="max-w-4xl mx-auto px-6 py-4 flex justify-between items-center">
                        <a href="/" class="text-xl font-bold tracking-tight text-gray-900">我的博客</a>
                        <nav class="space-x-4 text-sm font-medium">
                            <a href="/" class="text-gray-500 hover:text-gray-900 transition-colors">首页</a>
                            {props.isLoggedIn ? (
                                <>
                                    <a href="/admin" class="text-blue-600 hover:text-blue-800 transition-colors">管理后台</a>
                                    <form action="/admin/logout" method="post" class="inline">
                                        <button type="submit" class="text-gray-500 hover:text-red-600 ml-4 transition-colors">退出登录</button>
                                    </form>
                                </>
                            ) : (
                                <a href="/admin/login" class="text-gray-500 hover:text-gray-900 transition-colors">登录</a>
                            )}
                        </nav>
                    </div>
                </header>
                <main class="max-w-4xl mx-auto px-6 py-12">
                    {props.children}
                </main>
                <footer class="border-t border-gray-200 mt-12 py-8 text-center text-sm text-gray-400">
                    &copy; {new Date().getFullYear()} 我的博客. 版权所有.
                </footer>
            </body>
        </html>
    );
};

// --- Middleware ---
// Protect /admin routes (except login)
app.use('/admin/*', async (c, next) => {
    if (c.req.path === '/admin/login' || c.req.path === '/admin/logout') {
        return next();
    }
    const session = getCookie(c, 'session_auth');
    if (!session || session !== 'authenticated') {
        return c.redirect('/admin/login');
    }
    return next();
});

// --- Public Routes ---

// Home: List published posts
app.get('/', async (c) => {
    try {
        const db = drizzle(c.env.DB);
        const publishedPosts = await db.select().from(posts)
            .where(eq(posts.status, 'published'))
            .orderBy(desc(posts.createdAt));

        const isLoggedIn = getCookie(c, 'session_auth') === 'authenticated';

        return c.html(
            <Layout title="我的博客" isLoggedIn={isLoggedIn}>
                <div class="space-y-12">
                    {publishedPosts.length === 0 ? (
                        <div class="text-center py-20">
                            <p class="text-gray-500 text-lg">暂无文章。</p>
                        </div>
                    ) : (
                        publishedPosts.map((post) => (
                            <article key={post.id} class="group relative flex flex-col items-start">
                                <h2 class="text-2xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors">
                                    <a href={`/posts/${post.slug}`}>
                                        <span class="absolute -inset-y-6 -inset-x-4 z-0 scale-95 bg-gray-100 opacity-0 transition group-hover:scale-100 group-hover:opacity-100 sm:-inset-x-6 sm:rounded-2xl"></span>
                                        <span class="relative z-10">{post.title}</span>
                                    </a>
                                </h2>
                                <time class="relative z-10 order-first mb-3 flex items-center text-sm text-gray-500 pl-3.5" datetime={new Date(post.createdAt).toISOString()}>
                                    <span class="absolute inset-y-0 left-0 flex items-center" aria-hidden="true">
                                        <span class="h-4 w-0.5 rounded-full bg-gray-200"></span>
                                    </span>
                                    {new Date(post.createdAt).toLocaleDateString()}
                                </time>
                                <p class="relative z-10 mt-2 text-sm leading-6 text-gray-600 line-clamp-3">{post.content.substring(0, 200)}...</p>
                                <div class="relative z-10 mt-4 flex items-center text-sm font-medium text-blue-600">
                                    此时阅读 <span aria-hidden="true" class="ml-1">→</span>
                                </div>
                            </article>
                        ))
                    )}
                </div>
            </Layout>
        );
    } catch (e: any) {
        return c.html(<Layout title="错误"><div class="text-red-500">错误: {e.message}</div></Layout>);
    }
});

// Post Detail
app.get('/posts/:slug', async (c) => {
    const slug = c.req.param('slug');
    const db = drizzle(c.env.DB);
    const result = await db.select().from(posts).where(eq(posts.slug, slug)).limit(1);
    const post = result[0];

    const isLoggedIn = getCookie(c, 'session_auth') === 'authenticated';

    if (!post) {
        return c.notFound();
    }

    return c.html(
        <Layout title={post.title} isLoggedIn={isLoggedIn}>
            <article>
                <header class="flex flex-col">
                    <h1 class="mt-6 text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl">{post.title}</h1>
                    <time datetime={new Date(post.createdAt).toISOString()} class="order-first flex items-center text-base text-gray-500">
                        <span class="h-4 w-0.5 rounded-full bg-gray-200 mr-3"></span>
                        {new Date(post.createdAt).toLocaleDateString()}
                    </time>
                </header>
                <div class="mt-8 prose prose-gray max-w-none">
                    <div dangerouslySetInnerHTML={{ __html: post.content.replace(/\n/g, '<br/>') }} />
                </div>
            </article>
        </Layout>
    );
});

// --- Admin Routes ---

// Login Page
app.get('/admin/login', (c) => {
    const error = c.req.query('error');
    return c.html(
        <Layout title="管理后台登录">
            <div class="flex min-h-[50vh] items-center justify-center">
                <div class="w-full max-w-sm space-y-8">
                    <div class="text-center">
                        <h2 class="text-2xl font-bold tracking-tight text-gray-900">登录管理后台</h2>
                    </div>
                    <form action="/admin/login" method="post" class="mt-8 space-y-6">
                        <div>
                            <label for="password" class="sr-only">密码</label>
                            <input id="password" name="password" type="password" required class="relative block w-full rounded-md border-0 py-1.5 px-3 text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:z-10 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6" placeholder="管理员密码" />
                        </div>
                        {error && <p class="text-red-500 text-sm text-center">密码错误</p>}
                        <div>
                            <button type="submit" class="group relative flex w-full justify-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600">
                                登录
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </Layout>
    );
});

// Login Action
app.post('/admin/login', async (c) => {
    const body = await c.req.parseBody();
    const password = body['password'] as string;
    const envPassword = c.env.ADMIN_PASSWORD;

    // Simple check - in production use secure compare
    if (password === envPassword) {
        setCookie(c, 'session_auth', 'authenticated', {
            httpOnly: true,
            secure: true,
            path: '/',
            maxAge: 60 * 60 * 24 // 1 day
        });
        return c.redirect('/admin');
    } else {
        return c.redirect('/admin/login?error=1');
    }
});

// Logout
app.post('/admin/logout', (c) => {
    deleteCookie(c, 'session_auth');
    return c.redirect('/');
});

// Admin Dashboard
app.get('/admin', async (c) => {
    const db = drizzle(c.env.DB);
    const allPosts = await db.select().from(posts).orderBy(desc(posts.createdAt));

    return c.html(
        <Layout title="管理后台" isLoggedIn={true}>
            <div class="sm:flex sm:items-center">
                <div class="sm:flex-auto">
                    <h1 class="text-2xl font-semibold leading-6 text-gray-900">仪表盘</h1>
                    <p class="mt-2 text-sm text-gray-700">管理你的博客文章。</p>
                </div>
                <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
                    <a href="/admin/new" class="block rounded-md bg-blue-600 px-3 py-2 text-center text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600">新建文章</a>
                </div>
            </div>
            <div class="mt-8 flow-root">
                <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                    <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                        <table class="min-w-full divide-y divide-gray-300">
                            <thead>
                                <tr>
                                    <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">标题</th>
                                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">状态</th>
                                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">日期</th>
                                    <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                                        <span class="sr-only">编辑</span>
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-200">
                                {allPosts.map((post) => (
                                    <tr key={post.id}>
                                        <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">{post.title}</td>
                                        <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                            <span class={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset ${post.status === 'published' ? 'bg-green-50 text-green-700 ring-green-600/20' : 'bg-yellow-50 text-yellow-800 ring-yellow-600/20'}`}>
                                                {post.status === 'published' ? '已发布' : '草稿'}
                                            </span>
                                        </td>
                                        <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{new Date(post.createdAt).toLocaleDateString()}</td>
                                        <td class="whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                                            <div class="flex justify-end gap-2">
                                                <a href={`/admin/edit/${post.id}`} class="text-blue-600 hover:text-blue-900">编辑</a>
                                                <form action={`/admin/delete/${post.id}`} method="post" onsubmit="return confirm('确定要删除吗？')">
                                                    <button type="submit" class="text-red-600 hover:text-red-900 ml-2">删除</button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </Layout>
    );
});

// New Post Form
app.get('/admin/new', (c) => {
    return c.html(
        <Layout title="新建文章" isLoggedIn={true}>
            <h1 class="text-2xl font-bold mb-6">新建文章</h1>
            <form action="/admin/new" method="post" class="space-y-6 max-w-2xl">
                <div>
                    <label for="title" class="block text-sm font-medium leading-6 text-gray-900">标题</label>
                    <div class="mt-2">
                        <input type="text" name="title" id="title" required class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6" />
                    </div>
                </div>
                <div>
                    <label for="slug" class="block text-sm font-medium leading-6 text-gray-900">URL 别名 (Slug)</label>
                    <div class="mt-2">
                        <input type="text" name="slug" id="slug" required class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6" />
                    </div>
                </div>
                <div>
                    <label for="status" class="block text-sm font-medium leading-6 text-gray-900">状态</label>
                    <select id="status" name="status" class="mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-blue-600 sm:text-sm sm:leading-6">
                        <option value="draft">草稿</option>
                        <option value="published">发布</option>
                    </select>
                </div>
                <div>
                    <label for="content" class="block text-sm font-medium leading-6 text-gray-900">内容</label>
                    <div class="mt-2">
                        <textarea id="content" name="content" rows={10} required class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"></textarea>
                    </div>
                </div>
                <div>
                    <button type="submit" class="rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600">创建文章</button>
                    <a href="/admin" class="ml-4 text-sm font-semibold leading-6 text-gray-900">取消</a>
                </div>
            </form>
        </Layout>
    );
});

// Create Post Action
app.post('/admin/new', async (c) => {
    const body = await c.req.parseBody();
    const db = drizzle(c.env.DB);

    await db.insert(posts).values({
        title: body['title'] as string,
        slug: body['slug'] as string,
        content: body['content'] as string,
        status: body['status'] as 'draft' | 'published',
    });

    return c.redirect('/admin');
});

// Edit Post Form
app.get('/admin/edit/:id', async (c) => {
    const id = parseInt(c.req.param('id'));
    const db = drizzle(c.env.DB);
    const result = await db.select().from(posts).where(eq(posts.id, id)).limit(1);
    const post = result[0];

    if (!post) return c.notFound();

    return c.html(
        <Layout title="编辑文章" isLoggedIn={true}>
            <h1 class="text-2xl font-bold mb-6">编辑文章</h1>
            <form action={`/admin/edit/${id}`} method="post" class="space-y-6 max-w-2xl">
                <div>
                    <label for="title" class="block text-sm font-medium leading-6 text-gray-900">标题</label>
                    <div class="mt-2">
                        <input type="text" name="title" id="title" value={post.title} required class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6" />
                    </div>
                </div>
                <div>
                    <label for="slug" class="block text-sm font-medium leading-6 text-gray-900">URL 别名 (Slug)</label>
                    <div class="mt-2">
                        <input type="text" name="slug" id="slug" value={post.slug} required class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6" />
                    </div>
                </div>
                <div>
                    <label for="status" class="block text-sm font-medium leading-6 text-gray-900">状态</label>
                    <select id="status" name="status" class="mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-blue-600 sm:text-sm sm:leading-6">
                        <option value="draft" selected={post.status === 'draft'}>草稿</option>
                        <option value="published" selected={post.status === 'published'}>发布</option>
                    </select>
                </div>
                <div>
                    <label for="content" class="block text-sm font-medium leading-6 text-gray-900">内容</label>
                    <div class="mt-2">
                        <textarea id="content" name="content" rows={10} required class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6">{post.content}</textarea>
                    </div>
                </div>
                <div>
                    <button type="submit" class="rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600">更新文章</button>
                    <a href="/admin" class="ml-4 text-sm font-semibold leading-6 text-gray-900">取消</a>
                </div>
            </form>
        </Layout>
    );
});

// Update Post Action
app.post('/admin/edit/:id', async (c) => {
    const id = parseInt(c.req.param('id'));
    const body = await c.req.parseBody();
    const db = drizzle(c.env.DB);

    await db.update(posts).set({
        title: body['title'] as string,
        slug: body['slug'] as string,
        content: body['content'] as string,
        status: body['status'] as 'draft' | 'published',
        updatedAt: new Date()
    }).where(eq(posts.id, id));

    return c.redirect('/admin');
});

// Delete Post Action
app.post('/admin/delete/:id', async (c) => {
    const id = parseInt(c.req.param('id'));
    const db = drizzle(c.env.DB);
    await db.delete(posts).where(eq(posts.id, id));
    return c.redirect('/admin');
});


// Database Setup Route
app.get('/admin/setup', (c) => {
    return c.html(
        <Layout title="数据库初始化">
            <div class="flex min-h-[50vh] items-center justify-center">
                <div class="w-full max-w-lg space-y-8">
                    <div class="text-center">
                        <h2 class="text-2xl font-bold tracking-tight text-gray-900">数据库初始化</h2>
                        <p class="mt-2 text-gray-600">这将创建所需的数据库表。仅需运行一次。</p>
                    </div>
                    <form action="/admin/setup" method="post" class="mt-8 space-y-6 bg-white p-8 rounded-lg shadow border border-gray-200">
                        <div>
                            <label for="password" class="block text-sm font-medium text-gray-700">管理员密码</label>
                            <input id="password" name="password" type="password" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm border p-2" placeholder="输入 ADMIN_PASSWORD" />
                        </div>
                        <button type="submit" class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                            初始化数据库
                        </button>
                    </form>
                </div>
            </div>
        </Layout>
    );
});

app.post('/admin/setup', async (c) => {
    const body = await c.req.parseBody();
    const password = body['password'] as string;

    if (password !== c.env.ADMIN_PASSWORD) {
        return c.text('密码错误', 403);
    }

    const sqlStatements = [
        `CREATE TABLE IF NOT EXISTS posts (
            id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
            title text NOT NULL,
            slug text NOT NULL,
            content text NOT NULL,
            status text DEFAULT 'draft' NOT NULL,
            created_at integer DEFAULT (strftime('%s', 'now')) NOT NULL,
            updated_at integer DEFAULT (strftime('%s', 'now'))
        );`,
        `CREATE UNIQUE INDEX IF NOT EXISTS posts_slug_unique ON posts (slug);`
    ];

    try {
        for (const statement of sqlStatements) {
            await c.env.DB.prepare(statement).run();
        }
        return c.html(
            <Layout title="初始化成功">
                <div class="flex flex-col items-center justify-center min-h-[50vh] space-y-4">
                    <h1 class="text-2xl font-bold text-green-600">数据库初始化成功！/ Database Initialized!</h1>
                    <p>您现在可以登录后台发布文章了。</p>
                    <a href="/admin/login" class="text-blue-600 hover:underline">前往登录页面</a>
                </div>
            </Layout>
        );
    } catch (e: any) {
        return c.html(<Layout title="初始化失败"><div class="text-red-500 p-8">初始化失败: {e.message}</div></Layout>);
    }
});

export const onRequest = handle(app);
