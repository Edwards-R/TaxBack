/* 
 * A short function that determines what a valid child is, and will fetch all valid children from a given parent and level
 *
 * A valid child is the following:
 *      Current i.e. id == current
 *      Non - aggregate i.e. has one and only one component
 *          Note that this does not use '%agg' search strings. They *shouldn't* be a problem, but it is not guaranteed
*/

CREATE OR REPLACE FUNCTION cs_fetch_valid_children(
    level_id INT,
    parent INT
)
RETURNS TABLE (
    id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    child_level RECORD;
BEGIN
    -- Get the level that has the direct parent of the given parent
    SELECT * FROM taxonomy.rank INTO child_level WHERE direct_parent = level_id;

    -- Return the ids of the valid children
    RETURN QUERY EXECUTE format(
        'SELECT x.id FROM (
            SELECT t.id, count(c.*) 
            FROM taxonomy.%I t 
            JOIN taxonomy.%I_composition c ON t.id = c.subject 
            WHERE t.id=t.current 
            AND t.parent = $1
            GROUP BY t.id
        ) as x
        WHERE count = 1',
        child_level.name,
        child_level.name
    )
    USING parent
    ;
END; $$