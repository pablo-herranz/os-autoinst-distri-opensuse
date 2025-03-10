# SUSE's openQA tests
#
# Copyright 2016-2018 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Windows 10 installation test module
#    modiffied (only win10 drivers) iso from https://fedoraproject.org/wiki/Windows_Virtio_Drivers is needed
#    Works only with CDMODEL=ide-cd and QEMUCPU=host or core2duo (maybe other but not qemu64)
# Maintainer: Jozef Pupava <jpupava@suse.com>

use base "windowsbasetest";
use strict;
use warnings;

use testapi;

sub prepare_win11 {
    # Change some regedit values to skip system requirements check
    send_key 'shift-f10';
    assert_screen 'windows-install-cmd';
    type_string "reg add HKEY_LOCAL_MACHINE\\SYSTEM\\Setup /v LabConfig\n";
    type_string "reg add HKEY_LOCAL_MACHINE\\SYSTEM\\Setup\\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1\n";
    type_string "reg add HKEY_LOCAL_MACHINE\\SYSTEM\\Setup\\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1\n";
    type_string "reg add HKEY_LOCAL_MACHINE\\SYSTEM\\Setup\\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1\n";
    type_string "exit\n";
}

sub run {

    my $self = shift;

    if (get_var('UEFI')) {
        while (check_screen('windows-boot', timeout => 5)) {
            send_key 'spc';
            record_info('SPC', 'Space key pressed');
        }    # boot from CD or DVD
    }

    record_info('Windows firstboot', 'Starting Windows for the first time');
    wait_still_screen stilltime => 60, timeout => 300;
    # When starting Windows for the first time, several screens or pop-ups may appear
    # in a different order. We'll try to handle them until the desktop is shown
    assert_screen(['windows-edge-welcome', 'windows-desktop', 'windows-edge-decline', 'networks-popup-be-discoverable', 'windows-start-menu', 'windows-qemu-drivers', 'windows-setup-browser'], timeout => 120);
    while (not match_has_tag('windows-desktop')) {
        assert_and_click 'windows-edge-welcome' if (match_has_tag 'windows-edge-welcome');
        assert_and_click 'windows-setup-browser' if (match_has_tag 'windows-setup-browser');
        assert_and_click 'network-discover-yes' if (match_has_tag 'networks-popup-be-discoverable');
        assert_and_click 'windows-edge-decline' if (match_has_tag 'windows-edge-decline');
        assert_and_click 'windows-start-menu' if (match_has_tag 'windows-start-menu');
        assert_and_click 'windows-qemu-drivers' if (match_has_tag 'windows-qemu-drivers');
        wait_still_screen stilltime => 15, timeout => 60;
        assert_screen(['windows-edge-welcome', 'windows-desktop', 'windows-edge-decline', 'networks-popup-be-discoverable', 'windows-start-menu', 'windows-qemu-drivers', 'windows-setup-browser'], timeout => 120);
    }

    # These commands disable notifications that Windows shows randomly and
    # make our windows lose focus
    $self->open_powershell_as_admin;
    $self->run_in_powershell(cmd => 'reg add "HKLM\Software\Policies\Microsoft\Windows" /v Explorer');
    $self->run_in_powershell(cmd => 'reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v DisableNotificationCenter /t REG_DWORD /d 1');
    $self->run_in_powershell(cmd => 'reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0');
    record_info 'Port close', 'Closing serial port...';
    $self->run_in_powershell(cmd => '$port.close()', code => sub { });
    $self->run_in_powershell(cmd => 'exit', code => sub { });
}

1;
