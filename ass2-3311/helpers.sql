-- COMP3311 21T3 Ass2 ... extra database definitions
-- add any views or functions you need into this file
-- note: it must load without error into a freshly created mymyunsw database
-- you must submit this even if you add nothing to it

create or replace function transcript(_zid integer) returns setof TranscriptRecord
as $$
    select s.code, t.code, s.name, ce.mark, ce.grade, s.uoc
    from course_enrolments ce join courses c on (ce.course = c.id) 
    join subjects s on (c.subject = s.id) 
    join terms t on (c.term = t.id)
    where ce.student = _zid
    order by t.id, t.code, s.code
$$ language sql
;
