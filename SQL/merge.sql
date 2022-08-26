-- The development of the function to merge understandings to a new one
-- The function is designed to be level-agnostic. If entering a level name is too problematic then
-- create sub-functions that call this one with prepared level prefixes e.g. CS_Merge_Species
-- This is ugly though and I don't like it.

-- Example call: CALL cs_merge(5, ARRAY[1,2,3], 'junk', 'junker', 2022,7)
CREATE OR REPLACE PROCEDURE cs_merge(
	level_id int,
	inputs int ARRAY,
	name text,
	author text,
	year int,
	parent int
)
LANGUAGE plpgsql
AS $$
DECLARE
	level text;
	c int;
BEGIN

-- Start by fetching the name of the rank
SELECT r.name FROM taxonomy.rank r INTO level WHERE r.id = level_id;

-- Check that the inputs have the same parent
EXECUTE
	format('SELECT COUNT(distinct(parent)) FROM taxonomy.%I WHERE id = ANY ($1)', level)
	into c
	USING inputs
;

IF (c !=1) THEN
	RAISE EXCEPTION 'Inputs must belong to the same parent taxon';
END IF;

-- Level exists, now check that all inputs are current and not synonyms
EXECUTE
	format('SELECT COUNT(*) FROM taxonomy.%I WHERE id != current AND id = ANY ($1)', level)
	INTO c
	USING inputs
;

-- If there's a synonym, stop
IF (c > 0) THEN
	RAISE EXCEPTION 'Inputs may not contain synonyms';
END IF;

-- Pre-checks completed, make the new entity
EXECUTE
	format('INSERT INTO taxonomy.%I (name, author,  year, parent) VALUES ($1, $2, $3, $4) RETURNING id', level)
	INTO c
	using name, author, year, parent
;

-- Update the old to redirect to the new
EXECUTE
	format('UPDATE taxonomy.%I SET current = $1 WHERE id = ANY ($2)', level)
	USING c, inputs
;

-- Push the current children of the inputs into the new taxa

-- FILL THIS IN --

-- Stuff goes here
END; $$