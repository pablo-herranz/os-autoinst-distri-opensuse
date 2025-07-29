# SUSE's openQA tests
#
# Copyright 2012-2019 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Configure WSL users
# Maintainer: qa-c  <qa-c@suse.de>

use Mojo::Base qw(windowsbasetest);
use testapi;
use utils qw(enter_cmd_slow zypper_call);

# Define screen resolution to center the mouse later
use constant WIDTH  => 1024;
use constant HEIGHT => 768;

sub run () {
    my $self = shift;

    # Check if there is an already opened PowerShell window, otherwise, open one
    assert_screen(['windows-desktop', 'powershell-as-admin-window']);
    $self->open_powershell_as_admin if (match_has_tag('windows-desktop'));

    # Enter in the WSL prompt
    enter_cmd_slow("wsl");

    # We will install wsl_gui pattern from CLI now instead of firstboot, to make
    # it available in openSUSE too.
    become_root;
    zypper_call("install -t pattern wsl_gui");
    enter_cmd_slow "exit\n";


    # Check if wsl_gui has been installed properly
    $self->run_in_powershell(cmd => 'wsl /bin/bash -c "zypper -q se -i -t pattern wsl"');

    enter_cmd_slow "xeyes\n";
    assert_screen "wsl-xeyes-window-new";
    mouse_set(WIDTH/2, HEIGHT/2);
    assert_screen "wsl-xeyes-window-center";
}

1;