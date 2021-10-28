#!/bin/bash
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


# Global Defaults
common_mount_location="/mnt/efs-mount-point"
declare -A fusion_svc_common_points=(["reporting-svc"]="reporting" ["fusion-user-management"]="investigate/mgmt/db" ["fusion-metadata-web-app"]="fusion/theme" ["fusion-dashboard-web-app"]="fusion/widget-store" ["fusion-metadata-rethinkdb"]="investigate/search/rethinkdb" )
declare -A svc_common_points=(["reporting-svc"]="reporting" ["fusion-user-management"]="investigate/mgmt/db" ["fusion-metadata-rethinkdb"]="investigate/search/rethinkdb" )

svc_common="false"
fusion_svc_common="false"
restore_folder="" 
final_mount_points=()
final_pods=()

confirm() {
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

directory_exists() {
dir="$@"  
if [ -d $dir ];then true; else false; fi
}

sync_to_restore_directory() {
    pv_mount_paths=($final_mount_points)
    deployments=($final_pods)
    for i in "${!pv_mount_paths[@]}"; do
        if directory_exists "$common_mount_location/$restore_folder/${pv_mount_paths[i]}/backup";then
        latest_backup=$(ls -dtr1 $common_mount_location/$restore_folder/${pv_mount_paths[i]}/backup/* | tail -1)
        sudo rsync -avrHAXS $latest_backup/ $common_mount_location/${pv_mount_paths[i]}/restore
        else
         echo "Failed to find backup directory for ${deployments[i]}. Exiting"
         exit 1
        fi  
    done
    echo "Sync to restore completed successfully for ${deployments[@]}"
}

entrypoint() {
    while getopts "r:sf" OPT; do
        case "$OPT" in
        s)
            svc_common="true"
            ;;
        r)
            custom_restore_dir=${OPTARG}
            ;;
        f)
            fusion_svc_common="true"
            ;;
        *)
            echo "Usage: $0 [-s|-f service type OPTIONAL] [-r restore folder name OPTIONAL]" >&2
            exit 1
            ;;
        esac
    done

    if [ -n "${custom_restore_dir}" ]; then
        restore_folder=${custom_restore_dir}
        else
        if directory_exists "$common_mount_location/aws-backup-restore*";then 
        restore_folder=$(basename $( ls -dtr1 $common_mount_location/aws-backup-restore* | tail -1 ))
        else
         echo "No restore directory found in Mount Location"
         exit 1
        fi    
    fi

     if $fusion_svc_common; then
        final_mount_points=${fusion_svc_common_points[@]}
        final_pods="${!fusion_svc_common_points[@]}"
    elif  $svc_common; then
        final_mount_points=${svc_common_points[@]}
        final_pods="${!svc_common_points[@]}"
    else
        echo "No service type specified. Defaulting to All Pods in Service-Common EFS."
        final_mount_points=${fusion_svc_common_points[@]}
        final_pods="${!fusion_svc_common_points[@]}"                                
    fi

    echo "You are about to sync to restore directories of: " ${final_pods[@]}

    confirm && sync_to_restore_directory
}

entrypoint "$@"
