`git clone git://github.com/mangosR2/mangos.git`
`git clone git://github.com/KiriX/YTDB.git`
`git clone git://github.com/mangosR2/scriptdev2.git mangos/src/bindings/ScriptDev2`

unless RUBY_PLATFORM =~ /mswin|mingw/
  Dir.chdir 'mangos'
  Dir.glob('src/bindings/ScriptDev2/patch/*.patch').each do |file|
    `git apply #{file}`
  end
  Dir.chdir '..'
end

Dir.glob(File.join('YTDB', 'FullDB/*.7z')).each do |file|
  puts "Unpacking YTDB: #{File.basename file}"
  if RUBY_PLATFORM =~ /mswin|mingw/  
    `7za.exe x -o"#{File.dirname file}" "#{file}"`
  else
    `7z x -o"#{File.dirname file}" "#{file}"`
  end
  puts "YTDB unpacked!"
end