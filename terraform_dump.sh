#!/bin/bash

output_file="terraform_files_contents.txt"
echo "Collecting Terraform files to $output_file..."
> "$output_file"

# Ask for the base directory
echo "Enter the path to the directory containing the 'workspace' folder:"
echo "For example, if your files are in /home/ubuntu/workspace/... enter /home/ubuntu"
read -r base_dir

if [ -z "$base_dir" ]; then
  echo "No directory provided. Will try current directory."
  base_dir="."
fi

# List of files to find
files=(
  "terraform/addons.tf"
  "terraform/cleanup.sh"
  "terraform/eks.tf"
  "terraform/fsx-for-lustre.tf"
  "terraform/iam_policies.tf"
  "terraform/install.sh"
  "terraform/main.tf"
  "terraform/outputs.tf"
  "terraform/slinky_pre_req.tf"
  "terraform/slinky.tf"
  "terraform/variables.tf"
  "terraform/versions.tf"
  "terraform/vpc.tf"
)

# Also check the fsx-for-lustre directory
echo -e "\n\n==============================================" >> "$output_file"
echo "Directory: terraform/fsx-for-lustre" >> "$output_file"
echo "==============================================" >> "$output_file"

fsx_dir="$base_dir/terraform/fsx-for-lustre"
if [ -d "$fsx_dir" ]; then
  echo "Listing files in the fsx-for-lustre directory:" >> "$output_file"
  ls -la "$fsx_dir" >> "$output_file" 2>&1
  
  # If there are .tf files in this directory, include them too
  find "$fsx_dir" -name "*.tf" | while read -r fsxfile; do
    echo -e "\n\n==============================================" >> "$output_file"
    echo "File: $fsxfile" >> "$output_file"
    echo "==============================================" >> "$output_file"
    cat "$fsxfile" >> "$output_file" 2>&1
  done
else
  echo "Directory not found: $fsx_dir" >> "$output_file"
fi

# Process each file
for file in "${files[@]}"; do
  full_path="$base_dir/$file"
  echo -e "\n\n==============================================" >> "$output_file"
  echo "File: $file" >> "$output_file"
  echo "==============================================" >> "$output_file"
  
  if [ -f "$full_path" ]; then
    cat "$full_path" >> "$output_file" 2>&1
  else
    echo "File not found: $full_path" >> "$output_file"
  fi
done

echo "Done. All file contents have been collected in $output_file"
echo "You can view the file with: less $output_file"
