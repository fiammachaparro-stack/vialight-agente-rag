-- Vector Store de Vialight en Supabase (pgvector)
-- Embeddings: Google gemini-embedding-001 (3072 dimensiones)
create extension if not exists vector;

create table if not exists documents (
  id bigserial primary key,
  content text,
  metadata jsonb,
  embedding vector(3072)
);

alter table documents enable row level security;

-- Búsqueda por similitud usada por el nodo Supabase Vector Store de n8n
create or replace function match_documents (
  query_embedding vector(3072),
  match_count int default null,
  filter jsonb default '{}'
) returns table (id bigint, content text, metadata jsonb, similarity float)
language plpgsql as $$
#variable_conflict use_column
begin
  return query
  select id, content, metadata,
         1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;
