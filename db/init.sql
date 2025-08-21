\set ON_ERROR_STOP on

-- catalog DB가 없으면 생성
SELECT 'CREATE DATABASE catalog'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'catalog');
\gexec

-- search DB가 없으면 생성
SELECT 'CREATE DATABASE search'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'search');
\gexec

-- auth DB가 없으면 생성
SELECT 'CREATE DATABASE auth'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'auth');
\gexec

-- catalog DB로 접속
\connect catalog;

-- ============================================
-- book 테이블 (데이터 원본 역할)
--   - 검색 관련 컬럼 및 로직 제거
-- ============================================
CREATE TABLE IF NOT EXISTS book (
    id              BIGSERIAL PRIMARY KEY,
    isbn            VARCHAR(20)  NOT NULL UNIQUE,
    title           VARCHAR(255) NOT NULL,
    subtitle        VARCHAR(255),
    author          VARCHAR(255),
    publisher       VARCHAR(255),
    published_date  DATE,
    image_url       TEXT
);

-- ============================================
-- 인덱스 (기본 조회 및 정렬용)
-- ============================================
-- ISBN 고유 인덱스
CREATE UNIQUE INDEX IF NOT EXISTS uk_book_isbn ON book(isbn);

-- 최신순 페이징 최적화
CREATE INDEX IF NOT EXISTS idx_book_published_date ON book (published_date DESC, id);

-- search DB로 접속
\connect search;

-- ============================================
-- 인기 검색어 집계 테이블 (기능 유지를 위해 존속)
-- ============================================
CREATE TABLE IF NOT EXISTS search_keyword (
    keyword        VARCHAR(200) PRIMARY KEY,
    cnt            BIGINT NOT NULL DEFAULT 0,
    last_searched  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_search_keyword_cnt
    ON search_keyword (cnt DESC, last_searched DESC);


-- auth DB로 접속
\connect auth;

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(200) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'ROLE_USER'
);
