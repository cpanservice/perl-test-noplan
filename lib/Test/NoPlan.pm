package Test::NoPlan;

use warnings;
use strict;

use version; our $VERSION = version->new('0.0.1');

use base 'Exporter';
use Test::Builder::Module;

use FindBin qw($Bin);
use Cwd;
use File::Spec;
use Carp;

#our @EXPORT    = qw( all_plans_ok );
#our @EXPORT_OK = qw( get_file_list check_file_for_no_plan );
our @EXPORT_OK = qw( all_plans_ok get_file_list check_file_for_no_plan );

{
    my $CLASS = __PACKAGE__;

    my @allowed_args = qw/ check_files recurse topdir _stdout _stderr /;

    sub all_plans_ok {
        my ($arg_ref) = @_;
        _check_args($arg_ref);

        my @files = get_file_list($arg_ref);

        my $test = Test::Builder->create();
        if($arg_ref->{_stdout}) {
            if ( ref $arg_ref->{_stdout} ne 'IO::Scalar' ) {
                croak '_stdout is not an IO::Scalar';
            }
            $test->output($arg_ref->{_stdout});
        }
        if($arg_ref->{_stderr}) {
            if ( ref $arg_ref->{_stderr} ne 'IO::Scalar' ) {
                croak '_stderr is not an IO::Scalar';
            }
            $test->failure_output($arg_ref->{_stderr});
        }
        $test->plan( tests => scalar @files );

        foreach my $file (@files) {
            $test->ok( check_file_for_no_plan($file),
                "'$file' has 'no_plan'" );
        }

        return 1;
    }

    sub _check_args {
        my ($arg_ref) = @_;
        if ( ref($arg_ref) ne 'HASH' ) {
            croak 'arguments do not seem to be a hash -> ', ref($arg_ref);
        }

        my @unknown_args;

        foreach my $arg ( sort( keys(%$arg_ref) ) ) {
            if ( !grep {/^$arg$/} @allowed_args ) {
                push @unknown_args, $arg;
            }
        }
        if (@unknown_args) {
            die 'Unknown arguments: ', join( ',', @unknown_args );
        }
        return;
    }

    sub get_file_list {
        my ($arg_ref) = @_;

        _check_args($arg_ref);

        my $topdir = $Bin;
        if ( $arg_ref->{topdir} && $arg_ref->{topdir} ne '.' ) {
            $topdir = $arg_ref->{topdir};
        }
        if ( defined($topdir) && length $topdir && !-d $topdir ) {
            die( 'Invalid topdir provided: "' . $topdir . '"' );
        }
        my $cwd = getcwd();
        $topdir =~ s!$cwd/!!;

        my $check_files = qr/^.*\.t$/xsm;
        if ( $arg_ref->{check_files} ) {
            $check_files = $arg_ref->{check_files};
        }
        if ( ref($check_files) ne 'Regexp' ) {
            die 'invalid check_files provided';
        }

        my @files = ();
        opendir( my $topdir_dh, $topdir )
            or die 'Unable to read ', $topdir, ': ', $!;

        while ( my $dir_entry = readdir($topdir_dh) ) {
            next if ( $dir_entry =~ m/^\./xsm );

            my $resolved_entry = File::Spec->catfile( $topdir, $dir_entry );

            if ( -d $resolved_entry ) {
                if ( $arg_ref->{recurse} ) {
                    my %new_args = %$arg_ref;
                    $new_args{topdir} = $resolved_entry;
                    push @files, get_file_list( \%new_args );

                    #{ %{$arg_ref}, topdir => $resolved_entry, } );
                }
                next;
            }

            if ( $dir_entry =~ $check_files ) {
                push @files, $resolved_entry;
            }
        }

        closedir($topdir_dh) or die 'Unable to close ', $topdir, ': ', $!;

        return sort @files;
    }

    sub check_file_for_no_plan {
        my ($file) = @_;

        open( my $file_fh, '<', $file )
            or die 'Unable to read ' . $file . ': ', $!;
        my $file_contents = <$file_fh>;

        my $return_code = 1;
        if ( $file_contents =~ m/^.*(?<!\#).*no_plan/xsm ) {
            $return_code = 0;
        }
        close($file_fh);

        return $return_code;
    }
}

=head1 NAME

Test::NoPlan - The great new Test::NoPlan!

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Test::NoPlan;

    my $foo = Test::NoPlan->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 all_plans_ok({ [ options ] });

Searches for and checks files within the current directory.  Options are

=over

=item topdir => '.'

directory to begin search in - relative to the top directory in the project
(i.e. where the Makefile.OPL/Build.PL files are located

=item check_files => qr/^.*\.t/xsm

Regexp used to identify files to check - i.e. files ending in .t

=item recurse => 0

Recurse into any subdirectories

=back

=head2 get_file_list( { [ options ] } );

Return a list of files to be checked - uses same options as C<all_plans_ok>

=head2 check_file_for_no_plan( $filename );

=head1 AUTHOR

Duncan Ferguson, C<< <duncan_j_ferguson at yahoo.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-noplan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-NoPlan>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::NoPlan


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-NoPlan>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-NoPlan>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-NoPlan>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-NoPlan/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Duncan Ferguson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Test::NoPlan