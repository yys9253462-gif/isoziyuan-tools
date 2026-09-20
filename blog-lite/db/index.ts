/// <reference types="@cloudflare/workers-types" />

import { drizzle } from 'drizzle-orm/d1';
import * as schema from './schema';

export const getDb = (dbBinding: D1Database) => {
    return drizzle(dbBinding, { schema });
};

// Helper to get DB binding from environment
export const getDbBinding = (): D1Database => {
    // In Cloudflare Pages, DB is available via process.env
    // During build, this might be undefined, so we return a mock
    if (typeof process !== 'undefined' && (process.env as any).DB) {
        return (process.env as any).DB as D1Database;
    }
    // Return a mock for build time (won't be used)
    return null as any;
};
