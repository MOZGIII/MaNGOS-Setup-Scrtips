`git clone git://github.com/mangosR2/mangos.git`
`git clone git://github.com/KiriX/YTDB.git`
`git clone git://github.com/mangosR2/scriptdev2.git mangos/src/bindings/ScriptDev2`

unless ARGV.include? '--no-sd2-patch'
  unless RUBY_PLATFORM =~ /mswin|mingw/
    puts "Patching MaNGOS with ScriptDev2 patches"
    Dir.chdir 'mangos'
    Dir.glob('src/bindings/ScriptDev2/patch/*.patch').each do |file|
      puts "Applying: #{file}"
      `git apply #{file}`
    end
    Dir.chdir '..'
  end
end

Dir.glob(File.join('YTDB', 'FullDB/*.7z')).each do |file|
  puts "Unpacking YTDB: #{File.basename file}"
  if RUBY_PLATFORM =~ /mswin|mingw/  
    `7za.exe x -o"#{File.dirname file}" "#{file}"`
  else
    `7z x -o"#{File.dirname file}" "#{file}"` # apt-get install p7zip-full
  end
  puts "YTDB unpacked!"
end