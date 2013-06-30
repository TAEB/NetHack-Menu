# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'NetHack-Menu';
all_from       'lib/NetHack/Menu.pm';
githubmeta;

requires       'Moose';

build_requires 'Test::Fatal';
build_requires 'Test::Deep';

auto_install;
WriteAll;

