-- Need to start with a command to create a 'testing' taxonomic branch since none will exist to test this on
-- This is all new and previously untracked so start from scratch

CREATE OR REPLACE PROCEDURE cst_update_children(
    seed_name text,
    seed_author text,
    seed_year int
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variables
    -- If we store the top level domain we can just link everything up under that
    top int;
    tablename text;
    c int;
    parent_understanding int;
BEGIN
    -- Logic

    -- Due to the capstone there's a tiny bit of lead-in work to do before looping takes care of it

    -- Find the capstone
    SELECT id FROM taxonomy.rank INTO parent_understanding WHERE id = major_parent;

    -- Find the next rank
    SELECT name FROM taxonomy.rank into tablename WHERE id !=parent_understanding AND major_parent = parent_understanding;

    -- Create an entry into this rank
    EXECUTE format(
        'INSERT INTO taxonomy.%I (name, author, year, parent) VALUES($1, $2, $3, $4) RETURNING id',
        tablename
    )
    INTO c
    USING seed_name, seed_author, seed_year, parent_understanding;

END;
$$























-- Test to check for fail on trying to change the children of a current
-- Should fail with 'input cannot be current'
SELECT id FROM taxonomy.rank where name = 'genus';
SELECT id FROM taxonomy.genus WHERE id = current ORDER BY RANDOM() LIMIT 1;
SELECT id FROM taxonomy.genus WHERE id = current ORDER BY RANDOM() LIMIT 1;

CALL cs_update_children(
    4,
    54,
    17,
    'tester',
    2022
);


-- Test to check for fail on synonym output
-- Should fail with 'Output may not be a synonym'

-- THIS WILL NOT WORK ON SPECIES! You might need to add a synonym genus

SELECT id FROM taxonomy.rank where name = 'genus';
SELECT id FROM taxonomy.genus WHERE id != current ORDER BY RANDOM() LIMIT 1;
SELECT id FROM taxonomy.genus WHERE id != current ORDER BY RANDOM() LIMIT 1;

CALL cs_update_children(
    4,
    168,
    168,
    'tester',
    2022
);


