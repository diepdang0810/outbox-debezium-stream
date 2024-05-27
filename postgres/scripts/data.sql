create type enum_giphy_type as enum ('gif', 'sticker');

create type enum_media_status as enum ('waiting_process', 'processing', 'completed', 'failed');

create type enum_posts_privacy as enum ('CLOSED', 'OPEN', 'PRIVATE', 'SECRET', 'PUBLIC');

create type enum_posts_type as enum ('POST', 'ARTICLE', 'SERIES');

create type enum_posts_status as enum ('DRAFT', 'PROCESSING', 'PUBLISHED', 'WAITING_SCHEDULE', 'SCHEDULE_FAILED');

create type enum_quizzes_status as enum ('PENDING', 'DRAFT', 'PUBLISHED');

create type enum_quizzes_gen_status as enum ('PENDING', 'PROCESSING', 'PROCESSED', 'FAILED');

create type enum_reports_report_to as enum ('COMMUNITY', 'GROUP');

create type enum_reports_target_type as enum ('ARTICLE', 'POST', 'COMMENT');

create type enum_reports_status as enum ('CREATED', 'IGNORED', 'HID');

create type enum_reports_scope as enum ('MEMBER', 'GROUP_ADMIN', 'COMMUNITY_ADMIN');

create type enum_hidden_contents_target_type as enum ('ARTICLE', 'POST');

create type enum_daily_group_post_content_type as enum ('ALL', 'ARTICLE', 'POST', 'SERIES');

create type enum_hidden_contents_content_type as enum ('ARTICLE', 'POST');

create type enum_report_details_target_type as enum ('ARTICLE', 'POST', 'COMMENT');

create type enum_daily_community_content_counts_content_type as enum ('ALL', 'ARTICLE', 'POST', 'SERIES');

create type enum_daily_group_content_counts_content_type as enum ('ALL', 'ARTICLE', 'POST', 'SERIES');
create table if not exists "SequelizeMeta"
(
    name varchar(255) not null
        primary key
);

create table if not exists categories
(
    id         uuid                     default gen_random_uuid()                            not null
        primary key,
    parent_id  uuid                     default '00000000-0000-0000-0000-000000000000'::uuid not null,
    name       varchar(5000)                                                                 not null,
    slug       varchar(5000)                                                                 not null,
    level      smallint                                                                      not null,
    is_active  boolean                  default true                                         not null,
    created_at timestamp with time zone default CURRENT_TIMESTAMP                            not null,
    updated_at timestamp with time zone default CURRENT_TIMESTAMP                            not null,
    created_by uuid,
    updated_by uuid,
    index      integer                  default 1                                            not null,
    zindex     integer                  default 1                                            not null
);

create index if not exists categories_created_by
    on categories (created_by);


create table if not exists giphy
(
    id   varchar(255)                not null
        primary key,
    type enum_giphy_type not null
);

create unique index if not exists giphy_id_type
    on giphy (id, type);

create table if not exists hashtags
(
    id         uuid                     default gen_random_uuid() not null
        primary key,
    name       varchar(5)                                         not null,
    created_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    slug       varchar(255)
);

create table if not exists link_preview
(
    id          uuid                     default gen_random_uuid() not null
        primary key,
    url         varchar(2048),
    domain      varchar(255),
    image       varchar(2048),
    title       varchar(255),
    description varchar(2048),
    created_at  timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at  timestamp with time zone default CURRENT_TIMESTAMP not null
);

create unique index if not exists link_preview_url
    on link_preview (url);


create table if not exists posts
(
    comments_count        integer                       default 0                                   not null,
    is_important          boolean                       default false,
    important_expired_at  timestamp with time zone,
    can_share             boolean                       default true,
    can_comment           boolean                       default true,
    can_react             boolean                       default true,
    content               text,
    created_at            timestamp with time zone      default CURRENT_TIMESTAMP                   not null,
    updated_at            timestamp with time zone      default CURRENT_TIMESTAMP                   not null,
    id                    uuid                          default gen_random_uuid()                   not null
        constraint "posts_id_pk"
            primary key,
    title                 varchar(500),
    summary               varchar(5000),
    privacy               enum_posts_privacy,
    total_users_seen      integer                       default 0,
    lang                  varchar(3),
    created_by            uuid,
    updated_by            uuid,
    deleted_at            timestamp with time zone,
    link_preview_id       uuid,
    type                  enum_posts_type   default 'POST'::enum_posts_type not null,
    tags_json             jsonb,
    is_reported           boolean                       default false                               not null,
    is_hidden             boolean                       default false                               not null,
    status                enum_posts_status default 'DRAFT'::enum_posts_status,
    published_at          timestamp with time zone,
    error_log             jsonb,
    media_json            jsonb,
    cover_json            jsonb,
    mention_json          jsonb,
    video_id_processing   uuid,
    old_content           text,
    mentions              jsonb,
    word_count            integer                       default 0,
    quiz_id               uuid,
    scheduled_at          timestamp with time zone,
    parent_comments_count integer                       default 0                                   not null
);

create table if not exists comments
(
    total_reply integer                  default 0,
    content     varchar(5000),
    created_at  timestamp with time zone default CURRENT_TIMESTAMP                            not null,
    updated_at  timestamp with time zone,
    deleted_at  timestamp with time zone,
    edited      boolean                  default false,
    giphy_id    varchar(255),
    id          uuid                     default gen_random_uuid()                            not null
        constraint "comments_id_pk"
            primary key,
    post_id     uuid                                                                          not null
        constraint "comments_post_id_posts_fk"
            references posts
            on delete cascade,
    parent_id   uuid                     default '00000000-0000-0000-0000-000000000000'::uuid not null,
    created_by  uuid,
    updated_by  uuid,
    is_hidden   boolean                  default false,
    media_json  jsonb,
    mentions    jsonb
);

create index if not exists comments_post_id_parent_id_created_at_is_hidden
    on comments (post_id, parent_id, created_at, is_hidden);

create index if not exists comments_parent_id_created_at_index
    on comments (parent_id, created_at);

create index if not exists posts_is_hidden_deleted_at_status_published_at_type_is_impo_idx
    on posts (is_hidden, deleted_at, status, published_at, type, is_important, created_at, created_by);

create index if not exists index_table_a_column_tz_by_date
    on posts (published_at);

create index if not exists posts_created_by_is_hidden_status_published_at_type_idx
    on posts (created_by, is_hidden, status, published_at, type);

create index if not exists posts_created_by_composite_index
    on posts (created_by, is_hidden, status, published_at, type);

create table if not exists posts_categories
(
    post_id     uuid                                               not null
        constraint "posts_categories_post_id_posts_fk"
            references posts
            on delete cascade,
    category_id uuid                                               not null
        references categories,
    created_at  timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at  timestamp with time zone default CURRENT_TIMESTAMP not null,
    primary key (post_id, category_id)
);

create unique index if not exists posts_categories_post_id_category_id
    on posts_categories (post_id, category_id);

create table if not exists posts_groups
(
    created_at    timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at    timestamp with time zone default CURRENT_TIMESTAMP not null,
    post_id       uuid                                               not null
        constraint "posts_groups_post_id_posts_fk"
            references posts
            on delete cascade,
    group_id      uuid                                               not null,
    is_archived   boolean                  default false,
    is_pinned     boolean                  default false             not null,
    pinned_index  integer                  default 0                 not null,
    is_hidden     boolean,
    root_group_id uuid,
    primary key (post_id, group_id)
);

create index if not exists posts_groups_group_id_post_id_is_archived_is_hidden
    on posts_groups (group_id, post_id, is_archived, is_hidden);

create table if not exists posts_hashtags
(
    post_id    uuid                                               not null
        references posts,
    hashtag_id uuid                                               not null
        references hashtags,
    created_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    primary key (post_id, hashtag_id)
);

create unique index if not exists posts_hashtags_post_id_hashtag_id
    on posts_hashtags (post_id, hashtag_id);

create table if not exists posts_series
(
    post_id    uuid                                               not null
        constraint "posts_series_post_id_posts_fk"
            references posts
            on delete cascade,
    series_id  uuid                                               not null
        constraint "posts_series_series_id_posts_fk"
            references posts
            on delete cascade,
    created_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    zindex     integer                  default 0,
    primary key (post_id, series_id)
);

create index if not exists posts_series_series_id_post_id_zindex
    on posts_series (series_id, post_id, zindex);

create table if not exists recent_searches
(
    total_searched integer                  default 1                 not null,
    target         varchar(40)                                        not null,
    keyword        varchar(255)                                       not null,
    created_at     timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at     timestamp with time zone default CURRENT_TIMESTAMP not null,
    created_by     uuid,
    updated_by     uuid,
    id             uuid                     default gen_random_uuid() not null
        constraint "recent_searches_id_pk"
            primary key
);

create table if not exists user_newsfeed
(
    created_at   timestamp with time zone    default CURRENT_TIMESTAMP                   not null,
    is_seen_post boolean                     default false,
    post_id      uuid                                                                    not null
        constraint "user_newsfeed_post_id_posts_fk"
            references posts
            on delete cascade,
    user_id      uuid                                                                    not null,
    type         enum_posts_type default 'POST'::enum_posts_type not null,
    published_at timestamp with time zone,
    created_by   uuid,
    is_important boolean                     default false                               not null,
    primary key (user_id, post_id)
);

create index if not exists user_newsfeed_user_id_published_at_type_is_important_idx
    on user_newsfeed (user_id, published_at, type, is_important);

create index if not exists user_newsfeed_post_id
    on user_newsfeed (post_id);

create table if not exists users_mark_read_posts
(
    created_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    post_id    uuid                                               not null
        constraint "users_mark_read_posts_post_id_posts_fk"
            references posts
            on delete cascade,
    user_id    uuid                                               not null,
    primary key (post_id, user_id)
);

create index if not exists users_mark_read_posts_user_id_post_id_index
    on users_mark_read_posts (user_id, post_id);

create table if not exists users_seen_posts
(
    created_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    post_id    uuid                                               not null
        constraint "users_seen_posts_post_id_posts_fk"
            references posts
            on delete cascade,
    user_id    uuid                                               not null,
    primary key (user_id, post_id)
);

create index if not exists users_seen_posts_post_id_user_id_created_at
    on users_seen_posts (post_id, user_id, created_at);

create table if not exists users_save_posts
(
    user_id    uuid                                               not null,
    post_id    uuid                                               not null
        constraint "users_save_posts_post_id_posts_fk"
            references posts
            on delete cascade,
    created_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    primary key (user_id, post_id)
);

create index if not exists users_save_posts_post_id_user_id_created_at
    on users_save_posts (post_id, user_id, created_at);

create table if not exists tags
(
    id         uuid                     default gen_random_uuid() not null
        primary key,
    group_id   uuid                                               not null,
    name       varchar(32)                                        not null,
    slug       varchar(64)                                        not null,
    created_by uuid                                               not null,
    updated_by uuid                                               not null,
    created_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    total_used integer                  default 0                 not null
);

create table if not exists posts_tags
(
    post_id    uuid                                               not null
        constraint "posts_tags_post_id_posts_fk"
            references posts
            on delete cascade,
    tag_id     uuid                                               not null
        references tags,
    created_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    primary key (post_id, tag_id)
);

create unique index if not exists posts_tags_post_id_tag_id
    on posts_tags (post_id, tag_id);

create table if not exists report_contents
(
    id          uuid                     default gen_random_uuid()            not null
        primary key,
    updated_by  uuid,
    target_id   uuid                                                          not null,
    target_type varchar(30)                                                   not null,
    author_id   uuid                                                          not null,
    status      varchar(30)              default 'CREATED'::character varying not null,
    created_at  timestamp with time zone default CURRENT_TIMESTAMP            not null,
    updated_at  timestamp with time zone default CURRENT_TIMESTAMP
);

create index if not exists report_contents_target_id
    on report_contents (target_id);

create index if not exists report_contents_target_type
    on report_contents (target_type);

create table if not exists report_content_details
(
    id          uuid                     default gen_random_uuid() not null
        primary key,
    report_id   uuid                                               not null
        references report_contents
            on delete cascade,
    report_to   varchar(30)                                        not null,
    target_id   uuid                                               not null,
    target_type varchar(30)                                        not null,
    group_id    uuid,
    created_by  uuid                                               not null,
    reason_type varchar(60)                                        not null,
    reason      varchar(512),
    created_at  timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at  timestamp with time zone default CURRENT_TIMESTAMP
);

create index if not exists report_content_details_created_by_group_id
    on report_content_details (created_by, group_id);

create index if not exists report_content_details_report_id
    on report_content_details (report_id);

create index if not exists report_content_details_report_id_reason_type
    on report_content_details (report_id, reason_type);

create unique index if not exists report_content_details_target_id_group_id_created_by
    on report_content_details (target_id, group_id, created_by);

create table if not exists failed_process_posts
(
    id                    uuid                     default gen_random_uuid() not null
        primary key,
    post_id               uuid                                               not null,
    is_expired_processing boolean                  default false,
    reason                varchar(32),
    post_json             jsonb,
    created_at            timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at            timestamp with time zone default CURRENT_TIMESTAMP not null
);

create index if not exists failed_process_posts_post_id
    on failed_process_posts (post_id);

create table if not exists quizzes
(
    id                          uuid                            default gen_random_uuid() not null
        primary key,
    post_id                     uuid
        constraint "quizzes_content_id_posts_fk"
            references posts
            on delete cascade,
    title                       varchar(65)                     default false,
    status                      enum_quizzes_status default 'PENDING'::enum_quizzes_status,
    description                 varchar(256)                    default false,
    number_of_questions         smallint                        default 0                 not null,
    number_of_answers           smallint                        default 0                 not null,
    number_of_questions_display smallint,
    is_random                   boolean                         default true              not null,
    questions                   jsonb,
    created_by                  uuid,
    updated_by                  uuid,
    created_at                  timestamp with time zone        default CURRENT_TIMESTAMP not null,
    updated_at                  timestamp with time zone        default CURRENT_TIMESTAMP not null,
    meta                        jsonb,
    gen_status                  enum_quizzes_gen_status,
    error                       jsonb,
    time_limit                  integer                         default 1800              not null,
    published_at                timestamp with time zone
);

create index if not exists quizzes_post_id_created_by_status_created_at
    on quizzes (post_id, created_by, status, created_at);

create table if not exists quiz_participants
(
    id                    uuid                     default gen_random_uuid() not null
        constraint users_take_quizzes_pkey
            primary key,
    quiz_id               uuid                                               not null,
    post_id               uuid                                               not null
        constraint "users_take_quizzes_post_id_posts_fk"
            references posts
            on delete cascade,
    time_limit            integer,
    score                 integer,
    total_answers         integer,
    started_at            timestamp with time zone default CURRENT_TIMESTAMP not null,
    finished_at           timestamp with time zone,
    quiz_snapshot         jsonb,
    created_by            uuid                                               not null,
    updated_by            uuid,
    created_at            timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at            timestamp with time zone default CURRENT_TIMESTAMP not null,
    total_correct_answers integer,
    is_highest            boolean                  default false
);

create index if not exists users_take_quizzes_quiz_id
    on quiz_participants (quiz_id);

create index if not exists quiz_participants_post_id_created_by_created_at_is_highest_fini
    on quiz_participants (post_id, created_by, created_at, is_highest, finished_at);

create table if not exists quiz_questions
(
    id         uuid                     default gen_random_uuid() not null
        primary key,
    quiz_id    uuid                                               not null
        constraint "quiz_questions_quiz_id_quizzes_fk"
            references quizzes
            on delete cascade,
    content    varchar(256)                                       not null,
    created_at timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at timestamp with time zone default CURRENT_TIMESTAMP not null
);

create table if not exists quiz_answers
(
    id          uuid                     default gen_random_uuid() not null
        primary key,
    question_id uuid                                               not null
        constraint "quiz_answers_question_id_quiz_questions_fk"
            references quiz_questions
            on delete cascade,
    is_correct  boolean                                            not null,
    content     varchar(256)                                       not null,
    created_at  timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at  timestamp with time zone default CURRENT_TIMESTAMP not null
);

create table if not exists quiz_participant_answers
(
    id                  uuid                     default gen_random_uuid() not null
        constraint user_take_quiz_detail_pkey
            primary key,
    quiz_participant_id uuid                                               not null
        constraint "user_take_quiz_detail_user_take_quiz_id_users_take_"
            references quiz_participants
            on delete cascade,
    question_id         uuid                                               not null,
    answer_id           uuid                                               not null,
    created_at          timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at          timestamp with time zone default CURRENT_TIMESTAMP not null,
    is_correct          boolean                                            not null
);

create table if not exists reaction_comment_details
(
    id            uuid                     default gen_random_uuid() not null
        primary key,
    reaction_name varchar(256)                                       not null,
    comment_id    uuid                                               not null
        references comments
            on delete cascade,
    count         integer                                            not null,
    created_at    timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at    timestamp with time zone default CURRENT_TIMESTAMP not null
);

create unique index if not exists reaction_comment_details_comment_id_reaction_name
    on reaction_comment_details (comment_id, reaction_name);

create table if not exists reaction_content_details
(
    id            uuid                     default gen_random_uuid() not null
        primary key,
    reaction_name varchar(256)                                       not null,
    content_id    uuid                                               not null
        references posts
            on delete cascade,
    count         integer                                            not null,
    created_at    timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at    timestamp with time zone default CURRENT_TIMESTAMP not null
);

create unique index if not exists reaction_content_details_content_id_reaction_name
    on reaction_content_details (content_id, reaction_name);

create table if not exists reports
(
    id              uuid                            default gen_random_uuid()                          not null
        primary key,
    group_id        uuid                                                                               not null,
    report_to       enum_reports_report_to                                                 not null,
    target_id       uuid                                                                               not null,
    target_type     enum_reports_target_type                                               not null,
    target_actor_id uuid                                                                               not null,
    reasons_count   jsonb                                                                              not null,
    status          enum_reports_status default 'CREATED'::enum_reports_status not null,
    processed_by    uuid,
    processed_at    timestamp with time zone,
    created_at      timestamp with time zone        default CURRENT_TIMESTAMP                          not null,
    updated_at      timestamp with time zone        default CURRENT_TIMESTAMP,
    root_group_id   uuid,
    scope           enum_reports_scope
);

create table if not exists report_details
(
    id          uuid                     default gen_random_uuid() not null
        primary key,
    report_id   uuid                                               not null
        references reports
            on delete cascade,
    target_id   uuid                                               not null,
    reporter_id uuid                                               not null,
    reason_type varchar(60)                                        not null,
    reason      varchar(512),
    created_at  timestamp with time zone default CURRENT_TIMESTAMP not null,
    updated_at  timestamp with time zone default CURRENT_TIMESTAMP,
    target_type enum_report_details_target_type,
    scope       enum_reports_scope
);

create index if not exists report_details_target_id
    on report_details (target_id);

create index if not exists report_details_reporter_id
    on report_details (reporter_id);

create table if not exists comments_reactions
(
    reaction_name varchar(50)                                        not null,
    created_at    timestamp with time zone default CURRENT_TIMESTAMP not null,
    id            uuid                     default gen_random_uuid() not null
        constraint "comments_reactions_id_pk"
            primary key,
    comment_id    uuid                                               not null
        constraint "comments_reactions_comment_id_comments_fk"
            references comments
            on delete cascade,
    created_by    uuid,
    is_latest     boolean                  default false
);

create unique index if not exists comments_reactions_comment_id_created_by_reaction_name
    on comments_reactions (comment_id, created_by, reaction_name);

create table if not exists posts_reactions
(
    reaction_name varchar(50)                                        not null,
    created_at    timestamp with time zone default CURRENT_TIMESTAMP not null,
    id            uuid                     default gen_random_uuid() not null
        constraint "posts_reactions_id_pk"
            primary key,
    post_id       uuid                                               not null
        constraint "posts_reactions_post_id_posts_fk"
            references posts
            on delete cascade,
    created_by    uuid,
    is_latest     boolean                  default false
);

create unique index if not exists posts_reactions_post_id_reaction_name_created_by
    on posts_reactions (post_id, reaction_name, created_by);

create table if not exists quiz_stats
(
    quiz_id           uuid    not null
        primary key
        references quizzes
            on delete cascade,
    content_id        uuid    not null,
    pass_participants integer not null,
    fail_participants integer not null
);

create table if not exists daily_community_content_counts
(
    id            uuid                     default gen_random_uuid()           not null
        primary key,
    root_group_id uuid                                                         not null,
    content_type  enum_daily_community_content_counts_content_type not null,
    total_count   bigint                   default 0,
    collected_at  timestamp with time zone                                     not null,
    created_at    timestamp with time zone default CURRENT_TIMESTAMP           not null,
    updated_at    timestamp with time zone default CURRENT_TIMESTAMP           not null
);

create table if not exists daily_community_content_counts_clone
(
    id            uuid   default gen_random_uuid() not null,
    root_group_id uuid,
    total_count   bigint,
    collected_at  timestamp with time zone,
    created_at    timestamp with time zone,
    updated_at    timestamp with time zone,
    post_count    bigint default 0,
    article_count bigint default 0,
    series_count  bigint default 0
);

create table if not exists daily_group_content_counts_clone
(
    id            uuid   default gen_random_uuid() not null,
    group_id      uuid,
    total_count   bigint default 0,
    post_count    bigint default 0,
    article_count bigint default 0,
    series_count  bigint default 0,
    collected_at  timestamp with time zone,
    created_at    timestamp with time zone,
    updated_at    timestamp with time zone
);

create table if not exists hidden_contents
(
    content_id       uuid                                               not null
        primary key
        references posts
            on delete cascade,
    content_type     enum_hidden_contents_content_type      not null,
    content_actor_id uuid                                               not null,
    created_at       timestamp with time zone default CURRENT_TIMESTAMP not null
);

create table if not exists daily_content_interactions
(
    id                  uuid                                               not null
        primary key,
    content_id          uuid                                               not null
        references posts
            on delete cascade,
    num_of_unique_views integer                  default 0                 not null,
    num_of_views        integer                  default 0                 not null,
    num_of_comments     integer                  default 0                 not null,
    num_of_reactions    integer                  default 0                 not null,
    num_of_quizzes      integer                  default 0                 not null,
    points              numeric                  default 0                 not null,
    created_at          timestamp with time zone default CURRENT_TIMESTAMP not null
);


create table if not exists "SequelizeMeta"
(
    name varchar(255) not null
        primary key
);

insert into "SequelizeMeta" (name)
values  ('20211103045502-create_media_table.js'),
        ('20211103045503-create_post_table.js'),
        ('20211103045505-create_post_group_table.js'),
        ('20211103045505-create_post_media_table.js'),
        ('20211103045511-create_post_reaction_table.js'),
        ('20211125074139-create_comments_table.js'),
        ('20211125074140-create_comment_media_table.js'),
        ('20211125074140-create_comment_reaction_table.js'),
        ('20211125074140-create_user_newsfeed_table.js'),
        ('20211229090934-create_recent_searches_table.js'),
        ('20220314115635-create_mention_table.js'),
        ('20220324083858-create_follows_table.js'),
        ('20220324083859-create_user_marked_important_post_table.js'),
        ('20220426071342-create_post_edited_history_table.js'),
        ('20220427095013-create-comment-edited-history-table.js'),
        ('20220502074851-create_create_post_reaction_procedure.js'),
        ('20220502074858-create_create_comment_reaction_procedure.js'),
        ('20220505075150-create-user-seen-post-table.js'),
        ('20220509042219-add_edited_column_to_comment_table.js'),
        ('20220510081949-add_user_group_index_to_follow_table.js'),
        ('20220513042219-add_column_to_media_table.js'),
        ('20220513042220-add_column_to_post_table.js'),
        ('20220512115200-create-giphy-table.js'),
        ('20220512115536-add_giphy_id_column_to_post_table.js'),
        ('20220512115556-add_giphy_id_column_to_comment_table.js'),
        ('20220509031506-id-from-auto-increment-to-uuid.js'),
        ('20220513042222-remove_column_uploadId_media.js'),
        ('20220525092135-update_post_table.js'),
        ('20220525071614-create_series_table.js'),
        ('20220525082854-create_category_table.js'),
        ('20220530075704-create_hashtag_table.js'),
        ('20220531034046-create_posts_hashtags.js'),
        ('20220531034101-create_posts_series.js'),
        ('20220531034107-create_posts_categories.js'),
        ('20220602042219-add_post_privacy_table.js'),
        ('20220608095757-add_column_to_media_table.js'),
        ('20220610095208-add_total_users_seen_to_post_table.js'),
        ('20220620042725-recreate_post_reaction_procedure.js'),
        ('20220620043023-recreate_comment_reaction_procedure.js'),
        ('20220621090231-change_mime_type_in_media_table.js'),
        ('20220621094700-change_mime_type_in_media_table.js'),
        ('20220701042921-add_index_search_column_to_posts_table.js'),
        ('20220719162024-alter-tables-update-some-columns-to-uuid.js'),
        ('20220725145224-alter-tables-remove-temporary-columns.js'),
        ('20220729080114-add_deleted_at_to_post_table.js'),
        ('20220912072819-add-category-data.js'),
        ('20220912072820-update-category-data.js'),
        ('20220921081929-create_link_preview_table.js'),
        ('20220921082004-create_posts_link_preview_table.js'),
        ('20220923094839-change_url_in_link_preview_table.js'),
        ('20221001061745-change-id-to-uuid-recent-search.js'),
        ('20221001061755-change_image_column_in_link_preview_table.js'),
        ('20221001062755-add_cover_column_in_posts_table.js'),
        ('20230207070825-remove_column_is_draft_is_processing_is_article_from_post_table.js'),
        ('20230208042425-remove-user-newsfeed-id.js'),
        ('20230208042426-remove-change-primary-follow.js'),
        ('20221001062955-add_link_preview_id_column_in_posts_table.js'),
        ('20230208042429-remove-index-and-update-primary-key-user_seen_posts.js'),
        ('20230208042430-remove-index-user_save_posts.js'),
        ('20230208042431-remove-index-and-update-primary-key-user_mark_read_posts.js'),
        ('20221621090231-update_primary_key_in_media_comment_and_post_comment_table.js'),
        ('20221621090300-remove_is_draft_column_in_media_table.js'),
        ('20230208042432-update-tag-name-uppercase.js'),
        ('20221621090431-set_null_content_for_article.js'),
        ('20221728100415-add-type-to-post-table.js'),
        ('20221728200414-remove-series-table.js'),
        ('20230330101955-add-is-pinned-posts-groups-table.js'),
        ('20230323030051-remove-unused-column-in-post.js'),
        ('20221109042329-create-users-save-posts-table.js'),
        ('20221115085926-add-column-zindex-into-posts-series-table.js'),
        ('20230327102305-add-media-json-to-comments-table.js'),
        ('20230327102306-add-media-and-cover-json-to-posts-table.js'),
        ('20230327102307-add-mention-json-to-posts-table.js'),
        ('20230327102308-update-cascade-comments-media-table.js'),
        ('20230327102309-update-cascade-posts-cover-table.js'),
        ('20230327102309-update-cascade-posts-media-table.js'),
        ('20230327102310-create-old-id-for-media-table.js'),
        ('20230327102311-delete-cascade-comment-reactions-table.js'),
        ('20230327102312-delete-cascade-posts-categories-table.js'),
        ('20230327102313-delete-cascade-posts-groups-table.js'),
        ('20221205045958-sync-important-post-for-owner.js'),
        ('20221209095742-change-post-privacy-data-type.js'),
        ('20221209080018-create_tags_table.js'),
        ('20221209081648-create_posts_tags_table.js'),
        ('20221212081459-add_tags_json_to_post_table.js'),
        ('20221213083218-add_total_used_to_tags_table.js'),
        ('20221728215203-add-report-status-column-to-posts-table.js'),
        ('20221728215204-add-is-reported-to-post-group-table.js'),
        ('20221728200415-create-report-contents-table.js'),
        ('20221728200416-create-report-contents-detail-table.js'),
        ('20221728215207-alter-user-id-target-id-index-to-report-content-details-table.js'),
        ('20221728215206-drop-user-id-target-id-index-to-report-content-details-table.js'),
        ('20221219023420-create_failed_process_posts_table.js'),
        ('20221221021346-add-hidden-column-to-comment-table.js'),
        ('20221221030157-remove-report-column-in-post-group-table.js'),
        ('20221230072653-add-status-published_at-error_log-in-post-table.js'),
        ('20230106065237-add-is-archive-to-post-group.js'),
        ('20221728215204-remove-report-column-in-post-group-table.js'),
        ('20230327102314-delete-cascade-posts-reactions-table.js'),
        ('20230327102315-delete-cascade-posts-series-table.js'),
        ('20230327102316-delete-cascade-posts-tags-table.js'),
        ('20230327102317-delete-cascade-user-newsfeed-table.js'),
        ('20230327102318-delete-cascade-user-mark-read-table.js'),
        ('20230327102319-delete-cascade-user-save-post-table.js'),
        ('20230327102320-delete-cascade-user-seen-post-table.js'),
        ('20230410072205-add-video-processing-id-to-post-table.js'),
        ('20230413081425-add-old-content-in-posts-table.js'),
        ('20230421023419-add-cascade-delete-for-comments-table.js'),
        ('20230421023529-add-cascade-delete-for-posts-media-table.js'),
        ('20230514143037-add-mentions-column-to-posts-table.js'),
        ('20230514143226-add-mentions-column-to-comments-table.js'),
        ('20230523102033-add-work-count-to-posts.js'),
        ('20230626025446-create-quizzes-table.js'),
        ('20230626033741-add-quiz-id-column-into-posts-table.js'),
        ('20230706025927-add-gen-status-to-quizzes-table.js'),
        ('20230710041304-add_error_to_quizzes_table.js'),
        ('20230711064938-add-scheduled-at-column-to-posts-table.js'),
        ('20230724081135-add_limit_time_to_quizzes_table.js'),
        ('20230724081845-create_users_take_quizzes_table.js'),
        ('20230725073934-create-quiz-questions-table.js'),
        ('20230725073935-create-quiz-answers-table.js'),
        ('20230726081845-create_users_take_quizzes_table.js'),
        ('20230726081896-create_users_take_quiz_detail_table.js'),
        ('20230807063219-add-is-highest-to-quiz-participant.js'),
        ('20230809064648-add-created-at-into-quiz-question-table.js'),
        ('20230809064702-add-created-at-into-quiz-answer-table.js'),
        ('20230808034321-calculate-highest-score.js'),
        ('20230811085935-calculate-highest-score.js'),
        ('20230814040234-calculate-highest-score.js'),
        ('20230814111840-calculate-highest-score.js'),
        ('20230817081834-set-nullable-display-question-in-quizzes-table.js'),
        ('20230818040947-remove-number-of-answers-display-column-in-quizzes-table.js'),
        ('20231026034307-create_reaction_comment_details_table.js'),
        ('20231026034322-create_reaction_content_details_table.js'),
        ('20231122074202-add-is-hidden-to-post-group-table.js'),
        ('20231122084228-drop-unused-table.js'),
        ('20231127065329-create-table-report-and-report-detail-new-structure.js'),
        ('20231222110624-add-column-user-newsfeed-table.js'),
        ('20231222111100-add-index-newsfeed.js'),
        ('20240123083423-add_parentCommentsCount_to_post_table.js'),
        ('20240130025342-update-charactor-limit-link-preview-table.js'),
        ('20240131111558-add-is-latest-to-reaction.js'),
        ('20240229080346-add-publishedAt-to-quiz.js'),
        ('20240305031738-create-table-quiz-stats.js'),
        ('20240405074822-add-root_group_id-and-scope-to-reports-model.js'),
        ('20240411074844-update-report-details-table.js'),
        ('20240405081327-create-hidden_contents_table.js'),
        ('20240415022624-create-table-daily-content-interactions.js'),
        ('20240422021715-add-scope-to-report-detail-table.js'),
        ('20240423030831-update-default-value-for-is_hidden-in-posts_groups-table.js'),
        ('20240422030521-add-index-posts-table.js'),
        ('20240403032934-create-table-daily-group-content-counts.js'),
        ('20240409075137-create-table-daily-community-content-counts.js'),
        ('20240411173001-add-root-group-id-to-post-group-table.js'),
        ('20240503090004-add-scope-to-posts-table.js');

CREATE TABLE IF NOT EXISTS outbox (
    id uuid default gen_random_uuid() not null primary key, -- id event generated
    request_id uuid NOT NULL,
    aggregate_id VARCHAR(255) NOT NULL, -- key message
    aggregate_type VARCHAR(255) NOT NULL, -- topic name
    type VARCHAR(255) NOT NULL, -- event name (state, eg: created|published|deleted)
    payload jsonb,
    updated_at timestamp with time zone default CURRENT_TIMESTAMP,
    created_at timestamp with time zone default CURRENT_TIMESTAMP
);