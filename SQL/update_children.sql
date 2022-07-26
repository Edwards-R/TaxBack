/*
 * This function recursively clones the current children of the input to the output
 * As of 20220815, this function is only aware of major levels
*/

CREATE OR REPLACE PROCEDURE cs_update_children(
    level int,
    input int,
    output int
)
LANGUAGE plpgsql
AS $$
DECLARE
    author text;
    year int;
    c int;
    level_name text;
    child_level record;
    f record;
BEGINfg

    -- Check to see if there is a child level
    IF (SELECT COUNT(*) FROM taxonomy.rank WHERE major_parent = level) = 0
    THEN
        RETURN;
    END IF;

    -- There's a child level, so get the name so we can find the tables
    SELECT r.id, r.name FROM taxonomy.rank r INTO child_level WHERE r.major_parent = level;

    -- Get the name of the level so we can find it in tables
    SELECT r.name FROM taxonomy.rank r INTO level_name WHERE r.id = level;

    -- Check to see if the input is not current
    EXECUTE
        format('SELECT COUNT(*) FROM taxonomy.%I WHERE id = current AND id = ($1)', level_name)
        INTO c
        USING input
    ;

    -- If there's a current understanding, stop
    IF (c > 0) THEN
        RAISE EXCEPTION 'Inputs may not contain current understandings';
    END IF;

    -- Check that the output is current
    EXECUTE
        format('SELECT COUNT(*) FROM taxonomy.%I WHERE id != current AND id = ($1)', level_name)
        INTO c
        USING output
    ;

    -- If it's a synonym, stop
    IF (c > 0) THEN
        RAISE EXCEPTION 'Output may not be a synonym';
    END IF;

    -- Get the author and year of the parent so that it propagates
    EXECUTE
        format('SELECT author, year FROM taxonomy.%I WHERE id = $1', level_name)
        INTO author, year
        USING output
    ;

    RAISE NOTICE '% %', author, year;

    -- For each child
    FOR f in SELECT * FROM cs_fetch_valid_children(level, input)

    LOOP
        -- Create the new understanding under the new parent and return the id
        EXECUTE
        format('INSERT INTO taxonomy.%I (name, author, year, parent) VALUES ($1, $2, $3, $4) RETURNING id',child_level.name)
        USING f.name, author, year, output
        INTO c;

        -- Update the old to direct to the new
        EXECUTE
        format('UPDATE taxonomy.%I SET current = $1 WHERE current = $2', child_level.name)
        USING c, f.id;

        -- Now update try to update the children
        CALL cs_update_children(child_level.id, f.id, c);

    END LOOP;

END; $$