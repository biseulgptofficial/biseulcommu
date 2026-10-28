-- 로그인 없는 버전. 기존 profiles/posts/comments는 변경하거나 삭제하지 않습니다.
-- 새 community_* 테이블 전용 설치 SQL입니다. 기존 데이터는 자동 이전하지 않습니다.
begin;
create table if not exists public.community_posts (
 id uuid primary key default gen_random_uuid(),
 board text not null default 'free' check (board in ('free','notice')),
 title text not null check(char_length(trim(title)) between 2 and 120),
 body text not null check(char_length(trim(body)) between 1 and 5000),
 author_mode text not null default 'anonymous' check(author_mode in ('anonymous','custom')),
 display_name text,
 created_at timestamptz not null default now(),
 constraint community_posts_author_check check ((author_mode='anonymous' and display_name is null) or (author_mode='custom' and display_name is not null and char_length(trim(display_name)) between 2 and 20))
);
create table if not exists public.community_comments (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.community_posts(id) on delete cascade,
 body text not null check(char_length(trim(body)) between 1 and 1000),
 author_mode text not null default 'anonymous' check(author_mode in ('anonymous','custom')),
 display_name text,
 created_at timestamptz not null default now(),
 constraint community_comments_author_check check ((author_mode='anonymous' and display_name is null) or (author_mode='custom' and display_name is not null and char_length(trim(display_name)) between 2 and 20))
);
create index if not exists community_posts_date_idx on public.community_posts(created_at desc);
create index if not exists community_posts_board_date_idx on public.community_posts(board,created_at desc);
create index if not exists community_comments_post_idx on public.community_comments(post_id,created_at);
alter table public.community_posts enable row level security;
alter table public.community_comments enable row level security;
-- 브라우저 역할에는 읽기/제한된 컬럼의 삽입만 허용합니다.
revoke all on public.community_posts, public.community_comments from public,anon,authenticated;
grant usage on schema public to anon,authenticated;
grant select on public.community_posts, public.community_comments to anon,authenticated;
grant insert (board,title,body,author_mode,display_name) on public.community_posts to anon,authenticated;
grant insert (post_id,body,author_mode,display_name) on public.community_comments to anon,authenticated;
drop policy if exists community_posts_read on public.community_posts;
create policy community_posts_read on public.community_posts for select to anon,authenticated using(true);
drop policy if exists community_posts_insert on public.community_posts;
create policy community_posts_insert on public.community_posts for insert to anon,authenticated with check(board='free');
drop policy if exists community_comments_read on public.community_comments;
create policy community_comments_read on public.community_comments for select to anon,authenticated using(true);
drop policy if exists community_comments_insert on public.community_comments;
create policy community_comments_insert on public.community_comments for insert to anon,authenticated with check(exists(select 1 from public.community_posts p where p.id=post_id));
commit;
-- 공지사항 등록은 신뢰할 수 있는 Dashboard SQL Editor에서만 실행:
-- insert into public.community_posts(board,title,body,author_mode,display_name)
-- values('notice','공지 제목','공지 내용','custom','운영자');
