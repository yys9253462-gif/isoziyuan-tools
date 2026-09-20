-- 0000.sql
CREATE TABLE IF NOT EXISTS `comments` (
	`id` integer PRIMARY KEY NOT NULL,
	`feed_id` integer NOT NULL,
	`user_id` integer NOT NULL,
	`content` text NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL,
	FOREIGN KEY (`feed_id`) REFERENCES `feeds`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS `feed_hashtags` (
	`feed_id` integer NOT NULL,
	`hashtag_id` integer NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL,
	FOREIGN KEY (`feed_id`) REFERENCES `feeds`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`hashtag_id`) REFERENCES `hashtags`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS `feeds` (
	`id` integer PRIMARY KEY NOT NULL,
	`alias` text,
	`title` text,
	`content` text NOT NULL,
    `summary` text DEFAULT '' NOT NULL,
	`listed` integer DEFAULT 1 NOT NULL,
	`draft` integer DEFAULT 1 NOT NULL,
	`top` integer DEFAULT 0 NOT NULL,
	`uid` integer NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL,
	FOREIGN KEY (`uid`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS `friends` (
	`id` integer PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`desc` text,
	`avatar` text NOT NULL,
	`url` text NOT NULL,
	`uid` integer NOT NULL,
	`accepted` integer DEFAULT 0 NOT NULL,
	`health` text DEFAULT '' NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL,
	FOREIGN KEY (`uid`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS `hashtags` (
	`id` integer PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS `users` (
	`id` integer PRIMARY KEY NOT NULL,
	`username` text NOT NULL,
	`openid` text NOT NULL,
	`avatar` text,
	`permission` integer DEFAULT 0,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL
);


-- 0001.sql
CREATE TABLE IF NOT EXISTS `visits` (
	`id` integer PRIMARY KEY NOT NULL,
	`feed_id` integer NOT NULL,
	`ip` text NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	FOREIGN KEY (`feed_id`) REFERENCES `feeds`(`id`) ON UPDATE no action ON DELETE cascade
);


-- 0002.sql
CREATE TABLE IF NOT EXISTS `info` (
	`key` text NOT NULL,
	`value` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `info_key_unique` ON `info` (`key`);
--> statement-breakpoint
INSERT INTO `info` (`key`, `value`) VALUES ('migration_version', '2');

-- 0003.sql
ALTER TABLE `friends` ADD COLUMN `sort_order` integer DEFAULT 0 NOT NULL;
--> statement-breakpoint
UPDATE `info` SET `value` = '3' WHERE `key` = 'migration_version';

-- 0004.sql
CREATE TABLE IF NOT EXISTS `moments` (
	`id` integer PRIMARY KEY NOT NULL,
	`content` text NOT NULL,
	`uid` integer NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL,
	FOREIGN KEY (`uid`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
UPDATE `info` SET `value` = '4' WHERE `key` = 'migration_version';

-- 0005.sql
ALTER TABLE `feeds` ADD COLUMN `ai_summary` text DEFAULT '' NOT NULL;
-->statement-breakpoint
UPDATE `info` SET `value` = '5' WHERE `key` = 'migration_version';


-- 0006.sql
CREATE TABLE IF NOT EXISTS `visit_stats` (
	`feed_id` integer PRIMARY KEY NOT NULL,
	`pv` integer DEFAULT 0 NOT NULL,
	`hll_data` text DEFAULT '' NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL,
	FOREIGN KEY (`feed_id`) REFERENCES `feeds`(`id`) ON UPDATE no action ON DELETE cascade
);
-->statement-breakpoint
-- Migrate existing data from visits table to visit_stats
INSERT INTO `visit_stats` (`feed_id`, `pv`, `hll_data`, `updated_at`)
SELECT 
	`feed_id`,
	COUNT(*) as pv,
	'' as hll_data,
	unixepoch() as updated_at
FROM `visits`
GROUP BY `feed_id`;
-->statement-breakpoint
UPDATE `info` SET `value` = '6' WHERE `key` = 'migration_version';


-- 0007.sql
CREATE TABLE IF NOT EXISTS `cache` (
	`id` integer PRIMARY KEY NOT NULL,
	`key` text NOT NULL,
	`value` text NOT NULL,
	`type` text DEFAULT 'cache' NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `cache_key_type_unique` ON `cache` (`key`,`type`);
-->statement-breakpoint
UPDATE `info` SET `value` = '7' WHERE `key` = 'migration_version';

-- 0008.sql
-- Add password column to users table for password-based authentication
ALTER TABLE `users` ADD COLUMN `password` text;
--> statement-breakpoint
UPDATE `info` SET `value` = '8' WHERE `key` = 'migration_version';


-- 0009.sql
ALTER TABLE `feeds` ADD COLUMN `ai_summary_status` text DEFAULT 'idle' NOT NULL;
--> statement-breakpoint
ALTER TABLE `feeds` ADD COLUMN `ai_summary_error` text DEFAULT '' NOT NULL;
--> statement-breakpoint
UPDATE `info` SET `value` = '9' WHERE `key` = 'migration_version';


-- 0010.sql
-- Guest comments support
-- Recreate comments table with nullable user_id, add guest fields and approved flag
-- We ALTER can't change NOT NULL in SQLite, so we recreate the table.

--> statement-breakpoint
CREATE TABLE IF NOT EXISTS `comments_new` (
	`id` integer PRIMARY KEY NOT NULL,
	`feed_id` integer NOT NULL,
	`user_id` integer,
	`content` text NOT NULL,
	`guest_name` text DEFAULT '',
	`guest_email` text DEFAULT '',
	`guest_website` text DEFAULT '',
	`approved` integer DEFAULT 1 NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL,
	FOREIGN KEY (`feed_id`) REFERENCES `feeds`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

--> statement-breakpoint
INSERT INTO `comments_new` (`id`, `feed_id`, `user_id`, `content`, `created_at`, `updated_at`)
	SELECT `id`, `feed_id`, `user_id`, `content`, `created_at`, `updated_at` FROM `comments`;

--> statement-breakpoint
DROP TABLE `comments`;

--> statement-breakpoint
ALTER TABLE `comments_new` RENAME TO `comments`;

--> statement-breakpoint
UPDATE `info` SET `value` = '10' WHERE `key` = 'migration_version';


-- 0011.sql
CREATE INDEX IF NOT EXISTS `feeds_alias_idx` ON `feeds` (`alias`);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `feeds_visibility_order_idx` ON `feeds` (`draft`, `listed`, `top`, `created_at`, `updated_at`);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `feeds_uid_idx` ON `feeds` (`uid`);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `visits_feed_created_at_idx` ON `visits` (`feed_id`, `created_at`);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `friends_accepted_order_idx` ON `friends` (`accepted`, `sort_order`, `created_at`);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `users_openid_idx` ON `users` (`openid`);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `comments_feed_created_at_idx` ON `comments` (`feed_id`, `created_at`);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `hashtags_name_idx` ON `hashtags` (`name`);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `feed_hashtags_feed_hashtag_idx` ON `feed_hashtags` (`feed_id`, `hashtag_id`);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `feed_hashtags_hashtag_feed_idx` ON `feed_hashtags` (`hashtag_id`, `feed_id`);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `cache_type_key_idx` ON `cache` (`type`, `key`);
--> statement-breakpoint
UPDATE `info` SET `value` = '11' WHERE `key` = 'migration_version';


-- 0012.sql
-- The CLI migration preflight repairs feeds.top when it is missing. Keeping
-- that conditional check outside SQL avoids SQLite's unsupported
-- `ADD COLUMN IF NOT EXISTS` syntax and makes this migration safe for
-- databases where the column already exists.

DROP INDEX IF EXISTS `feeds_visibility_order_idx`;
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `feeds_visibility_order_idx` ON `feeds` (`draft`, `listed`, `top`, `created_at`, `updated_at`);
--> statement-breakpoint
UPDATE `info` SET `value` = '12' WHERE `key` = 'migration_version';
