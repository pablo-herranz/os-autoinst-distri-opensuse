# SUSE's openQA tests
#
# Copyright 2012-2021 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Update Windows base image
# Maintainer: qa-c <qa-c@suse.de>

use Mojo::Base qw(windowsbasetest);
use testapi;

sub dowload_and_run_script {
    my ($self, $script) = @_;

    my $timeout = ($script =~ "UpdateInstall.ps1" ? 3600 : 60);
    my $vbs_url = data_url("wsl/$script");
    $self->open_powershell_as_admin;
    $self->run_in_powershell(cmd => "Invoke-WebRequest -Uri \"$vbs_url\" -OutFile \"\$env:TEMP\\$script\"");
    $self->run_in_powershell(cmd => "Set-ExecutionPolicy Bypass -Scope CurrentUser -Force");
    $self->run_in_powershell(
        cmd => "cd \$env:TEMP; .\\$script",
        code => sub {
            die("The $script script finished unespectedly or timed out...")
              unless wait_serial('0', timeout => $timeout);
        }
    );
}

sub run {
    my $self = shift;

    $self->dowload_and_run_script(script => "UpdateInstall.ps1");
    save_screenshot;
    $self->reboot_or_shutdown(1);
    while (defined(check_screen('windows-updating', 60))) {
        bmwqemu::diag("Applying updates while shutting down the machine...");
    }
    $self->wait_boot_windows;

    $self->dowload_and_run_script(script => "SetWallpaper.ps1");
    save_screenshot;
    # Shutdown
    $self->reboot_or_shutdown;
}

1;
