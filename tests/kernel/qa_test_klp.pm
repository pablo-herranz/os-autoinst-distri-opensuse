# SUSE's openQA tests
#
# Copyright 2017-2019 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Package: autoconf automake gcc git-core make
# Summary: Tests for kernel live patching infrastructure
# Maintainer: Ondřej Súkup <osukup@suse.cz>

use strict;
use warnings;
use File::Basename 'basename';

use base 'opensusebasetest';
use testapi;
use serial_terminal 'select_serial_terminal';
use utils;
use registration;
use version_utils 'is_sle';
use transactional;
use package_utils;

sub run {
    if (get_var('AZURE')) {
        record_info("Azure don't have kGraft/LP infrastructure");
        return;
    }

    my $git_repo = get_required_var('QA_TEST_KLP_REPO');
    my $dir = basename($git_repo);
    $dir =~ s/\.git$//;

    (is_sle(">12-sp1") || !is_sle) ? select_serial_terminal() : select_console('root-console');

    add_suseconnect_product("sle-sdk") if (is_sle('<12-SP5'));
    install_package('autoconf automake gcc git make');

    if (script_run('[ -d /lib/modules/$(uname -r)/build ]') != 0) {
        my $devel_pack = 'kernel-devel';

        if (check_var('SLE_PRODUCT', 'slert')) {
            $devel_pack = 'kernel-devel-rt';
        }

        # Force recommended packages to pull in kernel-default-devel, etc.
        install_package("--recommends $devel_pack", trup_continue => 1);
    }

    reboot_on_changes;

    assert_script_run('git config --global http.sslVerify false');
    assert_script_run('git clone ' . $git_repo);
    assert_script_run("cd $dir");
    record_info('qa_test_klp', script_output("git show | tee"));
    record_info('bats', script_output("which bats 2>&1", proceed_on_failure => 1));
    assert_script_run("./run.sh", 2760);
}

1;

=head1 Example configuration

=head2 QA_TEST_KLP_REPO

Git repository for kernel live patching infrastructure tests.
QA_TEST_KLP_REPO=https://github.com/SUSE/qa_test_klp.git

=cut
