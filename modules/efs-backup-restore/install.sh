#!/usr/bin/env bash
#
# © Copyright 2021 Micro Focus or one of its affiliates.
# The only warranties for products and services of Micro Focus and its affiliates and licensors
# (“Micro Focus”) are set forth in the express warranty statements accompanying such products and
# services. Nothing herein should be construed as constituting an additional warranty. Micro Focus
# shall not be liable for technical or editorial errors or omissions contained herein. The informa-
# tion contained herein is subject to change without notice.
#
# Contains Confidential Information. Except as specifically indicated otherwise, a valid license is
# required for possession, use or copying. Consistent with FAR 12.211 and 12.212, Commercial
# Computer Software, Computer Software Documentation, and Technical Data for Commercial Items are
# licensed to the U.S. Government under vendor's standard commercial license.
#

set -e

# Locate the directory in which this script is located
readonly script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Move the bin files into /usr/local/bin
sudo cp "${script_path}"/bin/efs_backup_restore.sh /usr/local/bin

# Change ownership and permissions
sudo chmod +x /usr/local/bin/efs_backup_restore.sh