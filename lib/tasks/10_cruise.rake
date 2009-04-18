# -*- Ruby -*-

def runtask(task)
  puts "--Started at: " + Time.now.to_s
  ret = system("rake RAILS_ENV=development #{task}")
  puts "--Finished at: " + Time.now.to_s
  return ret
end


task :download_devel_data do
  system("make -C db other_clean ; make -C db BASE_URL=http://dev.freegeek.org/~ryan52/devel_data") or raise
end

task :do_i_have_everything_installed_right do
  system("./script/do_i_have_everything_installed_right") or raise
end

task :cruise do
  ['do_i_have_everything_installed_right', 'crash:prevent', 'db:drop', 'db:create', 'db:schema:revert', 'download_devel_data', 'db:data:old:load', 'db:metadata:load', 'db:migrate', 'autodoc', 'db:test:purge', 'db:test:prepare', 'test'].each{|x|
    arr = x.split(":")
    if arr.length > 1
      string = "#{arr[arr.length - 1].sub(/e$/, "")}ing the #{arr[arr.length - 2]}"
    else
      string = "#{arr[arr.length - 1].sub(/e$/, "")}ing"
    end
    (string.length + 4).times{
      print '='
    }
    puts ""
    print '| '
    print string
    puts ' |'
    (string.length + 4).times{
      print '='
    }
    puts ""
    if !runtask(x)
      (string.length + 18).times{
        printf "="
      }
      puts
      puts "=== #{string.upcase} FAILED!!! ==="
      (string.length + 18).times{
        printf "="
      }
      puts
      exit 1
    end
  }
end

namespace :crash do
task :prevent do
  if system("grep -qR \"^require 'test_helper'$\" #{RAILS_ROOT}/test")
    puts "GENERATORS are NOT perfect! ***TEST*** and ***TWEAK*** the code they generate BEFORE committing. and please, stop crashing my server. kthxbye."
    raise
  end
end
end

task :autodoc => :environment do
  abcs = setup_environment(RAILS_ENV)[0]
  base_cmdline = "postgresql_autodoc -d #{abcs[RAILS_ENV]["database"]} -f #{RAILS_ROOT}/doc/autodoc/fgdb "
  [
   "mkdir -p #{RAILS_ROOT}/doc/autodoc",
   "if ! test -h #{RAILS_ROOT}/doc/autodoc/autodoc; then ln -s . #{RAILS_ROOT}/doc/autodoc/autodoc; fi",
   base_cmdline + "-t html",
   base_cmdline + "-t dot",
   "dot -Tgif -o #{RAILS_ROOT}/doc/autodoc/fgdb.gif < #{RAILS_ROOT}/doc/autodoc/fgdb.dot",
   "rm #{RAILS_ROOT}/doc/autodoc/fgdb.dot"
#  sed -i 's*<!-- Primary Index -->*<a href="fgdb.gif"><img src="fgdb.gif" /></a><!-- Primary Index -->*' fgdb.html
  ].each do |x|
    if !system(x)
      exit 1
    end
  end
end
