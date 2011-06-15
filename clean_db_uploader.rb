# Options
$mysql_user = 'mangos'
$mysql_pass = 'mangos'

mangos_basedir = './mangos/'
ytdb_basedir = './YTDB/'
scriptdev2_basedir = './mangos/src/bindings/ScriptDev2/'
custom_sql_dir = './custom_sql/'

ytdb_full_db_dir = File.join ytdb_basedir, '/FullDB/'
ytdb_updates_dir = File.join ytdb_basedir, '/Updates/'
mangos_sql_mr_dir = File.join mangos_basedir, '/sql_mr/'
mangos_updates_dir = File.join mangos_basedir, '/sql/updates/'
mangos_base_sql_dir = File.join mangos_basedir, '/sql/'
scriptdev2_base_sql_dir = File.join scriptdev2_basedir, '/sql/'
scriptdev2_additions_dir = File.join scriptdev2_basedir, '/addition/'

# Common functions
def upload_file_to_db filename, database = 'mangos'
  `mysql -B -u#{$mysql_user} -p#{$mysql_pass} -D#{database} < "#{filename}"`
end
def recreate_db database
  if RUBY_PLATFORM =~ /mswin|mingw/
    `echo DROP DATABASE IF EXISTS #{database}; | mysql -B -u#{$mysql_user} -p#{$mysql_pass}`
    `echo CREATE DATABASE IF NOT EXISTS #{database}; | mysql -B -u#{$mysql_user} -p#{$mysql_pass}`
  else
    `echo "DROP DATABASE IF EXISTS #{database};" | mysql -B -u#{$mysql_user} -p#{$mysql_pass}`
    `echo "CREATE DATABASE IF NOT EXISTS #{database};" | mysql -B -u#{$mysql_user} -p#{$mysql_pass}`  
  end
end
def upload_by_glob glob, db = nil, except = []
  db ||= 'mangos'
  Dir.glob(glob).each do |file|
    next if except.member? File.basename(file)
    puts "File: #{File.basename file} to #{db}"
    upload_file_to_db file, db
  end
end


# Script begins
# Ask for permission to continue
puts "This will remove your 'characters', 'realmd', 'scriptdev2' and 'mangos' databases!"
print "Input \"yes\" to continue: "
exit unless gets.chomp == 'yes'
puts 'Ok...'
puts


# Read current revisions
$revision_r2 = File.open(File.join(mangos_basedir, '/src/shared/revision_R2.h')){ |file| file.read[/REVISION_R2 "(.*)"/, 1].to_i }
$revision_nr = File.open(File.join(mangos_basedir, '/src/shared/revision_nr.h')){ |file| file.read[/REVISION_NR "(.*)"/, 1].to_i }
puts "Current core revision: #{$revision_nr} mr#{$revision_r2}"

# Clear mangos DB
puts "Clearing databases"
recreate_db 'mangos'
recreate_db 'realmd'
recreate_db 'characters'
recreate_db 'scriptdev2'


# Upload basic structure
#upload_file_to_db File.join(mangos_base_sql_dir, 'mangos.sql'), 'mangos'
upload_file_to_db File.join(mangos_base_sql_dir, 'characters.sql'), 'characters'
upload_file_to_db File.join(mangos_base_sql_dir, 'realmd.sql'), 'realmd'
upload_file_to_db File.join(scriptdev2_base_sql_dir, 'scriptdev2_create_structure_mysql.sql'), 'scriptdev2'

# Full DB
$highest_ytdb_core_rev = $revision_nr
Dir.glob(File.join(ytdb_full_db_dir, '*.sql')).each do |file|
  spl = File.basename(file).split('_')
  $revision_ytdb = spl[2].gsub(/[^0-9]/, '').to_i
  $highest_ytdb_core_rev = spl[4].gsub(/[^0-9]/, '').to_i
  puts "Uploading Full DB file: #{File.basename file}"
  upload_file_to_db file
  puts "Full DB revision #{$revision_ytdb} for core >= #{$highest_ytdb_core_rev} uploaded!"
end
unless $revision_ytdb
  puts "No YTDB was uploaded! Is the Full DB sql file upacked? ...unable to continue..."
  exit
end

# YTDB updates
puts "Uploading YTDB updates"
Dir.glob(File.join(ytdb_updates_dir, '*.sql')).each do |file|
  update = File.basename(file, '.sql').split('_')
  is_corepatch = update[1] == 'corepatch'
  
  next if update[0].to_i <= $revision_ytdb
  if is_corepatch
    db = update[2]
    to_rev = update[5].to_i
  else
    db = update[1]
    to_rev = update[3].gsub(/[^0-9]/,'').to_i
  end
  next if db != 'mangos'
  next if to_rev > $revision_nr
  
  $highest_ytdb_core_rev = to_rev
  puts "File: #{File.basename file} to #{db}"
  upload_file_to_db file, db
end
puts "YTDB updates uploaded!"


# Core updates
puts "Uploading core updates"
Dir.glob(File.join(mangos_updates_dir, '*.sql')).each do |file|
  update = File.basename(file, '.sql').split('_')
  
  rev = update[0].to_i
  db = update[2]
  next if rev > $revision_nr || rev <= $highest_ytdb_core_rev
  
  puts "File: #{File.basename file} to #{db}"
  upload_file_to_db file, db  
end
puts "Core updates uploaded!"


# SQL_mr base
puts "Uploading SQL_mr base"
upload_by_glob File.join(mangos_sql_mr_dir, 'custom_characters_tables.sql'), 'characters'
upload_by_glob File.join(mangos_sql_mr_dir, 'custom_realmd_tables.sql'), 'realmd'
upload_by_glob File.join(mangos_sql_mr_dir, 'custom_mangos_tables.sql'), 'mangos'
puts "SQL_mr base uploaded!"


# SQL_mr updates
puts "Uploading SQL_mr updates"
upload_by_glob File.join(mangos_sql_mr_dir, 'mr*characters*.sql'), 'characters'
upload_by_glob File.join(mangos_sql_mr_dir, 'mr*realmd*.sql'), 'realmd'
upload_by_glob File.join(mangos_sql_mr_dir, 'mr*mangos*.sql'), 'mangos'
puts "SQL_mr udpates uploaded!"


# ScriptDev2 base
puts "Uploading ScriptDev2 base"
upload_by_glob File.join(scriptdev2_base_sql_dir, 'scriptdev2_script_full.sql'), 'scriptdev2'
upload_by_glob File.join(scriptdev2_additions_dir, 'boss_spell_table_scriptdev2.sql'), 'scriptdev2'
puts "ScriptDev2 base uploaded!"


# ScriptDev2 additions
puts "Uploading ScriptDev2 additions"
upload_by_glob File.join(scriptdev2_additions_dir, '*scriptdev2*.sql'), 'scriptdev2', ['boss_spell_table_scriptdev2.sql', 'spell_comment_from_wowd_scriptdev2.sql']
upload_by_glob File.join(scriptdev2_additions_dir, '*mangos*.sql'), 'mangos'
puts "ScriptDev2 additions uploaded!"


# Custom SQL
puts "Uploading custom SQL"
upload_by_glob File.join(custom_sql_dir, '*mangos*.sql'), 'mangos'
upload_by_glob File.join(custom_sql_dir, '*realmd*.sql'), 'realmd'
upload_by_glob File.join(custom_sql_dir, '*characters*.sql'), 'characters'
puts "Custom SQL uploaded!"