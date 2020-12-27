#!/usr/bin/env bash

yellow=`tput setaf 3`
reset=`tput sgr0`

resource_options=("daemonset" "deployment")

# First Menu - Which Resource
echo "Select from which resource:"
select res_opt in "${resource_options[@]}"
do
	echo "Selected option: ${yellow}$res_opt${reset}."

	cnv_res="oc get ${res_opt}"
	cnv_res_filter="-n openshift-cnv | awk ' { print \$1 } ' | tail -n +2"

	cnv_image_choices="${cnv_res} ${cnv_res_filter}"
	cnv_image_choices=`eval "$cnv_image_choices"`

	choices_array=( $cnv_image_choices )

	# Second Menu - Which image in the resource
	echo "Select the image you would like to check:"
	select opt in "${choices_array[@]}"
	do
	    echo "Selected option: ${yellow}$opt${reset}. Extracting version..."

	    pre="oc get ${res_opt} -n openshift-cnv"
	    suff="-oyaml | awk '/image:/' | tail -1"
	    temp="${pre} ${opt} ${suff}"

	    image=`eval "$temp"`

		# Extract container's sha256
		container_sha=${image##*container-native-virtualization/}

		# Concatenate docker path and sha256 value
		docker="docker://registry-proxy.engineering.redhat.com/rh-osbs/container-native-virtualization-"
		docker_img="${docker}${container_sha}"

		skop="skopeo inspect"
		extract_from_proxy="${skop} '${docker_img}'"

		version_cmd="| jq -r '.Labels.version','.Labels.release' |xargs | sed 's/ /-/g'"
		version_cmd="${extract_from_proxy} ${version_cmd}"

		version_num=`eval "$version_cmd"`

		# Get version
		echo "${yellow}$opt ${reset}version is: ${yellow}${version_num}${reset}"
	done
done