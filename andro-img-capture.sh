#!/bin/bash

# Log start time
echo "$(date): Starting photo capture and upload" >> /data/data/com.termux/files/home/photo_upload.log

# Define the directory where images will be saved
IMAGE_DIR="/data/data/com.termux/files/home"
# Define a temporary image file name
TIMESTAMP=$(date +%Y%m%d%H%M%S)  # Unique timestamp for each image
IMAGE_PATH="${IMAGE_DIR}/front_camera_image_${TIMESTAMP}.jpg"

# Function to capture photo with retries
capture_photo() {
    local attempts=5  # Number of attempts to capture the photo
    local count=0

    while [ $count -lt $attempts ]; do
        # Take a picture with the front camera (timeout after 30 seconds)
        timeout 30 termux-camera-photo -c 1 "$IMAGE_PATH"

        # Check if the photo was taken successfully
        if [ $? -eq 0 ]; then
            return 0  # Success
        fi

        echo "$(date): Attempt $((count + 1)): Failed to take photo. Retrying..." >> /data/data/com.termux/files/home/photo_upload.log
        count=$((count + 1))
        sleep 5  # Wait before retrying
    done

    return 1  # Failure after all attempts
}

# Call the function to capture the photo
capture_photo

# Check if the photo was taken successfully
if [ $? -ne 0 ]; then
    echo "$(date): Error: Failed to take photo after multiple attempts." >> /data/data/com.termux/files/home/photo_upload.log
    exit 1
fi

# Compress the image to reduce file size (using `jpegoptim`)
jpegoptim --max=80 "$IMAGE_PATH"
# Alternatively, use ImageMagick to compress (if jpegoptim isn't available)
# convert "$IMAGE_PATH" -quality 80 "$IMAGE_PATH"

# Check if compression succeeded
if [ $? -ne 0 ]; then
    echo "$(date): Error: Failed to compress image." >> /data/data/com.termux/files/home/photo_upload.log
    exit 1
fi

# Upload the image to Google Drive using rclone
rclone copy "$IMAGE_PATH" gdrive:termux

# Check if the upload was successful
if [ $? -ne 0 ]; then
    echo "$(date): Error: Failed to upload the image to Google Drive." >> /data/data/com.termux/files/home/photo_upload.log
    exit 1
else
    echo "$(date): Successfully uploaded $IMAGE_PATH to Google Drive." >> /data/data/com.termux/files/home/photo_upload.log
fi

# Optionally, delete the local image after upload to save space
rm "$IMAGE_PATH"

# Log completion
echo "$(date): Completed photo capture and upload." >> /data/data/com.termux/files/home/photo_upload.log

# Exit script
exit 0
