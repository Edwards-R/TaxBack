/*
 * A test suite for the cs_update_children function
*/

-- Test to see if it rejects inputs with different parents
SELECT array_agg(id) FROM (
	SELECT max(g.id) as id
	FROM taxonomy.genus g
	WHERE id = current
	GROUP BY g.parent
	ORDER BY RANDOM()
	LIMIT 2
) as r