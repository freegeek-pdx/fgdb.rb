SCHEMADUMPFILE = 'db/schema.sql'
DATADUMPFILE = 'db/devel_data.sql.gz'
METADATADIR = 'db/metadata'
METADATATABLES = %w[
        contact_method_types contact_types discount_schedules
        discount_schedules_gizmo_types gizmo_attrs gizmo_contexts
        gizmo_contexts_gizmo_typeattrs gizmo_contexts_gizmo_types
        gizmo_typeattrs gizmo_types payment_methods
        volunteer_task_types disbursement_types defaults
        community_service_types roles
]
MIGRATIONDIR = 'db/migrate'

def dump_metadata( rails_env = "development" )
  abcs, search_path = setup_environment(rails_env)
  case abcs[rails_env]["adapter"]
  when "postgresql"
    print "Dumping the metadata..."
    for table in METADATATABLES do
      command = 'pg_dump -i -U "%s" --disable-triggers -a -t "%s" -x -O -f %s/%s.sql %s %s' %
        [
         abcs[rails_env]["username"],
         table, METADATADIR, table,
         search_path,
         abcs[rails_env]["database"]
        ]
      system( command )
      raise "Error dumping metadata: '#{command}' " if $?.exitstatus == 1
      print "."
    end
    puts "done"
  else
    raise "Task not supported by '#{abcs["test"]["adapter"]}'"
  end
end

def dump_schema( rails_env = "development" )
  abcs, search_path = setup_environment(rails_env)
  case abcs[rails_env]["adapter"]
  when "postgresql"
    print "Dumping the schema..."
    `pg_dump -i -U "#{abcs[rails_env]["username"]}" -s -x -O -f #{SCHEMADUMPFILE} #{search_path} #{abcs[rails_env]["database"]}`
    raise "Error dumping database" if $?.exitstatus == 1
    puts "done"
  else
    raise "Task not supported by '#{abcs["test"]["adapter"]}'"
  end
end

def dump_data( rails_env = "development" )
  abcs, search_path = setup_environment(rails_env)
  case abcs[rails_env]["adapter"]
  when "postgresql"
    print "Dumping the data..."
    `pg_dump -i -U "#{abcs[rails_env]["username"]}" --disable-triggers -a -x -O #{search_path} #{abcs[rails_env]["database"]} | gzip -v > #{DATADUMPFILE}`
    raise "Error dumping database" if $?.exitstatus == 1
    puts "done"
  else
    raise "Task not supported by '#{abcs["test"]["adapter"]}'"
  end
end

def load_metadata( rails_env = "development" )
  abcs, search_path = setup_environment(rails_env)
  case abcs[rails_env]["adapter"]
  when "postgresql"
    load_data_from(METADATADIR, abcs, rails_env)
  else
    raise "Task not supported by '#{abcs["test"]["adapter"]}'"
  end
end

def load_data_from(dir, abcs, rails_env)
  dbname = abcs[rails_env]['database']
  print "Loading the meta-data..."
  for table in METADATATABLES do
    `echo "ALTER TABLE #{table} DISABLE TRIGGER ALL;
             DELETE FROM #{table};
             ALTER TABLE #{table} ENABLE TRIGGER ALL;" | psql -U "#{abcs[rails_env]["username"]}" #{dbname}`
    raise "Error cleaning table '#{table}'" if $?.exitstatus == 1
    print "."
    `psql -U "#{abcs[rails_env]["username"]}" #{dbname} -f #{dir}/#{table}.sql`
    raise "Error loading metadata" if $?.exitstatus == 1
    print "."
  end
  puts "done"
end

def load_schema( rails_env = "development" )
  abcs, search_path = setup_environment(rails_env)
  case abcs[rails_env]["adapter"]
  when "postgresql"
    dbname = abcs[rails_env]['database']
    print "Droping the database..."
    `dropdb -U "#{abcs[rails_env]["username"]}" #{dbname}`
    if $?.exitstatus == 1
      puts "Warning: error dropping database"
    else
      puts "done"
    end
    print "Creating the database..."
    `createdb -U "#{abcs[rails_env]["username"]}" #{dbname}`
    raise "Error creating database" if $?.exitstatus == 1
    puts "done"
    print "Loading the schema..."
    `psql -U "#{abcs[rails_env]["username"]}" #{dbname} -f #{SCHEMADUMPFILE}`
    raise "Error loading schema" if $?.exitstatus == 1
    puts "done"
  else
    raise "Task not supported by '#{abcs["test"]["adapter"]}'"
  end
end

def wipe( rails_env = "development" )
  f = open('config/database.yml')
  config = YAML::load(f.read)
  f.close()

  `dropdb -U "#{config[rails_env]["username"]}" #{config[rails_env]['database']}`
  `createdb -U "#{config[rails_env]["username"]}" #{config[rails_env]['database']}`
  if $?.to_i.nonzero?
    raise Exception, "failed to create db"
  end
end

def load_data( rails_env = "development" )
  abcs, search_path = setup_environment(rails_env)
  case abcs[rails_env]["adapter"]
  when "postgresql"
    dbname = abcs[rails_env]['database']
    print "Loading the data..."
    `zcat #{DATADUMPFILE} | psql -U "#{abcs[rails_env]["username"]}" #{dbname}`
    raise "Error loading data" if $?.exitstatus == 1
    puts "done"
  else
    raise "Task not supported by '#{abcs["test"]["adapter"]}'"
  end
end

def migrate_from_schema( rails_env = "development" )
  abcs, search_path = setup_environment(rails_env)
  case abcs[rails_env]["adapter"]
  when "postgresql"
    dbname = abcs[rails_env]['database']
    print "Migrating the database..."
    Dir.open(MIGRATIONDIR).find_all {|name|
      /sql$/.match(name)
    }.sort.each {|name|
      `psql -U "#{abcs[rails_env]["username"]}" #{dbname} -f #{MIGRATIONDIR}/#{name}`
      raise "Error loading data" if $?.exitstatus == 1
      print "."
    }
    puts "done"
  else
    raise "Task not supported by '#{abcs["test"]["adapter"]}'"
  end
end

def setup_environment(rails_env)
  abcs = ActiveRecord::Base.configurations
  ENV['PGHOST']     = abcs[rails_env]["host"] if abcs[rails_env]["host"]
  ENV['PGPORT']     = abcs[rails_env]["port"].to_s if abcs[rails_env]["port"]
  ENV['PGPASSWORD'] = abcs[rails_env]["password"].to_s if abcs[rails_env]["password"]
  search_path = abcs[rails_env]["schema_search_path"]
  search_path = "--schema=#{search_path}" if search_path
  return abcs, search_path
end

rails_env = ENV['RAILS_ENV'] || "production"
namespace :db do
#   desc "Migrate from schema.sql to current"
#   redefine_task :migrate => :environment do
#     migrate_from_schema(rails_env)
#   end

#   desc "Setup a new database"
#   task :setup => :environment do
#     load_schema(rails_env)
#     load_metadata(rails_env)
#     migrate_from_schema(rails_env)
#   end

  namespace :metadata do

    desc "Dump the metadata-related data from devel to SQL"
    task :dump => :environment do
      dump_metadata(rails_env)
    end

    desc "Load the metadata to all databases"
    task :load => :environment do
      load_metadata(rails_env)
    end

  end # namespace :metadata

#   namespace :schema do

#     desc "Dump the development database to an SQL file"
#     redefine_task :dump => :environment do
#       dump_schema(rails_env)
#     end

#     desc "Load the database schema into the development database"
#     redefine_task :load => :environment do
#       load_schema(rails_env)
#     end

#   end # namespace :schema

  namespace :data do

    desc "Dump the development database (including data) to a SQL file"
    task :dump => :environment do
      dump_data(rails_env)
    end

    desc ".."
    task :wipe do
      wipe(rails_env)
    end

    desc "Fill the database with data from the dumped SQL file"
    task :load => ['db:data:wipe', :environment, 'db:migrate'] do
      load_data(rails_env)
    end

  end # namespace :data

end # namespace :db
