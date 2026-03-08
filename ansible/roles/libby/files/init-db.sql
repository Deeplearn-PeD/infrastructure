-- Initialize pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create a test table to verify pgvector is working
CREATE TABLE IF NOT EXISTS vector_test (
    id serial PRIMARY KEY,
    embedding vector(3)
);

-- Clean up test table
DROP TABLE IF EXISTS vector_test;
