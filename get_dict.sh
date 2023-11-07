#!/bin/bash

# Define the directory where files will be stored
dir="vishvas_dicts"

echo "Starting the script..."

# Create the directory if it doesn't exist
if [ ! -d "$dir" ]; then
  echo "Creating directory '$dir'..."
  mkdir "$dir"
fi

# The URL of the main markdown file containing the list of markdown files
main_md_url="https://raw.githubusercontent.com/indic-dict/stardict-index/master/dictionaryIndices.md"

echo "Fetching the main markdown file..."
# Fetch the main markdown file and extract the URLs to the other markdown files
# The grep pattern is adjusted to match URLs within angle brackets
curl -s $main_md_url | grep -o '<https://raw.githubusercontent.com/[^>]*>' | tr -d '<>' > md_links.txt

echo "Extracting markdown file links..."
# Loop through the list of markdown files
while IFS= read -r md_url; do
    echo "Processing markdown file: $md_url"
    
    # Fetch each markdown file and extract file links
    # The grep pattern here is for extracting GitHub URLs that are direct links to files
    curl -s $md_url | grep -o 'https://github.com/indic-dict/[^\"]*\.tar\.gz' > file_links.txt

    echo "Downloading files linked in the markdown..."
    # Loop through the file links and download each file
    while IFS= read -r file_url; do
        # Convert the GitHub blob URL to a raw URL if necessary
        raw_file_url=$(echo $file_url | sed 's/github\.com\/indic-dict\/stardict-sanskrit\/raw/raw.githubusercontent.com\/indic-dict\/stardict-sanskrit/')
        # Extract the file name from the URL
        file_name=$(basename "$raw_file_url")
        # Create a directory for the tar file
        file_dir="$dir/${file_name%.tar.gz}"
        mkdir -p "$file_dir"
        echo "Downloading $file_name to $file_dir"
        # Download the file and store it in the specified directory, overwriting if it exists
        curl -L "$raw_file_url" -o "$file_dir/$file_name"

        echo "Unzipping $file_name..."
        # Unzip the file into its own directory and then delete the archive
        tar -xzf "$file_dir/$file_name" -C "$file_dir"
        rm "$file_dir/$file_name"

        echo "$file_name unzipped and removed."
    done < file_links.txt
done < md_links.txt

echo "Cleaning up temporary files..."
# Clean up
rm md_links.txt file_links.txt

echo "Script completed. Files are downloaded and unzipped in '$dir'."
