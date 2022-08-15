/*
 * This function recursively clones the current children of the input to the output
*/

CREATE OR REPLACE PROCEDURE cs_update_children(
    level int,
    input int,
    output int,
    author text,
    year int
)
LANGUAGE plpgsql
AS $$
DECLARE
    c int;
    child_level int;
    f record;
BEGIN

    -- Check to see if there is a child level
    IF (SELECT COUNT(*) FROM taxonomy.rank WHERE parent = level) = 0
    THEN
        RETURN;
    END IF;

    -- There's a child level, so get it
    SELECT id FROM taxonomy.rank INTO child_level WHERE parent = level;

    -- Check to see if the inputs are all synonyms
    EXECUTE
        format('SELECT COUNT(*) FROM taxonomy.%I WHERE id = current AND id = ($1)', level)
        INTO c
        USING input
    ;

    -- If there's a current understanding, stop
    IF (c > 0) THEN
        RAISE EXCEPTION 'Inputs may not contain current understandings';
    END IF;

    -- Check that the output is current
    EXECUTE
        format('SELECT COUNT(*) FROM taxonomy.%I WHERE id != current AND id = ($1)', level)
        INTO c
        USING output
    ;

    -- If it's a synonym, stop
    IF (c > 0) THEN
        RAISE EXCEPTION 'Output may not be a synonym';
    END IF;

    -- For each child
    FOR f in EXECUTE 
        format('SELECT id FROM taxonomy.%I WHERE id = current AND parent = $1', child_level)
        USING input

    LOOP
        -- Create the new understanding under the new parent and return the id
        EXECUTE
        format('INSERT INTO taxonomy.%I (name, author year, parent) RETURNING id',child_level)
        USING f.name, f.author, f.year, f.parent
        INTO c;

        -- Now update try to update the children
        CALL cs_update_children(child_level, f.id, c, author, year);

    END LOOP;

END; $$