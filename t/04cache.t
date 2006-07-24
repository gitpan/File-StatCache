#!/usr/bin/perl -w
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Library General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#  (C) Paul Evans, 2006 -- leonerd@leonerd.org.uk

use strict;

use Test::More tests => 5;

use File::StatCache qw( stat );

sub touch($)
{
   my ( $path ) = @_;

   local *F;
   open( F, ">", $path ) or die "Cannot open '$path' in append mode - $!";
   print F "Content\n";
   close( F );
}

# Short cache timeout to ensure quicker testing run
$File::StatCache::STATTIMEOUT = 1;

my $touchfile = "./test-file-statcache.touch";

END {
   unlink( $touchfile );
}

if( -f $touchfile ) {
   warn "Testing file $touchfile already exists";
}

touch( $touchfile );

my @touchfilestats = CORE::stat( $touchfile );

my $now = time();
my @stats = stat( $touchfile );
is_deeply( \@stats, \@touchfilestats, "Initial stat() call" );

@stats = stat( $touchfile );
is_deeply( \@stats, \@touchfilestats, "Soon cached stat() call" );

my $wait = $File::StatCache::STATTIMEOUT + 1;
sleep( $wait );

@stats = stat( $touchfile );
is_deeply( \@stats, \@touchfilestats, "Later cached stat() call" );

unlink( $touchfile );

# We hope the cache doesn't time out yet - we want a cache hit
@stats = stat( $touchfile );
is_deeply( \@stats, \@touchfilestats, "Cache hit after unlink()" );

sleep( $wait );

@stats = stat( $touchfile );
is( scalar @stats, 0, "Later stat() call after unlink()" );
