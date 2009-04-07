#!/usr/bin/make -f

all: download

download: update_devel_data_version devel_data.sql

devel_data.sql: devel_data.sql.lzma
	lzcat devel_data.sql.lzma > devel_data.sql

BASE_URL := http://develdata.freegeek.org/
#BASE_URL := http://dev.freegeek.org/~ryan52/devel_data

devel_data.sql.lzma: devel_data_version
	wget $(BASE_URL)/$(shell cat devel_data_version)/devel_data.sql.lzma -O devel_data.sql.lzma
	touch devel_data.sql.lzma

have_branch := $(wildcard branch_devel_data_version)

update_devel_data_version:
ifneq ($(strip $(have_branch)),)
	cp branch_devel_data_version devel_data_version
else
	wget $(BASE_URL)/version -O devel_data_version.new
	touch devel_data_version.new
	if [ ! -f devel_data_version ] || ! diff devel_data_version devel_data_version.new; then mv devel_data_version.new devel_data_version; else rm devel_data_version.new; fi
endif

create: create_devel_data
clean: clean_devel_data
create_devel_data: clean_devel_data fgdb-devel-data ohaither

fgdb-devel-data: tmp/devel_data/svn_repo/devel_data.sql.lzma
	ln -s db/tmp/devel_data/svn_repo/ ../fgdb-devel-data

committed: clean_devel_data download

commit:
	cd ..; git commit -a -m "updated devel data"; cd fgdb-devel-data; under-myagent svn ci -m "updated devel data"; cd ..; under-myagent git push fg
	@make committed

ohaither:
	@echo
	@echo "==========================================================="
	@echo "Done."
	@echo
	@echo "Please look at the results and run 'make -C db commit'"
	@echo "==========================================================="
	@echo

clean_devel_data:
	rm -fr tmp/devel_data ../fgdb-devel-data

tmp/devel_data/dir:
	mkdir -p $@

tmp/devel_data/database.sql.gz: tmp/devel_data/dir
	under-myagent scp tulip:/usr/local/arik/database.sql.gz ./tmp/devel_data/

tmp/devel_data/database.sql: tmp/devel_data/database.sql.gz
	zcat tmp/devel_data/database.sql.gz > tmp/devel_data/database.sql
	sed -i "s/fgdb_production/fgdb_development/g" tmp/devel_data/database.sql

tmp/devel_data/load_db: tmp/devel_data/database.sql
	-dropdb fgdb_development
	createdb fgdb_development
	psql fgdb_development < tmp/devel_data/database.sql
	touch $@

tmp/devel_data/mutate: tmp/devel_data/load_db
	RAILS_ENV=development ../script/data_mutate
	touch $@

tmp/devel_data/devel_data.sql: tmp/devel_data/mutate
	FGDB_INTERNAL_DUMP_FILE=$(shell readlink -f tmp/devel_data/devel_data.sql) RAILS_ENV=development rake db:data:dump

tmp/devel_data/devel_data.sql.lzma: tmp/devel_data/devel_data.sql
	cat tmp/devel_data/devel_data.sql | lzma -9 > tmp/devel_data/devel_data.sql.lzma

tmp/devel_data/svn_repo:
	under-myagent svn co svn+ssh://devo/svn/fgdb-devel-data/trunk tmp/devel_data/svn_repo
	touch tmp/devel_data/devel_data.sql.lzma # so that tmp/devel_data/svn_repo/devel_data.sql.lzma will get rebuilt even tho it has a newer timestamp

tmp/devel_data/svn_repo/devel_data.sql.lzma: tmp/devel_data/devel_data.sql.lzma tmp/devel_data/svn_repo
	cp tmp/devel_data/devel_data.sql.lzma tmp/devel_data/svn_repo/devel_data.sql.lzma
