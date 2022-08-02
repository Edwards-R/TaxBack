SELECT
s.id as tik,
s.name as species,
s.author as species_author,
s.year as species_year,
s.current as synonym_of,
g.name as genus,
g.author as genus_author,
g.year as genus_year,
f.name as family,
f.author as family_author,
f.year as family_year,
spf.name as superfamily,
spf.author as superfamily_author,
spf.year as superfamily_year

FROM taxonomy.species s
JOIN taxonomy.genus g on s.parent = g.id
JOIN taxonomy.family f on g.parent = f.id
JOIN taxonomy.superfamily spf on f.parent = spf.id