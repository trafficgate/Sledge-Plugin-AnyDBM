# $Id$
#
# Tatsuhiko Miyagawa <miyagawa@livedoor.jp>
# Livedoor, Co.,Ltd.
#

use strict;
use Test::More;

BEGIN {
    eval { require Sledge::TestPages };
    plan $@ ? (skip_all => "no Sledge::TestPages") : (tests => 2);
}

package Mock::Pages;
use base qw(Sledge::TestPages);
use Sledge::Session::AnyDBM;

sub create_session {
    my($self, $sid) = @_;
    Sledge::Session::AnyDBM->new($self, $sid);
}

use vars qw($DBM_FILE $DBM_PACKAGE $COOKIE_NAME $TMPL_PATH);
$DBM_FILE = "/path/to/dbmfile";
$DBM_PACKAGE = "DB_File";
$COOKIE_NAME = "sid";
$TMPL_PATH   = "t/template";

sub dispatch_test {
    my $self = shift;
    $self->session->param(foo => "bar");
}

sub dispatch_test2 { }

package main;

do_test();

sub do_test {
    my $p = Mock::Pages->new;
    $p->dispatch("test");

    # get the SID from cookie
    my($sid) = $p->output =~ /sid=(\w+)/;

    $ENV{HTTP_COOKIE} = "sid=$sid";

    # check Session ID
    my $p2 = Mock::Pages->new;
    $p2->dispatch("test2");

    like $p2->output, qr/Session ID: $sid/, "Session ID: $sid";
    like $p2->output, qr/foo: bar/, "Session value";

    delete $ENV{HTTP_COOKIE};
}

