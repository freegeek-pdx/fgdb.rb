#!/usr/bin/ruby -w
#
#   user api tests
#

class UserTests < Test::Unit::TestCase

#	include StandardTests

#	self.tested_class = FGDB::User

	def test_020_login
		user = nil
		assert_nothing_raised { user = FGDB::User.login( 'god', 'sex' ) }
        assert( user.name == 'god' )
        assert_raises( FGDB::LoginError ) { FGDB::User.login( 'god', 'blah' ) }
        assert_raises( NoMethodError ) { FGDB::User.new }
        assert_kind_of( FGDB::User, user )
        assert_respond_to( user, :contact )
        assert_kind_of( FGDB::Contact, user.contact )

        assert_nothing_raised { user.password = 'blah' }
        assert_nothing_raised { user.commit }

        assert_nothing_raised { user.logout }
        
        assert_raises( FGDB::LoginError) { FGDB::User.login( 'god', 'sex' ) }
        assert_nothing_raised { user = FGDB::User.login( 'god', 'blah' ) }
        assert_nothing_raised { user.password = 'sex' }
        assert_nothing_raised { user.commit }
        assert_nothing_raised { user.logout }

        assert_nothing_raised { user = FGDB::User.login( 'god', 'sex' ) }
        assert_raises( FGDB::LoginError ) { FGDB::User.login( 'god', 'blah' ) }

	end
       

end # class UserTests
