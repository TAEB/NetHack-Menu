# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'NetHack-Menu';
all_from       'lib/NetHack/Menu.pm';

requires       '';

build_requires 'Test::More';

auto_install;
WriteAll;

