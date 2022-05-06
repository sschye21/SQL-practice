# COMP3311 21T3 Ass2 ... Python helper functions
# add here any functions to share between Python scripts 
# you must submit this even if you add nothing

def getProgram(db,code):
  cur = db.cursor()
  cur.execute("select * from Programs where code = %s",[code])
  info = cur.fetchone()
  cur.close()
  if not info:
    return None
  else:
    return info

def getStream(db,code):
  cur = db.cursor()
  cur.execute("select * from Streams where code = %s",[code])
  info = cur.fetchone()
  cur.close()
  if not info:
    return None
  else:
    return info

def getStudent(db,zid):
  cur = db.cursor()
  qry = """
  select p.*, c.name
  from   People p
         join Students s on s.id = p.id
         join Countries c on p.origin = c.id
  where  p.id = %s
  """
  cur.execute(qry,[zid])
  info = cur.fetchone()
  cur.close()
  if not info:
    return None
  else:
    return info

# Returns transcript info for student zid
def getTrans(db, zid):
  cur = db.cursor()
  qry = """
    select *
    from transcript(%s)
  """
  cur.execute(qry, [zid])
  info = cur.fetchall()
  cur.close()
  if not info:
    return None
  else:
    return info

# Returns the program information from an sql query
def getProgramCodeInfo(db, code):
  cur = db.cursor()
  qry = """
    select p.code, r.name, r.type, r.min_req, r.max_req, aog.type, aog.defby, aog.definition
    from programs p join program_rules pr on (pr.program = p.id) join rules r on (r.id = pr.rule) join academic_object_groups aog on (r.ao_group = aog.id)
    where p.code = %s
  """
  cur.execute(qry, [code])
  codeInfo = cur.fetchall()
  cur.close()
  if not codeInfo:
    return None
  else:
    return codeInfo

# Gets stream information per stream code
def getStreamCodeInfo(db, code):
  cur = db.cursor()
  qry = """
    select s.code, r.name, r.type, r.min_req, r.max_req, aog.type, aog.defby, aog.definition
    from streams s join stream_rules sr on (sr.stream = s.id) 
      join rules r on (r.id = sr.rule) 
      join academic_object_groups aog on (r.ao_group = aog.id)
    where s.code = %s
  """
  cur.execute(qry, [code])
  codeInfo = cur.fetchall()
  cur.close()
  if not codeInfo:
    return None
  else:
    return codeInfo

# Gets subject Information as per subject code
def getSubjectInfo(db, subjectCode):
  cur = db.cursor()
  qry = """
    select s.name
    from subjects s
    where s.code = %s
  """
  cur.execute(qry, [subjectCode])
  subjectInfo = cur.fetchone()
  cur.close()
  if not subjectInfo:
    return None
  else:
    return subjectInfo

# Prints Course Statement
def printCourseStatement(name, min_req, max_req, courses):
  if (len(courses) == 8):
    print(f"{name}")
    return
  
  if (min_req is None and max_req is None):
    print(f"all courses from {name}")
  
  elif (min_req is not None and max_req is None):
    print(f"at least {min_req} courses from {name}")
  
  elif (min_req is None and max_req is not None):
    print(f"up to {max_req} courses from {name}")
  
  elif (min_req is not None and max_req is not None and min_req < max_req):
    print(f"between {min_req} and {max_req} courses from {name}")
  
  elif (min_req is not None and max_req is not None and min_req == max_req):
    print(f"{min_req} courses from {name}")
  return

# Gets school name per program code
def getSchool(db, code):
  cur = db.cursor()
  qry = """
    select o.longname
    from programs p join orgunits o on (p.offeredby = o.id)
    where p.code = %s
  """
  cur.execute(qry, [code])
  schoolName = cur.fetchone()
  cur.close()
  if not schoolName:
    return None
  else:
    return schoolName

# Prints UOC Statements
def printUOCStatement(name, min_req, max_req):
  if (min_req is None and max_req is None):
    print(f"{name}")
  
  elif (min_req is not None and max_req is None):
    print(f"at least {min_req} UOC courses from {name}")
  
  elif (min_req is None and max_req is not None):
    print(f"up to {max_req} UOC courses from {name}")
  
  elif (min_req is not None and max_req is not None and min_req < max_req):
    print(f"between {min_req} and {max_req} UOC courses from {name}")
  
  elif (min_req is not None and max_req is not None and min_req == max_req):
    print(f"{min_req} UOC courses from {name}")
  return

# Gets the school associated with stream code
def getSchoolStream(db, code):
  cur = db.cursor()
  qry = """
    select o.longname
    from streams s join orgunits o on (s.offeredby = o.id)
    where s.code = %s
  """
  cur.execute(qry, [code])
  schoolName = cur.fetchone()
  cur.close()
  if not schoolName:
    return None
  else:
    return schoolName

# Prints the subject information
def printSubjectInfo(db, newTup):
  for subjectCode in newTup:
    if (subjectCode[0] == '{'):
      i = 1
      j = 9
      subjectInfo = getSubjectInfo(db, subjectCode[i:j])
      print(f"- {subjectCode[i:j]} {subjectInfo[0]}")
      i = i + j
      j = i + 8
      subjectInfo = getSubjectInfo(db, subjectCode[i:j])
      print(f"  or {subjectCode[i:j]} {subjectInfo[0]}")
    
    else:
      subjectInfo = getSubjectInfo(db, subjectCode)
      
      if (subjectInfo is None):
        print(f"- {subjectCode} ???")
      else:
        print(f"- {subjectCode} {subjectInfo[0]}")  

# Get the most recent enrolled program per student id
def getRecentProgram(db, zid):
  cur = db.cursor()
  qry = """
  select pe.program
  from course_enrolments ce join courses c on (ce.course = c.id)
      join terms t on (c.term = t.id)
      join program_enrolments pe on (ce.student = pe.student)
  where ce.student = %s
  order by t.code desc
  """
  cur.execute(qry, [zid])
  progCode = cur.fetchone()
  cur.close()
  if not progCode:
    return None
  else:
    return progCode

# Gets the most recent stream per student id
def getRecentStream(db, zid):
  cur = db.cursor()
  qry = """
  select s.code
  from stream_enrolments se join streams s on (se.stream = s.id)
      join program_enrolments pe on (se.partof = pe.id)
      join terms t on (pe.term = t.id)
  where pe.student = %s
  order by t.code desc
  """
  cur.execute(qry, [zid])
  streamCode = cur.fetchone()
  cur.close()
  if not streamCode:
    return None
  else:
    return streamCode

# Removing completed courses from rulesList
def removeCompletedCourses(transCode, rulesList):
  for subject in rulesList:
    if (subject[0] == '{'):
      i = 1
      j = 9
      if (transCode == subject[i:j]):
        rulesList.remove(subject)
        break
      else:
        i = i + j
        j = i + 8
        if (transCode == subject[i:j]):
          rulesList.remove(subject)
          break
    elif (subject == transCode):
      rulesList.remove(subject)
  return