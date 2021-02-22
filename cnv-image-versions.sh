#!/usr/bin/env bash

YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
RESET=$(tput sgr0)
OCP_CNV="openshift-cnv"

RESOURCE_OPTIONS=("daemonset" "deployment")

function extract_version {
  # Extract version from image
  image="oc get \$1 -n ${OCP_CNV} \$2 -oyaml | awk '/image:/' | tail -1"
  image=$(eval "$image")

  # Extract container's sha256
  container_sha=${image##*container-native-virtualization/}

  # Concatenate docker path and sha256 value
  docker_img="docker://registry-proxy.engineering.redhat.com/rh-osbs/container-native-virtualization-${container_sha}"

  extract_from_proxy="skopeo inspect '${docker_img}'"

  # Get version
  version_num=$(eval "${extract_from_proxy} | jq -r '.Labels.version','.Labels.release' |xargs | sed 's/ /-/g'")

  echo "${YELLOW}$2 ${RESET}version is: ${YELLOW}${version_num}${RESET}"
}

if [[ $* == '--all' || $* == '--a' ]]
then
  echo "Extracting ${RED}ALL${RESET} the images and their versions, Please wait this may take a couple of minutes..."	
  for resource in ${RESOURCE_OPTIONS[@]}
  do
    cnv_image_choices="oc get ${resource} -n ${OCP_CNV} | awk ' { print \$1 } ' | tail -n +2"
    cnv_image_choices=$(eval "$cnv_image_choices")
    for image in ${cnv_image_choices[@]}
    do
      version_results="$version_results""\n""$(extract_version "$resource" "$image")"
    done
  done
  echo -e "$version_results"

else
  # First Menu - Which Resource
  echo "Select from which resource:"
  select res_opt in "${RESOURCE_OPTIONS[@]}"
  do
    echo "Selected option: ${YELLOW}$res_opt${RESET}."

    cnv_image_choices="oc get ${res_opt} -n ${OCP_CNV} | awk ' { print \$1 } ' | tail -n +2"
    cnv_image_choices=$(eval "$cnv_image_choices")

    choices_array=( ${cnv_image_choices} )

    # Second Menu - Which image in the resource
    echo "Select the image you would like to extract its version:"
    select img_opt in "${choices_array[@]}"
    do
      echo "Selected option: ${YELLOW}$img_opt${RESET}. Extracting version..."

      version_result="$(extract_version "$res_opt" "$img_opt")"
      echo $version_result
    done
  done
fi
