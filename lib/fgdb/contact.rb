#!/usr/bin/ruby
#
# This file contains the Contact class, which represents a person or
# organization, and has references to all other aspects of what that
# contact does, from buying things, to working, from adopting a
# computer, to borrowing a book.
#
# == Subversion ID
# 
# $Id$
# 
# == Authors
# 
# * Martin Chase <mchase@freegeek.org>
# 

require 'fgdb/object'

class FGDB::Contact < FGDB::Object

	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# SVN URL
	SVNURL = %q$URL$

	addAttributes( *%w[ firstname middlename lastname organization
		address address2 city state zip phone fax email emailOK mailOK
		phoneOK faxOK notes lists tasks ] )

	addAttributesReadOnly( *%w[ modified created sortName ] )

	####################
	# Instance Methods #
	####################

	def initialize()
		self.lists = []
		self.tasks = []
	end

	# the lists are responsible for calling this.
	def addToList( list )
		self.lists << list
	end

	# the lists are responsible for calling this.
	def removeFromList( list )
		self.lists.delete( list )
	end

	def addTask( task )
		task.contact = self
		self.tasks << task
	end

	def removeTask( task )
		self.tasks.delete( task )
		if task.contact == self
			task.contact = nil
		end
	end

	def hours 
		hour_sum = 0
		self.tasks.each {|task|
			hour_sum += task.hours
		}
		return hour_sum
	end

end # class FGDB::Contact
