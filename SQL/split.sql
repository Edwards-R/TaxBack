DROP TYPE IF EXISTS split_item CASCADE;

CREATE TYPE split_item AS (
    name TEXT,
    children int ARRAY
);

CREATE OR REPLACE PROCEDURE cs_split(
    level_id INT,
    source INT,
    author TEXT,
    year INT,
    destinations split_item ARRAY
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variables
    level record;
    child_level record;
    subject record;
    c int;
BEGIN
    -- Code
    -- Get the level details
    SELECT * FROM taxonomy.rank INTO level WHERE id = level_id;

    -- Check if the input is non-synonym
    -- We can save some time here by just grabbing everything - we'll need it later anyway
    EXECUTE
        format('SELECT * FROM taxonomy.%I WHERE id = $1', level.name)
        INTO subject
        USING source
    ;

    -- If synonym, fail
    IF (subject.id != subject.current) THEN
        RAISE EXCEPTION 'Input must be current and not a synonym';
    END IF;

    -- Check that there are > 1 destinations ie the split actually splits
    IF (ARRAY_LENGTH(destinations) < 2) THEN
        RAISE EXCEPTION 'There must be multiple destination outputs';
    END IF;

    -- We already grabbed the details of the subject so create the aggregate

    -- Because of memory management stuff we have to modify the name to '+agg' first
    subject.name = subject.name + ' agg';

    EXECUTE
        format('INSERT INTO taxonomy.%I (name, author, year, parent) VALUES ($1, $2, $3, $4)', level.name)
        USING subject.name, author, year, subject.parent;
END; $$