-- The development of the function to merge understandings to a new one
-- The function is designed to be level-agnostic. If entering a level name is too problematic then
-- create sub-functions that call this one with prepared level prefixes e.g. CS_Merge_Species
-- This is ugly though and I don't like it.

-- Example call: CALL CS_MERGE('species', ARRAY[1,2,3], 'junk', 'junker', 2022)
CREATE OR REPLACE PROCEDURE CS_Merge(
	level text,
	inputs int[],
	name text,
	author text,
	year int
)
LANGUAGE plpgsql
AS $$
DECLARE
	table_name text;
BEGIN
-- Start by checking if the level exists
IF ((SELECT COUNT(*) FROM taxonomy.rank WHERE rank.name = level) !=1) THEN
    RAISE EXCEPTION 'Rank not found';
END IF;

-- Fill in table_name with the quoted and schema-prefixed version
table_name = 'taxonomy.' || level;

-- Level exists, now check that all inputs are current and not synonyms
IF (EXECUTE 'SELECT COUNT(*) FROM ' || table_name || ' WHERE id != current' >0) THEN
	RAISE EXCEPTION 'Merges cannot contain synonym inputs';
END IF;

-- Stuff goes here
END; $$