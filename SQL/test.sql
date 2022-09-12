DROP TYPE IF EXISTS test_item CASCADE;

CREATE TYPE test_item AS (
    name TEXT,
    num INT
);

create or replace function sc_repeat(
    data test_item[]
)
returns INT
LANGUAGE plpgsql
AS $$
DECLARE

BEGIN
    raise notice 'zoids!';
    return data.num;
END;
$$;