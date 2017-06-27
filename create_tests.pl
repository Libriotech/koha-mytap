#!/usr/bin/perl

use Template;
use Data::Dumper;
use File::Slurper qw( read_lines );
use Modern::Perl;

# Set path to kohastructure.sql and check it exists
my $kohastructure_file = '/usr/share/koha/intranet/cgi-bin/installer/data/mysql/kohastructure.sql';
if ( !-e $kohastructure_file ) {
    print "The file '$kohastructure_file' does not exist!\n";
    exit;
}

# Configure Template Toolkit
my $ttconfig = {
    INCLUDE_PATH => './templates/', 
    ENCODING => 'utf8'  # ensure correct encoding
};
# create Template object
my $tt2 = Template->new( $ttconfig ) || die Template->error(), "\n";

my %tables;
my @columns;
my $tablename;
my @lines = read_lines( $kohastructure_file );
foreach my $line ( @lines ) {

    chomp $line;

    # Remove leading whitespace
    $line =~ s/^ {1,}//g;
    # Remove ticks
    $line =~ s/`//g;
    # Remove any tabs
    $line =~ s/\t//g;

    next if $line =~ m|^/|i;
    next if $line =~ m/^--/i;
    next if $line =~ m/^\n$/i;
    next if $line =~ m/^DROP/i;
    next if $line eq '';
    next if $line =~ m/^primary/i;
    next if $line =~ m/^key/i;
    next if $line =~ m/^constraint/i;
    next if $line =~ m/^unique/i;
    next if $line =~ m/^foreign/i;
    next if $line =~ m/^references/i;
    next if $line =~ m/^on /i;
    next if $line =~ m/^index /i;
    next if $line =~ m/^alter /i;
    next if $line =~ m/^add /i;
    next if $line =~ m/^check /i;

    if ( $line =~ m/^CREATE TABLE/ ) {
        if ( $line =~ m/create table `(.*?)`/i ) {
            $tablename = $1;
        } elsif ( $line =~ m/create table if not exists `(.*?)`/i ) {
            $tablename = $1;
        } elsif ( $line =~ m/create table if not exists (.*?) \(/i ) {
            $tablename = $1;
        } elsif ( $line =~ m/create table (.*?) \(/i ) {
            $tablename = $1;
        } elsif ( $line =~ m/create table (.*?)\(/i ) {
            $tablename = $1;
        }
    } elsif ( $line =~ m/;/ ) {
        undef @columns;
    } else {
        my ( $name, $type, $more ) = split / /, $line, 3;
        push @{ $tables{ $tablename } }, {
            'name' => $name,
            'type' => $type,
        };
    }

}

# Output
foreach my $table ( keys %tables ) {
    $tt2->process( 'table.tt', {
        'table' => $table,
        'cols'  => $tables{ $table },
    }, "t/$table.sql" ) || die $tt2->error();
}
