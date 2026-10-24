-- =====================================================================
-- REMEDIAL UTS BASIS DATA
-- Nama  : Keylila Edenia Vinca Susanto
-- NPM   : 264311045
-- Kelas : 1B - D4 Teknologi Rekayasa Perangkat Lunak
-- Kasus : Portal Berita (CMS) 
--
-- PENAMBAHAN PROSES BISNIS:
--   Redaksi ingin melihat performa tiap artikel setiap hari:
--   berapa kali dibuka, berapa pembaca, dan berapa yang berlangganan
--   (konversi). Untuk itu ditambah SATU tabel: statistik_artikel_harian
-- =====================================================================


-- =====================================================================
-- 1. PEMODELAN KONSEPTUAL
-- =====================================================================

-- Aturan bisnis:
--   1. Satu artikel punya banyak statistik, satu per tanggal (1 : N).
--   2. Statistik tidak ada tanpa artikelnya -> ENTITAS LEMAH.
--      Kuncinya gabungan: article_id + tanggal.
--   3. Artikel dihapus -> statistiknya ikut terhapus.
--   4. Pembaca unik tidak boleh lebih dari tayang, dan konversi tidak
--      boleh lebih dari pembaca unik.
--
-- Entitas baru:
--   STATISTIK_ARTIKEL_HARIAN (article_id, tanggal, jumlah_tayang,
--                             jumlah_pembaca_unik, jumlah_konversi)
--
-- ERD (teks):
--   KATEGORI (1) --- memiliki --- (N) ARTIKEL
--   ARTIKEL  (N) --- ditulis  --- (M) USERS   (lewat ARTIKEL_PENULIS)
--   ARTIKEL  (N) --- diberi   --- (M) TAG     (lewat ARTIKEL_TAG)
--   ARTIKEL  (1) --- memiliki --- (N) STATISTIK_ARTIKEL_HARIAN  [BARU]


-- =====================================================================
-- 2. PEMODELAN LOGIS
-- =====================================================================

-- Skema relasional tabel baru:
--   STATISTIK_ARTIKEL_HARIAN (PK/FK article_id, PK tanggal,
--                             jumlah_tayang, jumlah_pembaca_unik,
--                             jumlah_konversi)
--
-- Normalisasi:
--
--   UNF : satu baris artikel berisi banyak data harian sekaligus.
--     id | judul        | kategori | harian
--     1  | Harga Cabai  | Ekonomi  | (1 Okt: 320 tayang), (2 Okt: 410 tayang)
--
--   1NF : satu baris = satu artikel di satu tanggal. Kunci (id, tanggal).
--     id | tanggal | judul       | kategori | tayang
--     1  | 1 Okt   | Harga Cabai | Ekonomi  | 320
--     1  | 2 Okt   | Harga Cabai | Ekonomi  | 410
--
--   2NF : judul dan kategori hanya bergantung pada id artikel
--         (sebagian kunci), jadi dipindah ke tabel ARTIKEL.
--     STATISTIK (id, tanggal, tayang, pembaca_unik, konversi)
--
--   3NF : nama kategori bergantung pada id_kategori, jadi dipindah
--         ke tabel KATEGORI. Tingkat konversi tidak disimpan karena
--         bisa dihitung (konversi / pembaca unik).


-- =====================================================================
-- 3. PEMODELAN FISIK (SQL DDL)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS portal_berita;
USE portal_berita;

-- ---------------------------------------------------------------------
-- 3.1 Tabel kelompok 
-- ---------------------------------------------------------------------

CREATE TABLE users (
  user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name    VARCHAR(100) NOT NULL,
  email   VARCHAR(150) NOT NULL UNIQUE,
  role    VARCHAR(50)  NOT NULL DEFAULT 'penulis'
) ENGINE=InnoDB;

CREATE TABLE kategori (
  category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE tag (
  tag_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name   VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE artikel (
  article_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id  INT UNSIGNED NOT NULL,
  title        VARCHAR(255) NOT NULL,
  published_at DATETIME NULL,
  status       ENUM('draft','published','archived') NOT NULL DEFAULT 'draft',
  CONSTRAINT fk_artikel_kategori FOREIGN KEY (category_id)
    REFERENCES kategori(category_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE artikel_penulis (
  article_id    INT UNSIGNED NOT NULL,
  user_id       INT UNSIGNED NOT NULL,
  peran_penulis VARCHAR(50)  NOT NULL,
  PRIMARY KEY (article_id, user_id),
  CONSTRAINT fk_artikel_penulis_artikel FOREIGN KEY (article_id)
    REFERENCES artikel(article_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_artikel_penulis_users FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE artikel_tag (
  article_id INT UNSIGNED NOT NULL,
  tag_id     INT UNSIGNED NOT NULL,
  PRIMARY KEY (article_id, tag_id),
  CONSTRAINT fk_artikel_tag_artikel FOREIGN KEY (article_id)
    REFERENCES artikel(article_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_artikel_tag_tag FOREIGN KEY (tag_id)
    REFERENCES tag(tag_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3.2 TABEL TAMBAHAN (BARU)
-- ---------------------------------------------------------------------

CREATE TABLE statistik_artikel_harian (
  article_id          INT UNSIGNED NOT NULL,
  tanggal             DATE         NOT NULL,
  jumlah_tayang       INT UNSIGNED NOT NULL DEFAULT 0,
  jumlah_pembaca_unik INT UNSIGNED NOT NULL DEFAULT 0,
  jumlah_konversi     INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (article_id, tanggal),
  CONSTRAINT chk_pembaca_unik CHECK (jumlah_pembaca_unik <= jumlah_tayang),
  CONSTRAINT chk_konversi     CHECK (jumlah_konversi <= jumlah_pembaca_unik),
  CONSTRAINT fk_statistik_artikel FOREIGN KEY (article_id)
    REFERENCES artikel(article_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_statistik_tanggal ON statistik_artikel_harian(tanggal);

-- ---------------------------------------------------------------------
-- 3.3 Data contoh 
-- ---------------------------------------------------------------------

INSERT INTO users (user_id, name, email, role) VALUES
  (1, 'Jadid', 'justdid@gmail.com',    'editor'),
  (2, 'Fatir', 'patirstuvw@gmail.com', 'penulis'),
  (3, 'Heksa', 'hexaa@gmail.com',      'penulis');

INSERT INTO kategori (category_id, name) VALUES
  (1, 'Ekonomi'), (2, 'Pemerintahan'), (3, 'Layanan Publik');

INSERT INTO artikel (article_id, category_id, title, published_at, status) VALUES
  (1, 1, 'Harga Cabai Naik Jelang Akhir Pekan', '2026-10-01 08:00:00', 'published'),
  (2, 2, 'Pemkot Resmikan Taman Kota Baru',     '2026-10-02 09:00:00', 'published'),
  (3, 3, 'Jadwal Pemadaman Listrik Pekan Ini',  NULL,                  'draft'),
  (4, 1, 'UMKM Madiun Ikuti Pameran Daerah',    '2026-10-04 10:00:00', 'published');

INSERT INTO artikel_penulis (article_id, user_id, peran_penulis) VALUES
  (1, 2, 'Reporter'), (1, 1, 'Editor'),
  (2, 3, 'Reporter'), (2, 1, 'Editor'),
  (3, 2, 'Reporter'), (3, 1, 'Editor'),
  (4, 3, 'Reporter');

INSERT INTO statistik_artikel_harian
  (article_id, tanggal, jumlah_tayang, jumlah_pembaca_unik, jumlah_konversi) VALUES
  (1, '2026-10-01', 320, 250, 20),
  (1, '2026-10-02', 410, 300, 33),
  (2, '2026-10-02', 200, 160,  8);

-- Tingkat konversi dihitung lewat query
SELECT a.title,
       SUM(s.jumlah_tayang) AS total_tayang,
       ROUND(SUM(s.jumlah_konversi) / SUM(s.jumlah_pembaca_unik) * 100, 2)
         AS tingkat_konversi_persen
FROM statistik_artikel_harian s
JOIN artikel a ON a.article_id = s.article_id
GROUP BY a.article_id, a.title;

-- ---------------------------------------------------------------------
-- 3.4 Index dan EXPLAIN 
-- ---------------------------------------------------------------------

EXPLAIN SELECT * FROM artikel WHERE status = 'published';  -- sebelum index

CREATE INDEX idx_artikel_title  ON artikel(title);
CREATE INDEX idx_artikel_status ON artikel(status);

EXPLAIN SELECT * FROM artikel WHERE status = 'published';  -- sesudah index

-- ---------------------------------------------------------------------
-- 3.5 Tabel rekapitulasi 
-- ---------------------------------------------------------------------

CREATE TABLE rekap_produktivitas_penulis (
  user_id                 INT UNSIGNED PRIMARY KEY,
  nama_penulis            VARCHAR(100) NOT NULL,
  total_artikel_published INT UNSIGNED DEFAULT 0,
  CONSTRAINT fk_rekap_user FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT INTO rekap_produktivitas_penulis (user_id, nama_penulis, total_artikel_published)
VALUES (1, 'Jadid', 1)
ON DUPLICATE KEY UPDATE total_artikel_published = total_artikel_published + 1;

SELECT user_id, nama_penulis, total_artikel_published
FROM rekap_produktivitas_penulis;
