use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'File::StatCache',
   dist_version_from => 'lib/File/StatCache.pm',
   license => 'perl',
  );
  
$build->create_build_script;
