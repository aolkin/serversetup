CREATE DATABASE ##user##;
CREATE USER ##user##;
ALTER ROLE ##user## SET client_encoding TO 'utf8';
ALTER ROLE ##user## SET default_transaction_isolation TO 'read committed';
ALTER ROLE ##user## SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE ##user## TO ##user##;
