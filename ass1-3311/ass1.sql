-- COMP3311 21T3 assignment 1
--
-- Fill in the gaps ("...") below with your code
-- You can add any auxiliary views/function that you like
-- The code in this file MUST load into a database in one pass
-- It will be tested as follows:
-- createdb test; psql test -f ass1.dump; psql test -f ass1.sql
-- Make sure it can load without errorunder these conditions


-- Q1: oldest brewery
-- What is the world's oldest brewery? Define an SQL view Q1(brewery) that gives its name.

create or replace view Q1(brewery)
as
select name as brewery
from breweries
where founded = (select MIN(founded) from breweries);

-- Q2: collaboration beers
-- Nowadays, brewers often work together to make a beer. Such a beer is called a "collaboration beer" (or just "collab" for short) 
-- and is registered as being brewed by both brewers. Define an SQL view Q2(beer) that gives the names of all collaboration beers.

create or replace view Q2(beer)
as
select b.name as beer
from brewed_by br join beers b on (br.beer = b.id)
group by br.beer, b.name
having count(br.brewery) > 1;

-- Q3: worst beer
-- What is the worst beer in the world (determined by its rating)? Define a view Q3(worst) that gives its name. There may be several equally worst beers.

create or replace view Q3(worst)
as
select name as worst
from beers
where rating = (select MIN(rating) from beers);

-- Q4: too strong beer
-- Beers are brewed according to a style, which indicates what colour the beer should be, how strong it should be, etc. 
-- Occasionally brewers stray outside the bounds for a style e.g. make a beer stronger than the maximum ABV for that style. 
-- Define a view Q4(beer,abv,style,max_abv) that gives information about any beers whose ABV is higher than the maximum ABV for their style. 
-- The view should give the beer name, its ABV, its style, and the maximum ABV for that style.

create or replace view Q4(beer,abv,style,max_abv)
as
select b.name as beer, b.abv, s.name as style, s.max_abv
from beers b join styles s on (b.style = s.id)
where b.abv > s.max_abv;

-- Q5: most common style
-- What style of beer is most commonly brewed (as determined by the number of beers brewed to that style)? 
-- Define a view Q5(style) that gives the name of the most common style.

create or replace view Q5(style)
as
select s.name as style
from styles s join beers b on (s.id = b.style)
group by s.name
having count(s.name) = (select max(namecount) from (
	select count(ss.name) as namecount 
	from styles ss join beers b on (ss.id = b.style) 
	group by ss.name
) styles);

-- Q6: duplicated style names
-- Sometimes data entry can go wrong and two slightly different versions of a style name can be entered into the database. 
-- The difference might be a spelling mistake or a mismatch in upper/lower-case letters in the name. 
-- Spelling mistakes are difficult to determine, but case mismatches are easy to detect. 
-- Define a view Q6(style1,style2) that determines pairs of style names that differ only in the upper/lower case of their letters. 
-- The order of style names matters in the result tuple; the lexicographically smaller style name should be in style1.

create or replace view nameDuplicates(names) as (
	select upper(s3.name)
	from styles s3
	group by upper(s3.name)
	having count(*) > 1
);

create or replace view Q6(style1,style2)
as
select s1.name as style1, s2.name as style2
from styles s1, styles s2
where upper(s1.name) IN (
	select names
	from nameDuplicates
) AND upper(s2.name) IN (
	select names 
	from nameDuplicates
) AND s1.name != s2.name AND s1.name < s2.name;


-- Q7: breweries that make no beers
-- The partial participation line between Brewery and BrewedBy in the ER model for this database suggests that there may 
-- be breweries that haven't (so far) brewed any beers. Define a view Q7(brewery) that finds any such breweries.

create or replace view Q7(brewery)
as
select br.name as brewery
from breweries br left join brewed_by bb on (br.id = bb.brewery)
where bb.brewery IS NULL;

-- Q8: city with the most breweries
-- Some cities (metro attribute) are known as "hot-spots" for breweries. 
-- Define a view Q8(city,country) that finds the city which has the most breweries located in it and the country where that city is located..

create or replace view Q8(city,country)
as
select l.metro as city, l.country
from locations l join breweries b on (l.id = b.located_in)
group by l.metro, l.country
having count(l.metro) = (select max(citycount) from (
	select count(ll.metro) as citycount
	from locations ll join breweries bb on (ll.id = bb.located_in)
	group by ll.metro
) locations);

-- Q9: breweries that make more than 5 styles
-- Some breweries concentrate on a small number of beer varieties, others are prolific experimenters and make many different styles. 
-- Write a view Q9(brewery,nstyles) that gives the name and count of styles made by that brewery, for all breweries that make more than 5 different styles.

create or replace view Q9(brewery,nstyles)
as
select br.name as brewery, count(distinct b.style) as nstyles
from breweries br inner join brewed_by bb on (br.id = bb.brewery) join beers b on (bb.beer = b.id)
group by br.name
having count(distinct b.style) > 5;

-- Q10: beers of a certain style
-- Write a PLpgSQL function that takes a style name, and prints a list of all the beers that are brewed in that style.
create or replace view BeerInfo(beer, brewery, style, year, abv) as (
	select b.name, string_agg(br.name, ' + ' order by br.name), s.name, b.brewed, b.abv
	from breweries br inner join brewed_by bb on (br.id = bb.brewery) 
		join beers b on (bb.beer = b.id) 
		join styles s on (b.style = s.id) 
	group by b.name, s.name, b.brewed, b.abv
);

create or replace function
	q10(_style text) returns setof BeerInfo
as $$
begin
	return query
	select *
	from BeerInfo b
	where b.style = _style;
	return;
end;
$$
language plpgsql;

-- Q11: beers with names matching a pattern
-- Write a PLpgSQL function that takes a string as argument and finds all beers that contain that string in their name
create or replace view BeerInfo2(id, brewery, style, abv, beer) as (
	select b.id, string_agg(br.name, ' + ' order by br.name), s.name, b.abv, b.name
	from breweries br inner join brewed_by bb on (br.id = bb.brewery) 
		join beers b on (bb.beer = b.id)
		join styles s on (b.style = s.id)
	group by b.name, s.name, b.abv, b.id
);

create or replace function
	Q11(partial_name text) returns setof text
as $$
begin
	return query
	select ('"'||beer||'", '||brewery||', '||style||', '||abv||'% ABV')
	from BeerInfo2
	where lower(beer) like '%'||partial_name||'%'
	group by beer, style, abv, brewery;
	return;
end;
$$
language plpgsql;

-- Q12: breweries and the beers they make
-- Write a PostgreSQL function that takes a string as argument and gets information about all breweries that contain that string in their name

-- view that containing the beers made by the specified brewery
create or replace view BeerInfo3(beer, style, year, abv, brewery) as (
	select b.name, s.name, b.brewed, b.abv, br.name
	from breweries br inner join brewed_by bb on (br.id = bb.brewery) 
		join beers b on (bb.beer = b.id)
		join styles s on (b.style = s.id)
	group by b.name, s.name, b.brewed, b.abv, br.name
);

-- view for the brewery info that would match the brewery substring
create or replace view BreweryInfo(brewery, founded, country, region, metro, town) as (
	select br.name, br.founded, l.country, l.region, l.metro, l.town 
	from breweries br join locations l on (br.located_in = l.id) 
	group by br.name, br.founded, l.country, l.region, l.metro, l.town
);

create or replace function
	Q12(partial_name text) returns setof text
as $$
declare
	tuple record;
	beers_b BeerInfo3%ROWTYPE;
begin
	for tuple in select br.name, br.founded, l.country, l.region, l.metro, l.town 
		from breweries br join locations l on (br.located_in = l.id) 
		where lower(br.name) like '%'||partial_name||'%'
		order by br.name
	loop
		-- if town and metro are known, include just the town OR if metro is null then include town
		if (tuple.region is not null and tuple.town is not null and tuple.metro is not null) or (tuple.region is not null and tuple.town is not null and tuple.metro is null) then
			return next tuple.name||', founded '||tuple.founded;
			return next 'located in '||tuple.town||', '||tuple.region||', '||tuple.country;
		
		-- metro is not null and town is null
		elsif tuple.metro is not null and tuple.town is null and tuple.region is not null then
			return next tuple.name||', founded '||tuple.founded;
			return next 'located in '||tuple.metro||', '||tuple.region||', '||tuple.country;
		
		-- metro is null and town is null and region is null
		elsif tuple.metro is null and tuple.town is null and tuple.region is null then 
			return next tuple.name||', founded '||tuple.founded;
			return next 'located in '||tuple.country;
		
		-- region is null and metro is null
		elsif tuple.region is null and tuple.metro is null and tuple.town is not null then
			return next tuple.name||', founded '||tuple.founded;
			return next 'located in '||tuple.town||', '||tuple.country;
		
		-- metro and town is null
		elsif tuple.town is null and tuple.metro is null and tuple.region is not null then
			return next tuple.name||', founded '||tuple.founded;
			return next 'located in '||tuple.region||', '||tuple.country;

		-- region and town is null
		elsif tuple.region is null and tuple.town is null and tuple.metro is not null then
			return next tuple.name||', founded '||tuple.founded;
			return next 'located in '||tuple.metro||', '||tuple.country;
		
		-- only region is null
		elsif tuple.region is null and tuple.town is not null and tuple.metro is not null then
			return next tuple.name||', founded '||tuple.founded;
			return next 'located in '||tuple.town||', '||tuple.metro||', '||tuple.country;
		end if;

		select '  "'||beer||'", '||style||', '||year||', '||abv||'% ABV' into beers_b
		from BeerInfo3
		where lower(brewery) like lower(tuple.name);

		if beers_b is null then
			return next 'No known beers';
		else
			return query
			select '  "'||beer||'", '||style||', '||year||', '||abv||'% ABV'
			from BeerInfo3
			where lower(brewery) like lower(tuple.name)
			order by year;
		end if;
	end loop;
	return;
end;
$$
language plpgsql;
