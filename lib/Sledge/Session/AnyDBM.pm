package Sledge::Session::AnyDBM;
# $Id$
#
# Koichi Taniguchi <taniguchi@livedoor.jp>
# Tatsuhiko Miyagawa <miyagawa@livedoor.jp>
# Livedoor, Co.,Ltd.
#

use strict;
use base qw(Sledge::Session);

use File::Spec;
use Fcntl qw(:DEFAULT);
use Sledge::Exceptions;

sub _connect_database { 
    my($self, $page) = @_;
    my $conf = $page->create_config;
    my $dbm_file = eval{ $conf->dbm_filename } || '/tmp/Sledge-Session';
    my $dbm_pkg = eval{ $conf->dbm_package };
    unless ($dbm_pkg) {
	require AnyDBM_File;
	$dbm_pkg = $AnyDBM_File::ISA[0];
	$dbm_pkg or
	    Sledge::Exception::DBConnectionError->throw(
		"Any DBM package is not installed on this server."
	    );
    }
    eval qq{ use $dbm_pkg };
    Sledge::Exception::DBConnectionError->throw($@)
	if $@ && $@ =~ /Can\'t locate/;
    my %sessions = ();
    tie(%sessions, $dbm_pkg, $dbm_file, O_RDWR|O_CREAT, 0666)
	or Sledge::Exception::DBConnectionError->throw($!);
    return \%sessions;
}

sub _commit  { untie %{shift->{_dbh}} }
sub _do_lock { }
sub _lockid  { }

sub _select_me { 
    my $self = shift;
    my $data = $self->{_dbh}->{$self->{_sid}};
    $data = $self->__split_data($data, 1);
    $self->{_data} = $self->_deserialize($data);
}

sub _insert_me {
    my $self = shift;
    my $hashref = $self->{_dbh};
    $hashref->{$self->{_sid}} =
	join "\0", time, $self->_serialize($self->{_data});
}

sub _update_me { shift->_insert_me }

sub _delete_me {
    my $self = shift;
    delete $self->{_dbh}->{$self->{_sid}};
}

sub _do_cleanup { 
    my($self, $hashref, $min) = @_;
    my $now = time;
    while (my($sid, $value) = each %$hashref) {
	delete $hashref->{$sid}
	    if $self->__split_data($value, 0) <= $now - $min * 60;
    }
}

sub __split_data {
    my($self, $data, $flag) = @_;
    return $flag ? ($data =~ /^\d+(?:\0(.*))?$/s)[0] : ($data =~ /^(\d+)/)[0];
}

1;

__END__

=head1 NAME

Sledge::Session::AnyDBM - Session stored in DBM file

=head1 SYNOPSIS

  package MyProj::Pages;
  use Sledge::Session::AnyDBM;

  sub create_session {
      my($self, $sid) = @_;
      Sledge::Session::AnyDBM->new($self, $sid);
  }

  package MyProj::Config::_common;

  $C{DBM_FILE} = "/path/to/dbmfile";
  $C{DBM_PACKAGE} = "DB_File";

=head1 DESCRIPTION

Sledge::Session::AnyDBM is a Sledge Session implementation that allows
you to use DBM file as a session storage. It's something like
Apache::Session::DB_File in Sledge::Session.

=head1 CONFIGURATION

You can use folloowing variabls in your Config file:

=over 4

=item DBM_FILE

  $C{DBM_FILE} = "/path/to/dbmfile";

it supplies path to DBM file. defaults to C</tmp/Sledge-Session>.

=item DBM_PACKAGE

  $C{DBM_PACKAGE} = "DB_File";

package name that you can tie your session into. it defaults to
C<$AnyDBM::ISA[0]>.

=back

=head1 AUTHOR

Originally written by Koichi Taniguchi E<lt>taniguchi@livedoor.jpE<gt>

Packaged into Sledge and test suite written by Tatsuhiko Miyagawa E<lt>miyagawa@livedoor.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Sledge itself.

=head1 SEE ALSO

L<Sledge>

=cut


