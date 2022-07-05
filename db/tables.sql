--
-- テーブル作成用SQLスクリプト
--
CREATE DATABASE study DEFAULT CHARACTER SET utf8;
USE study

-- 問題テーブル
CREATE TABLE questions (
    id          INT unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
    task        VARCHAR(6) UNIQUE,   -- 課題
    level       CHAR(1),             -- 難易度
    input_type  CHAR(1),             -- 入力区分（0:なし、1:パラメータ、2:ファイル）
    parameter   TEXT,                -- 入力パラメータ
    file_name   VARCHAR(128),        -- ファイル名
    file_data   TEXT,                -- ファイル内容
    outline     VARCHAR(256),        -- 概要
    question    TEXT,                -- 問題
    answer      TEXT,                -- 解答
    cr_user     VARCHAR(64),
    cr_date     DATETIME,
    up_user     VARCHAR(64),
    up_date     DATETIME,
    del_flag    CHAR(1)
);


-- 進捗データ
CREATE TABLE progresses (
    id          INT unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
    userid      VARCHAR(64),         -- ユーザID
    question_id INT unsigned,        -- 問題ID
    lang_id     TINYINT unsigned,    -- 言語ID
    code        MEDIUMTEXT,          -- ソースコード
    result      TEXT,                -- 実行結果
    status      TINYINT unsigned,    -- 状況(0:OK, 1:NG)
    submitted   TINYINT unsigned,    -- 提出フラグ(0:未提出, 1:提出済)
    cr_user     VARCHAR(64),
    cr_date     DATETIME,
    up_user     VARCHAR(64),
    up_date     DATETIME,
    del_flag    CHAR(1)
);


-- 先生マスタ
CREATE TABLE teachers (
    id          INT unsigned NOT NULL,
    lang_id     TINYINT unsigned,    -- 言語ID
    userid      VARCHAR(64),         -- ユーザID
    del_flag    CHAR(1)
);


-- 言語マスタ
CREATE TABLE languages (
    id          TINYINT unsigned NOT NULL,
    shot_name   VARCHAR(32),         -- 言語略称
    name        VARCHAR(64),         -- 言語名
    del_flag    CHAR(1)
);
