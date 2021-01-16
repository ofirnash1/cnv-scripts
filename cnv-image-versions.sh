#!/usr/bin/env bash

YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)
OCP_CNV="openshift-cnv"

RESOURCE_OPTIONS=("daemonset" "deployment")

# First Menu - Which Resource
echo "Select from which resource:"
select res_opt in "${RESOURCE_OPTIONS[@]}"
do
  echo "Selected option: ${YELLOW}$res_opt${RESET}."

  cnv_image_choices="oc get ${res_opt} -n ${OCP_CNV} | awk ' { print \$1 } ' | tail -n +2"
  cnv_image_choices=$(eval "$cnv_image_choices")

  choices_array=( ${cnv_image_choices} )

  # Second Menu - Which image in the resource
  echo "Select the image you would like to check:"
  select opt in "${choices_array[@]}"
  do
    echo "Selected option: ${YELLOW}$opt${RESET}. Extracting version..."

    image="oc get ${res_opt} -n ${OCP_CNV} ${opt} -oyaml | awk '/image:/' | tail -1"
    image=$(eval "$image")

    # Extract container's sha256
    container_sha=${image##*container-native-virtualization/}

    # Concatenate docker path and sha256 value
    docker_img="docker://registry-proxy.engineering.redhat.com/rh-osbs/container-native-virtualization-${container_sha}"

    extract_from_proxy="skopeo inspect '${docker_img}'"

    # Get version
    version_num=$(eval "${extract_from_proxy} | jq -r '.Labels.version','.Labels.release' |xargs | sed 's/ /-/g'")

    echo "${YELLOW}$opt ${RESET}version is: ${YELLOW}${version_num}${RESET}"
  done
done
