/*
 * Checks to see the following:
 *      Each given child is unique
 *      Each given child belongs to the given parent
 *      Every transferrable child of the given parent is present in the given children
*/

CREATE OR REPLACE FUNCTION cs_split_child_check(
    level_id INT,
    source INT,
    destinations split_item ARRAY
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variables
    level RECORD;
    child_level RECORD;

    source_array INT ARRAY;
    output_array INT ARRAY;
    destination_array INT ARRAY;

    c INT;
    _destination split_item;
BEGIN
    -- Fetch the rank level details
    SELECT * FROM taxonomy.rank INTO level WHERE id = level_id;

    -- Fetch the child rank level detailsz\
    SELECT * FROM taxonomy.rank INTO child_level WHERE major_parent = level_id;

    -- Fetch the number of destinations which appear more than once
    EXECUTE
    format('
        SELECT count(cnt) from (
            SELECT COUNT(*) cnt FROM (
                SELECT 
                unnest((y.x).children) as destination
                FROM (
                    SELECT UNNEST(
                        $1::split_item[]
                    )
                    as x
                ) as y
            ) as z
            GROUP BY destination
        ) as a
        WHERE cnt > 1
    ')
    INTO c
    USING destinations;
    
    -- Check if all provided destinations are valid children of the source
END;
$$;