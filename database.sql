DROP SCHEMA IF EXISTS taxonomy CASCADE;

CREATE SCHEMA taxonomy;

-- Create the ranks table and populate it

CREATE TABLE taxonomy.rank (
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name TEXT NOT NULL,
	major_parent INT NOT NULL,
	direct_parent INT NOT NULL,
	display_name TEXT NOT NULL,
	CONSTRAINT major_parent FOREIGN KEY(major_parent) REFERENCES taxonomy.rank(id) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT direct_parent FOREIGN KEY(direct_parent) REFERENCES taxonomy.rank(id) DEFERRABLE INITIALLY DEFERRED
);

insert into taxonomy.rank (name, major_parent, direct_parent, display_name)
VALUES (
	'capstone',
	1,
	1, 
	'Capstone'
),(
	'superfamily',
	1,
	1,
	'Superfamily'
)
,(
	'family',
	2,
	2,
	'Family'
)
,(
	'genus',
	3,
	3,
	'Genus'
)
,(
	'species',
	4,
	4,
	'Species'
);

-- Create the rank tables

CREATE TABLE taxonomy.capstone(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name TEXT NOT NULL,
	author TEXT NOT NULL,
	year INT NOT NULL,
	parent INT NOT NULL,
	current INT NOT NULL,
	CONSTRAINT parent FOREIGN KEY(parent) REFERENCES taxonomy.capstone(id),
	CONSTRAINT current FOREIGN KEY(current) REFERENCES taxonomy.capstone(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.superfamily(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name TEXT NOT NULL,
	author TEXT NOT NULL,
	year INT NOT NULL,
	parent INT NOT NULL,
	current INT NOT NULL,
	CONSTRAINT parent FOREIGN KEY(parent) REFERENCES taxonomy.capstone(id),
	CONSTRAINT current FOREIGN KEY(current) REFERENCES taxonomy.superfamily(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.family(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name TEXT NOT NULL,
	author TEXT NOT NULL,
	year INT NOT NULL,
	parent INT NOT NULL,
	current INT NOT NULL,
	CONSTRAINT parent FOREIGN KEY(parent) REFERENCES taxonomy.superfamily(id),
	CONSTRAINT current FOREIGN KEY(current) REFERENCES taxonomy.family(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.genus(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name TEXT NOT NULL,
	author TEXT NOT NULL,
	year INT NOT NULL,
	parent INT NOT NULL,
	current INT NOT NULL,
	CONSTRAINT parent FOREIGN KEY(parent) REFERENCES taxonomy.family(id),
	CONSTRAINT current FOREIGN KEY(current) REFERENCES taxonomy.genus(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.species(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name TEXT NOT NULL,
	author TEXT NOT NULL,
	year INT NOT NULL,
	parent INT NOT NULL,
	current INT NOT NULL,
	CONSTRAINT parent FOREIGN KEY(parent) REFERENCES taxonomy.genus(id),
	CONSTRAINT current FOREIGN KEY(current) REFERENCES taxonomy.species(id) DEFERRABLE INITIALLY DEFERRED
);


-- Create the <rank>_type tables
-- Deliberately does not have a constraint on the pseudo-external type table
-- Deferrable due to desire to make everything in one transaction

CREATE TABLE taxonomy.capstone_rank(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	capstone int NOT NULL,
	type int NOT NULL,
	CONSTRAINT capstone FOREIGN KEY(capstone) REFERENCES taxonomy.capstone(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.superfamily_rank(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	superfamily int NOT NULL,
	type int NOT NULL,
	CONSTRAINT superfamily FOREIGN KEY(superfamily) REFERENCES taxonomy.superfamily(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.family_rank(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	family int NOT NULL,
	type int NOT NULL,
	CONSTRAINT family FOREIGN KEY(family) REFERENCES taxonomy.family(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.genus_rank(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	genus int NOT NULL,
	type int NOT NULL,
	CONSTRAINT genus FOREIGN KEY(genus) REFERENCES taxonomy.genus(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.species_rank(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	species int NOT NULL,
	type int NOT NULL,
	CONSTRAINT species FOREIGN KEY(species) REFERENCES taxonomy.species(id) DEFERRABLE INITIALLY DEFERRED
);


-- Constuct the <rank>_composition tables

CREATE TABLE taxonomy.capstone_composition(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	subject INT NOT NULL,
	component INT NOT NULL,
	CONSTRAINT subject FOREIGN KEY(subject) REFERENCES taxonomy.capstone(id) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT component FOREIGN KEY(component) REFERENCES taxonomy.capstone(id) DEFERRABLE INITIALLY DEFERRED
);


CREATE TABLE taxonomy.superfamily_composition(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	subject INT NOT NULL,
	component INT NOT NULL,
	CONSTRAINT subject FOREIGN KEY(subject) REFERENCES taxonomy.superfamily(id) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT component FOREIGN KEY(component) REFERENCES taxonomy.superfamily(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.family_composition(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	subject INT NOT NULL,
	component INT NOT NULL,
	CONSTRAINT subject FOREIGN KEY(subject) REFERENCES taxonomy.family(id) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT component FOREIGN KEY(component) REFERENCES taxonomy.family(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.genus_composition(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	subject INT NOT NULL,
	component INT NOT NULL,
	CONSTRAINT subject FOREIGN KEY(subject) REFERENCES taxonomy.genus(id) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT component FOREIGN KEY(component) REFERENCES taxonomy.genus(id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE taxonomy.species_composition(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	subject INT NOT NULL,
	component INT NOT NULL,
	CONSTRAINT subject FOREIGN KEY(subject) REFERENCES taxonomy.species(id) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT component FOREIGN KEY(component) REFERENCES taxonomy.species(id) DEFERRABLE INITIALLY DEFERRED
);

-- Add the self-reference enabling trigger function

CREATE OR REPLACE FUNCTION insert_understanding() RETURNS TRIGGER AS $insert_understanding$
	BEGIN
		IF NEW.current IS NULL THEN
			NEW.current = NEW.id;
		END IF;
		RETURN NEW;
END
$insert_understanding$ LANGUAGE plpgsql;

-- Assign trigger to tables

CREATE TRIGGER insert_understanding BEFORE INSERT ON taxonomy.capstone
FOR EACH ROW EXECUTE FUNCTION insert_understanding();

CREATE TRIGGER insert_understanding BEFORE INSERT ON taxonomy.superfamily
FOR EACH ROW EXECUTE FUNCTION insert_understanding();

CREATE TRIGGER insert_understanding BEFORE INSERT ON taxonomy.family
FOR EACH ROW EXECUTE FUNCTION insert_understanding();

CREATE TRIGGER insert_understanding BEFORE INSERT ON taxonomy.genus
FOR EACH ROW EXECUTE FUNCTION insert_understanding();

CREATE TRIGGER insert_understanding BEFORE INSERT ON taxonomy.species
FOR EACH ROW EXECUTE FUNCTION insert_understanding();


-- Set up the ranks for NON-AGGREGATE

insert into taxonomy.capstone (name, author, year, parent) VALUES ('BWARS', 'BWARS', '2022',1);

INSERT INTO taxonomy.superfamily (name, author, year, parent) SELECT name, isoauth, isoyear, 1 FROM public.superfamily;

INSERT INTO taxonomy.family (name, author, year, parent)
SELECT s.name, s.isoauth, s.isoyear, np.id
FROM public.family s
JOIN public.superfamily op ON s.higherid = op.id
JOIN taxonomy.superfamily np ON op.name = np.name AND op.isoauth = np.author AND op.isoyear = np.year
WHERE s.name NOT LIKE '%agg';

INSERT INTO taxonomy.genus (name, author, year, parent)
SELECT s.name, s.isoauth, s.isoyear, np.id
FROM public.genus s
JOIN public.family op ON s.higherid = op.id
JOIN taxonomy.family np ON op.name = np.name AND op.isoauth = np.author AND op.isoyear = np.year
WHERE s.name NOT LIKE '%agg';

-- Species

-- Since the parent must be present for the creation process to accept the data, add the current definitions first
-- Something odd is going on with a silent fail of the constraint in mass adding of data, I think due to the delayed application of the constraint
-- Not a massive problem in anything other than the migration

--Start by transferring all of the non-synonym species

INSERT INTO taxonomy.species (name, author, year, parent)
SELECT s.name, s.isoauth, s.isoyear, np.id
FROM public.species s
JOIN public.genus op ON s.higherid = op.id
JOIN taxonomy.genus np ON op.name = np.name AND op.isoauth = np.author AND op.isoyear = np.year
WHERE s.id = s.current_understanding;

-- Now that all end points are in, add the synonym species that rely on those end points

INSERT INTO taxonomy.species (name, author, year, parent, current)
SELECT s.name, s.isoauth, s.isoyear, np.id, nc.id
FROM public.species s
JOIN public.genus op ON s.higherid = op.id
JOIN taxonomy.genus np ON op.name = np.name AND op.isoauth = np.author AND op.isoyear = np.year
JOIN public.species oc ON s.current_understanding = oc.id
JOIN taxonomy.species nc ON oc.name = nc.name AND oc.isoauth = nc.author AND oc.isoyear = nc.year
WHERE s.id != s.current_understanding;

-- Now set up the composition for non-aggregate taxa
-- Only species have aggregates right now so we can be a little cheap with the other ranks

INSERT INTO taxonomy.capstone_composition (subject, component) select id, id FROM taxonomy.capstone;

INSERT INTO taxonomy.superfamily_composition (subject, component) select id, id FROM taxonomy.superfamily;

INSERT INTO taxonomy.family_composition (subject, component) select id, id FROM taxonomy.family;

INSERT INTO taxonomy.genus_composition (subject, component) select id, id FROM taxonomy.genus;

-- For species we have to do this to the non-aggregate entries only
INSERT INTO taxonomy.species_composition (subject, component) select id, id FROM taxonomy.species WHERE name NOT LIKE '%agg';

-- It is not possible to set the composition of aggregates autonomously. The information simply doesn't exist anywhere in any system
-- This isn't surprising as it's a deficit this new system specifically aims to correct

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Falk et al'
AND o.year = 2019;

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Seifert'
AND o.year = 2018;

-- Deal with Andrena pilipes agg iso. Else & Edwards: 2018 

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Notton & Norman'
AND o.year = 2017;

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Schmid-Egger'
AND o.year = 2016;

-- Deal with the Chrysid block: ignita, mediata, niemelai iso Paukkunnen et al: 2015

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Edwards'
AND o.year = 2013;

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Seifert'
AND o.year = 2012;

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Smissen'
AND o.year = 2010;

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Notton and Dathe'
AND o.year = 2008;

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Murray et al'
AND o.year = 2008;

-- Deal with T. caespitum iso: Schlick-Steiner: 2006, only has one member which can't be the case any more

-- Deal with O. inermis, parietina iso: Amiet et al: 2004. Too many to pick from

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Falk'
AND o.year = 2004;

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Csösz & Seifert'
AND o.year = 2003;

-- Deal with Bitsch et al: 2001. Multiple options and multiple entries

-- Deal with Vikberg 2000, multiple options

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Dubois'
AND o.year = 1998;

-- Deal with Baker 1994

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Seifert'
AND o.year = 1992;

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Pulawski'
AND o.year = 1984;

-- Deal with Morgan 1984

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Elmes'
AND o.year = 1978;

-- Deal with Guiglia 1972, only has one option

-- Deal with Sladen 1912, only has one option

INSERT INTO taxonomy.species_composition (subject, component)
select o.id, c.id
from taxonomy.species o
JOIN taxonomy.species c ON o.author=c.author and o.year = c.year
WHERE o.name like '%agg'
AND c.name not like '%agg'
AND o.author like 'Saunders'
AND o.year = 1900;

-- Deal with Tachysphex unicolor agg, Unknown author, unknown year, so can't automate finding components