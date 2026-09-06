-- Phase 3 : fil d'actualité, publications, likes, commentaires, follow.

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  city text,
  country text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index posts_author_id_created_at_idx on public.posts (author_id, created_at desc);
create index posts_created_at_idx on public.posts (created_at desc);

drop trigger if exists set_posts_updated_at on public.posts;
create trigger set_posts_updated_at
  before update on public.posts
  for each row
  execute function public.set_updated_at();

create table public.post_media (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  url text not null,
  type text not null default 'image' check (type in ('image', 'video')),
  position int not null default 0
);

create index post_media_post_id_idx on public.post_media (post_id, position);

create table public.likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, profile_id)
);

create index likes_post_id_idx on public.likes (post_id);
create index likes_profile_id_idx on public.likes (profile_id);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  parent_comment_id uuid references public.comments (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index comments_post_id_created_at_idx on public.comments (post_id, created_at);

create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  following_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint follows_no_self_follow check (follower_id <> following_id)
);

create index follows_following_id_idx on public.follows (following_id);
create index follows_follower_id_idx on public.follows (follower_id);

create table public.saved_posts (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  post_id uuid not null references public.posts (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (profile_id, post_id)
);

-- RLS
alter table public.posts enable row level security;
alter table public.post_media enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.follows enable row level security;
alter table public.saved_posts enable row level security;

create policy "Posts are viewable by everyone"
  on public.posts for select using (true);
create policy "Users can create their own posts"
  on public.posts for insert with check (auth.uid() = author_id);
create policy "Users can update their own posts"
  on public.posts for update using (auth.uid() = author_id);
create policy "Users can delete their own posts"
  on public.posts for delete using (auth.uid() = author_id);

create policy "Post media are viewable by everyone"
  on public.post_media for select using (true);
create policy "Users can attach media to their own posts"
  on public.post_media for insert
  with check (
    exists (
      select 1 from public.posts
      where posts.id = post_media.post_id and posts.author_id = auth.uid()
    )
  );
create policy "Users can delete media from their own posts"
  on public.post_media for delete
  using (
    exists (
      select 1 from public.posts
      where posts.id = post_media.post_id and posts.author_id = auth.uid()
    )
  );

create policy "Likes are viewable by everyone"
  on public.likes for select using (true);
create policy "Users can like as themselves"
  on public.likes for insert with check (auth.uid() = profile_id);
create policy "Users can remove their own like"
  on public.likes for delete using (auth.uid() = profile_id);

create policy "Comments are viewable by everyone"
  on public.comments for select using (true);
create policy "Users can comment as themselves"
  on public.comments for insert with check (auth.uid() = author_id);
create policy "Users can delete their own comments"
  on public.comments for delete using (auth.uid() = author_id);

create policy "Follows are viewable by everyone"
  on public.follows for select using (true);
create policy "Users can follow as themselves"
  on public.follows for insert with check (auth.uid() = follower_id);
create policy "Users can unfollow as themselves"
  on public.follows for delete using (auth.uid() = follower_id);

create policy "Users can view their own saved posts"
  on public.saved_posts for select using (auth.uid() = profile_id);
create policy "Users can save as themselves"
  on public.saved_posts for insert with check (auth.uid() = profile_id);
create policy "Users can unsave as themselves"
  on public.saved_posts for delete using (auth.uid() = profile_id);
