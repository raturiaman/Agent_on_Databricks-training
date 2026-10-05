-- Lab 3A — chunk the policy documents for retrieval.
-- Sentence-aware, grouped 3 sentences per chunk, metadata carried through so
-- Vector Search can filter on it.

CREATE OR REPLACE TABLE agents_labs.retail.support_chunks AS
WITH sentences AS (
  SELECT doc_id, title, category, audience, pos, sentence
  FROM agents_labs.retail.support_docs
  LATERAL VIEW posexplode(split(body, '(?<=\\.)\\s+')) t AS pos, sentence
),
grouped AS (
  SELECT doc_id, title, category, audience,
         CAST(pos / 3 AS INT) AS grp,
         collect_list(struct(pos, sentence)) AS parts
  FROM sentences
  WHERE length(trim(sentence)) > 0
  GROUP BY doc_id, title, category, audience, CAST(pos / 3 AS INT)
)
SELECT
  concat(doc_id, '-C', lpad(cast(grp AS STRING), 2, '0')) AS chunk_id,
  doc_id, title, category, audience,
  concat_ws(' ', transform(array_sort(parts, (l, r) -> CASE WHEN l.pos < r.pos THEN -1
                                                            WHEN l.pos > r.pos THEN 1 ELSE 0 END),
                           x -> x.sentence)) AS chunk
FROM grouped;

ALTER TABLE agents_labs.retail.support_chunks
  SET TBLPROPERTIES (delta.enableChangeDataFeed = true);

ALTER TABLE agents_labs.retail.support_chunks
  ALTER COLUMN chunk_id SET NOT NULL;

ALTER TABLE agents_labs.retail.support_chunks
  ADD CONSTRAINT support_chunks_pk PRIMARY KEY (chunk_id);

SELECT doc_id, count(*) AS chunks, round(avg(length(chunk))) AS avg_chars
FROM agents_labs.retail.support_chunks GROUP BY doc_id ORDER BY doc_id;
