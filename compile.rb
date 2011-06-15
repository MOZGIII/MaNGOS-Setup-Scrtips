if RUBY_PLATFORM =~ /mswin|mingw/
  puts "I detect Windows... Do everything yourself!"
else
  Dir.chdir 'mangos' if File.directory? 'mangos'
  if File.directory? 'build'
    puts "'build' directory already created! You must remove it before you can continue!"
    exit
  end
  Dir.mkdir 'build'
  Dir.chdir 'build'
  
  flags = "-march=native -O2 -ggdb -pipe -D_LARGEFILE_SOURCE -frename-re gisters -fno-strict-aliasing -fno-strength-reduce -fno-delete-null-pointer-checks -ffast-math"
  conf_opts = '-DPCH=1'
  prefix = '/opt/mangos'
  sudo = "sudo " if ARGV.include? '--use-sudo'
  
  `#{sudo}cmake .. -DPREFIX="#{prefix}" #{conf_opts} -DCMAKE_C_FLAGS="#{flags}" -DCMAKE_CXX_FLAGS="#{flags}" -DCMAKE_C_COMPILER="gcc" -DCMAKE_CXX_COMPILER="g++"`
end