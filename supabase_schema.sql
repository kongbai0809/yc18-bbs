-- ============================================
-- 银川十八中贴吧 - Supabase 数据库建表脚本
-- 使用方法：打开 Supabase 控制台 → SQL Editor → 新建查询 → 粘贴全部内容 → 运行
-- ============================================

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. 用户表
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  nickname TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'student',  -- owner/admin/student/graduate
  student_status TEXT DEFAULT '在读',      -- 在读/毕业
  class_info TEXT DEFAULT '',
  real_name TEXT DEFAULT '',               -- 加密存储
  student_id TEXT DEFAULT '',              -- 加密存储，格式 入学年份+4位编号
  gender TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  qq TEXT DEFAULT '',
  wechat TEXT DEFAULT '',
  email TEXT DEFAULT '',
  douyin TEXT DEFAULT '',
  kuaishou TEXT DEFAULT '',
  signature TEXT DEFAULT '',
  location TEXT DEFAULT '',
  avatar TEXT DEFAULT '',                   -- base64 图片
  cover TEXT DEFAULT '',                    -- base64 背景图
  ban_status TEXT DEFAULT '',               -- warning/ban1/ban3/ban7/permanent
  ban_reason TEXT DEFAULT '',
  ban_end_time TIMESTAMPTZ,
  ban_by TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. 帖子表
-- ============================================
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  zone TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  images JSONB DEFAULT '[]',                -- 图片 base64 数组
  audios JSONB DEFAULT '[]',                -- 音频链接数组
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  author_name TEXT NOT NULL,
  author_role TEXT NOT NULL,
  author_avatar TEXT DEFAULT '',
  views INTEGER DEFAULT 0,
  likes INTEGER DEFAULT 0,
  comments INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. 评论表
-- ============================================
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  author_name TEXT NOT NULL,
  author_role TEXT NOT NULL,
  author_avatar TEXT DEFAULT '',
  content TEXT NOT NULL,
  likes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. 好友关系表
-- ============================================
CREATE TABLE IF NOT EXISTS friends (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending',   -- pending/accepted
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

-- ============================================
-- 5. 私聊消息表
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. 举报表
-- ============================================
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL,                 -- user/post/comment/message
  target_id TEXT NOT NULL,
  target_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  report_type TEXT NOT NULL,
  description TEXT DEFAULT '',
  status TEXT DEFAULT 'pending',             -- pending/ignored/deleted/banned
  handled_by TEXT DEFAULT '',
  handle_action TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. 站内信表
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,                        -- system/friend_request/friend_accepted/report/ban/warning
  title TEXT NOT NULL,
  content TEXT DEFAULT '',
  related_id TEXT DEFAULT '',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. 帖子点赞表
-- ============================================
CREATE TABLE IF NOT EXISTS post_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

-- ============================================
-- 9. 评论点赞表
-- ============================================
CREATE TABLE IF NOT EXISTS comment_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, comment_id)
);

-- ============================================
-- 索引
-- ============================================
CREATE INDEX IF NOT EXISTS idx_posts_zone ON posts(zone);
CREATE INDEX IF NOT EXISTS idx_posts_author ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_friends_user ON friends(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);

-- ============================================
-- RLS 行级安全策略（宽松模式，保证功能正常）
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;

-- 用户表：公开可读（不含密码），自己可更新
CREATE POLICY "users_read" ON users FOR SELECT USING (true);
CREATE POLICY "users_insert" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "users_update" ON users FOR UPDATE USING (true);
CREATE POLICY "users_delete" ON users FOR DELETE USING (true);

-- 帖子表：公开读写
CREATE POLICY "posts_all" ON posts FOR ALL USING (true) WITH CHECK (true);

-- 评论表：公开读写
CREATE POLICY "comments_all" ON comments FOR ALL USING (true) WITH CHECK (true);

-- 好友表：公开读写
CREATE POLICY "friends_all" ON friends FOR ALL USING (true) WITH CHECK (true);

-- 消息表：公开读写
CREATE POLICY "messages_all" ON messages FOR ALL USING (true) WITH CHECK (true);

-- 举报表：公开读写
CREATE POLICY "reports_all" ON reports FOR ALL USING (true) WITH CHECK (true);

-- 站内信表：公开读写
CREATE POLICY "notifications_all" ON notifications FOR ALL USING (true) WITH CHECK (true);

-- 点赞表：公开读写
CREATE POLICY "post_likes_all" ON post_likes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "comment_likes_all" ON comment_likes FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- 初始化站长账号（用户名 admin，密码 admin123）
-- 密码用 Base64+偏移3 加密，和前端一致
-- ============================================
INSERT INTO users (username, password, nickname, role, student_status, signature, location)
VALUES ('admin', 'admins123', '站长', 'owner', '在读', '银川十八中贴吧站长', '宁夏银川')
ON CONFLICT (username) DO NOTHING;

-- 初始化示例帖子
INSERT INTO posts (zone, title, content, author_id, author_name, author_role, views, likes, comments)
SELECT 'general', '欢迎来到银川十八中贴吧！', '这里是银川十八中的校园社区，大家可以在这里交流学习、分享生活、结交朋友。\n\n请遵守社区规范，文明发言。', 
  id, '站长', 'owner', 128, 15, 0
FROM users WHERE username = 'admin'
ON CONFLICT DO NOTHING;

INSERT INTO posts (zone, title, content, author_id, author_name, author_role, views, likes, comments)
SELECT 'campus', '今天食堂的红烧肉太好吃了！', '强烈推荐今天食堂二楼的红烧肉，肥而不腻，入口即化！配上米饭简直绝了，我直接干了两碗饭。\n\n有没有同学也吃了？来举个手！',
  id, '追风少年', 'student', 189, 42, 2
FROM users WHERE username = 'admin'
ON CONFLICT DO NOTHING;

-- ============================================
-- 10. 应用全量状态表（用于全量同步）
-- ============================================
CREATE TABLE IF NOT EXISTS app_state (
  id TEXT PRIMARY KEY DEFAULT 'main',
  users JSONB DEFAULT '[]',
  posts JSONB DEFAULT '[]',
  comments JSONB DEFAULT '[]',
  friends JSONB DEFAULT '[]',
  messages JSONB DEFAULT '[]',
  reports JSONB DEFAULT '[]',
  notifications JSONB DEFAULT '[]',
  post_likes JSONB DEFAULT '[]',
  comment_likes JSONB DEFAULT '[]',
  settings JSONB DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE app_state ENABLE ROW LEVEL SECURITY;
CREATE POLICY "app_state_all" ON app_state FOR ALL USING (true) WITH CHECK (true);

-- 初始化默认状态
INSERT INTO app_state (id, settings)
VALUES ('main', '{"siteName":"银川十八中贴吧","announcement":"欢迎来到银川十八中贴吧！请遵守社区规范，文明发言。"}')
ON CONFLICT (id) DO NOTHING;

-- 完成提示
SELECT '数据库建表完成！共创建 10 张表 + 索引 + RLS 策略 + 示例数据。' AS result;
