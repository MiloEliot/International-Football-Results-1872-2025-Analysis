-- import former_names.csv
drop table if exists former_names;
create table former_names (
id bigint generated always as identity primary key,
current varchar(64),
former varchar(64),
start_date date,
end_date date
);
copy former_names("current", former, start_date, end_date)
from '/Users/yingliu/Documents/GitHub/Global_Football_Goalscorers_Analysis/data/former_names.csv'
delimiter ','
csv header;


-- import goalscorers.csv
drop table if exists temp_table;
create table temp_table (
id bigint generated always as identity primary key, 
"date" date,
home_team varchar(64),
away_team varchar(64),
team varchar(64),
scorer text,
"minute" varchar(16),
own_goal boolean,
penalty boolean
);

copy temp_table("date", home_team, away_team, team, scorer, "minute", own_goal, penalty)
from '/Users/yingliu/Documents/GitHub/Global_Football_Goalscorers_Analysis/data/goalscorers.csv'
delimiter ','
csv header;


drop table if exists goalscorers;
create table goalscorers (
id bigint generated always as identity primary key, 
"date" date,
home_team varchar(64),
away_team varchar(64),
team varchar(64),
scorer text,
"minute" int,
own_goal boolean,
penalty boolean
);

insert into goalscorers("date", home_team, away_team, team, scorer, "minute", own_goal, penalty)
select "date", home_team, away_team, team, scorer, 
	case
		when "minute"= 'NA' then null 
		else "minute"::int
	end as "minute",
	own_goal, penalty
from temp_table;
drop table if exists temp_table;


-- import results.csv
drop table if exists results cascade;
create table results ( 
id bigint generated always as identity primary key,
"date" date,
home_team varchar(64),
away_team varchar(64),
home_score int,
away_score int,
tournament varchar(64),
city varchar(64),
country varchar(64),
neutral boolean
);

copy results("date", home_team, away_team, home_score, away_score, tournament, city, country, neutral)
from '/Users/yingliu/Documents/GitHub/Global_Football_Goalscorers_Analysis/data/results.csv'
delimiter ','
csv header;

-- import shootouts.csv
drop table if exists shootouts cascade;
create table shootouts ( 
id bigint generated always as identity primary key,
"date" date,
home_team varchar(64),
away_team varchar(64),
winner varchar(64),
first_shooter text
); 

copy shootouts("date", home_team, away_team, winner, first_shooter)
from '/Users/yingliu/Documents/GitHub/Global_Football_Goalscorers_Analysis/data/shootouts.csv'
delimiter ','
csv header;


-- create a table for the current names of each country
drop table if exists countries cascade;
create table countries(
id bigint generated always as identity primary key,
country_name varchar(64) unique
);

insert into countries(country_name)
	select home_team from goalscorers
	union
	select away_team from goalscorers 
	union
	select home_team from results 
	union
	select away_team from results
	union
	select home_team from shootouts 
	union 
	select away_team from shootouts 
on conflict (country_name) do nothing;


-- add a foreign key to former_names.current / goalscorers.home_team / goalscorers.away_team
alter table former_names 
add constraint country_name_fk
foreign key (current)
references countries(country_name)
on delete no action
on update no action;

alter table goalscorers 
add constraint g_home_team_fk
	foreign key (home_team) references countries(country_name)
	on delete no action
	on update no action,
add constraint g_away_team_fk
	foreign key (away_team) references countries(country_name)
	on delete no action
	on update no action;

alter table results 
add constraint r_home_team_fk
	foreign key (home_team) references countries(country_name)
	on delete no action
	on update no action,
add constraint r_away_team_fk
	foreign key (away_team) references countries(country_name)
	on delete no action
	on update no action;

alter table shootouts 
add constraint s_home_team_fk
	foreign key (home_team) references countries(country_name)
	on delete no action
	on update no action,
add constraint s_away_team_fk
	foreign key (away_team) references countries(country_name)
	on delete no action
	on update no action;


-- create a table to store all scorers
drop table if exists scorers cascade;
create table scorers (
id bigint generated always as identity primary key,
name text,
country varchar(64),
constraint scorer_country_unique unique(name, country)
);

insert into scorers(name, country)
	select scorer, team from goalscorers 
on conflict (name, country) do nothing;

-- add foreign key to goalscorers / shootouts
alter table goalscorers 
add constraint g_scorer_country_fk 
foreign key (scorer, team)
references scorers(name, country)
on delete no action 
on update no action;





