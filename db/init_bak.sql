-- ============================================
-- 0) 데이터베이스 생성 (이미 있으면 건너뜀)
-- ============================================
\set ON_ERROR_STOP on

-- catalog DB가 없으면 생성
SELECT 'CREATE DATABASE catalog'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'catalog')
\gexec

-- search DB가 없으면 생성
SELECT 'CREATE DATABASE search'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'search')
\gexec

-- catalog DB로 접속
\connect catalog;

-- ============================================
-- 1) 확장(Extensions)
--    - FTS(Full-Text Search) 품질 & 부분일치 가속
-- ============================================
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 1-1) IMMUTABLE 래퍼 (unaccent(text)는 STABLE → 생성컬럼 불가)
CREATE OR REPLACE FUNCTION immutable_unaccent(text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$ SELECT public.unaccent('unaccent', $1) $$;

-- ============================================
-- 2) book 테이블 (엔티티 기반 + 검색 최적화)
--    필드: isbn, title, subtitle, author, publisher, published_date, image_url
--    + Generated tsvector 컬럼(search_tsv)로 FTS 수행
-- ============================================
CREATE TABLE IF NOT EXISTS book (
    id              BIGSERIAL PRIMARY KEY,
    isbn            VARCHAR(20)  NOT NULL UNIQUE,
    title           VARCHAR(255) NOT NULL,
    subtitle        VARCHAR(255),
    author          VARCHAR(255),
    publisher       VARCHAR(255),
    published_date  DATE,
    image_url       TEXT,

    -- Full-Text Search용 생성 컬럼 (언제나 최신 값 유지)
    search_tsv      tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', immutable_unaccent(coalesce(title,    ''))), 'A') ||
        setweight(to_tsvector('simple', immutable_unaccent(coalesce(subtitle, ''))), 'B') ||
        setweight(to_tsvector('simple', immutable_unaccent(coalesce(author,   ''))), 'B') ||
        setweight(to_tsvector('simple', immutable_unaccent(coalesce(publisher,''))), 'C') ||
        setweight(to_tsvector('simple', immutable_unaccent(coalesce(isbn,     ''))), 'D')
    ) STORED
);

-- ============================================
-- 3) 인덱스
-- ============================================
-- ISBN 고유 인덱스(UNIQUE 제약으로 존재하지만 명시적으로 선언)
CREATE UNIQUE INDEX IF NOT EXISTS uk_book_isbn ON book(isbn);

-- 최신순 페이징 최적화 (정렬 인덱스)
CREATE INDEX IF NOT EXISTS idx_book_published_date ON book (published_date DESC, id);

-- FTS 주 인덱스 (GIN on tsvector)
CREATE INDEX IF NOT EXISTS idx_book_search_tsv ON book USING GIN (search_tsv);

-- 부분일치/오타 보정용 Trigram 인덱스 (선택적, 필요 시 사용)
CREATE INDEX IF NOT EXISTS idx_book_title_trgm      ON book USING GIN (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_book_subtitle_trgm   ON book USING GIN (subtitle gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_book_author_trgm     ON book USING GIN (author gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_book_publisher_trgm  ON book USING GIN (publisher gin_trgm_ops);

-- search DB로 접속
\connect search;

-- ============================================
-- 4) 인기 검색어 집계 테이블 (Top10 등)
-- ============================================
CREATE TABLE IF NOT EXISTS search_keyword (
    keyword        VARCHAR(200) PRIMARY KEY,
    cnt            BIGINT NOT NULL DEFAULT 0,
    last_searched  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_search_keyword_cnt
    ON search_keyword (cnt DESC, last_searched DESC);

-- ============================================
-- 5) 샘플 데이터 (선택) - 필요 시 주석 해제
-- ============================================
-- INSERT INTO book (isbn, title, subtitle, author, publisher, published_date, image_url)
-- VALUES
-- ('9781617291609','MongoDB in Action, 2nd Edition','Covers MongoDB version 3.0','Kyle Banker','Manning','2016-03-01','https://itbook.store/img/books/9781617291609.png');
