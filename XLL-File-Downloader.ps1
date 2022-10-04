# X Labs Launcher - File Downloader (XLL-File-Downloader)
# Created by: JoelColby (Joel#4740)
# Version: 1.0 (October 4, 2022)
# License: MIT License
# Repository: https://github.com/JoelColby/XLL-File-Downloader

# Set the window title and the progress preference (stops a progress bar from appearing when invoking web requests).
(Get-Host).UI.RawUI.WindowTitle = "XLL File Downloader (v1.0)"
${ProgressPreference} = 'SilentlyContinue'

# Obtain the current directory path of the script.
${CurrentDirectory} = Get-Location

########################################################################################################################
# Script Header
########################################################################################################################

# Write a fancy header to the console.
Write-Host "###################################################################" -ForegroundColor Red
Write-Host "#                                                                 #" -ForegroundColor Red
Write-Host "#                " -NoNewLine -ForegroundColor Red
Write-Host "X Labs Launcher - File Downloader" -NoNewLine
Write-Host "                #" -ForegroundColor Red
Write-Host "#                " -NoNewLine -ForegroundColor Red
Write-Host "Created by: JoelColby (Joel#4740)" -NoNewLine
Write-Host "                #" -ForegroundColor Red
Write-Host "#                           " -NoNewLine -ForegroundColor Red
Write-Host "Version 1.0" -NoNewLine
Write-Host "                           #" -ForegroundColor Red
Write-Host "#                                                                 #" -ForegroundColor Red
Write-Host "#                              " -NoNewLine -ForegroundColor Red
Write-Host "-----" -NoNewLine
Write-Host "                              #" -ForegroundColor Red
Write-Host "#                                                                 #" -ForegroundColor Red
Write-Host "#     " -NoNewLine -ForegroundColor Red
Write-Host "A script designed to download the files necessary to run" -NoNewLine
Write-Host "    #" -ForegroundColor Red
Write-Host "#  " -NoNewLine -ForegroundColor Red
Write-Host "the X Labs Launcher (https://github.com/XLabsProject/launcher)" -NoNewLine
Write-Host " #" -ForegroundColor Red
Write-Host "#                                                                 #" -ForegroundColor Red
Write-Host "###################################################################`n" -ForegroundColor Red

# Write the current working directory to the console.
Write-Host "Current Directory: " -NoNewLine
Write-Host "${CurrentDirectory}`n" -ForegroundColor Yellow

########################################################################################################################
# Step 1/4: Get the file listing JSON file from the X Labs master server.
########################################################################################################################

# Print visual section header.
Write-Host "###################################################################" -ForegroundColor Cyan
Write-Host "#        " -NoNewLine -ForegroundColor Cyan
Write-Host "Step 1/4 - Obtain File Listing from Master Server" -NoNewline
Write-Host "        #" -ForegroundColor Cyan
Write-Host "###################################################################`n" -ForegroundColor Cyan

Write-Host "Getting file listing from https://master.xlabs.dev/files.json..."

# Obtain the JSON file listing from the X Labs master server.
try {
    ${fileListing} = Invoke-WebRequest "https://master.xlabs.dev/files.json" | ConvertFrom-Json
} catch {
    # If an error is encountered when downloading the master server file listing, write the error to the console and exit.
    Write-Error "The following error was encountered when downloading the master server file listing: ${_}`n"
    Write-Host "The error above has occurred. Press any key on your keyboard to exit the script..." -NoNewLine
    Read-Host
    throw "The following error was encountered when downloading the master server file listing: ${_}"
}

# Extract the count of the file listing and write it to the console.
${numFiles} = ${fileListing}.Count
Write-Host "File listing received. ${numFiles} file(s) are in the listing.`n"

########################################################################################################################
# Step 2/4: Check if the files from the file listing are already present in an "xlabs" folder in the current directory.
########################################################################################################################

# Print visual section header.
Write-Host "###################################################################" -ForegroundColor Cyan
Write-Host "#               " -NoNewLine -ForegroundColor Cyan
Write-Host "Step 2/4 - Check for Existing Files" -NoNewline
Write-Host "               #" -ForegroundColor Cyan
Write-Host "###################################################################`n" -ForegroundColor Cyan

Write-Host "Checking for ${numFiles} file(s) from the file listing in: ${CurrentDirectory}...`n"

# Initialize a file counter and an empty list that will contain files that need to be downloaded.
${counter} = 0
[System.Collections.ArrayList]${downloadList}= @()

# Iterate over each file in the file listing obtained from the master server.
foreach (${fileEntry} in ${fileListing}) {
    # Each entry contains 3 objects representing the file name, file size, and file hash. Pull out these objects.
    ${entryName} = ${fileEntry}[0]
    ${entrySize} = ${fileEntry}[1]
    ${entryHash} = ${fileEntry}[2]

    # Increment the current file counter.
    ${counter} += 1

    # Initialize a variable containing the full file path. We will store the
    # xlabs.exe file in the current directory.
    if (${entryName} -eq "xlabs.exe") {
        ${file} = "${CurrentDirectory}\${entryName}"
    } else {
        ${file} = "${CurrentDirectory}\xlabs\data\${entryName}"
    }

    # Output the current file counter.
    Write-Host "[${counter}/${numFiles}] " -ForegroundColor White -NoNewLine
    Write-Host "File Check: " -ForegroundColor Magenta -NoNewLine
    Write-Host "${file}" -NoNewLine -ForegroundColor Yellow
    Write-Host ": " -NoNewLine

    # Verify if the path for the file is a valid path before continuing.
    if (Test-Path -Path ${file} -IsValid) {
        # Check if the file exists.
        if (Test-Path -Path ${file} -PathType Leaf) {
            # Grab the file size and file hash of the existing file.
            ${fileSize} = (Get-Item -Path ${file}).Length
            ${fileHash} = (Get-FileHash -Path ${file} -Algorithm SHA1).Hash

            # If the file size does not match the expected file size in the entry, then add it to the list of files to be downloaded.
            if (${fileSize} -ne ${entrySize}) {
                Write-Host "Unexpected file size" -ForegroundColor DarkRed
                [void]${downloadList}.Add(${fileEntry})
            } else {
                # If the file hash does not match the expected file hash in the entry, then add it to the list of files to be downloaded.
                if (${fileHash} -ne ${entryHash}) {
                    Write-Host "Unexpected file hash" -ForegroundColor DarkRed
                    [void]${downloadList}.Add(${fileEntry})
                } else {
                    # File name matches, file size matches, and file hash matches. So the file is found and does not need to be redownloaded.
                    Write-Host "File found" -ForegroundColor Green
                }
            }
        } else {
            # The file was not found, so we add it to the list of files to be downloaded.
            Write-Host "File not found" -ForegroundColor DarkRed
            [void]${downloadList}.Add(${fileEntry})
         }
    } else {
        # The path for this file is invalid. Write an error to the console and exit.
        Write-Error "Invalid file path: ${file}"
        Write-Host "The error above has occurred. Press any key on your keyboard to exit the script..." -NoNewLine
        Read-Host
        throw "Invalid file path: ${file}"
    }
}

# Extract the count of the download list and write it to the console.
${downloadFileCount} = ${downloadList}.Count
Write-Host "`nFile check complete. ${downloadFileCount} file(s) of the ${numFiles} file(s) in the file listing have been designated to be downloaded.`n"

########################################################################################################################
# Step 3/4: Download any designated files from the master server.
########################################################################################################################

# Print visual section header.
Write-Host "###################################################################" -ForegroundColor Cyan
Write-Host "#        " -NoNewLine -ForegroundColor Cyan
Write-Host "Step 3/4 - Download Files from the Master Server" -NoNewline
Write-Host "         #" -ForegroundColor Cyan
Write-Host "###################################################################`n" -ForegroundColor Cyan

# If the file count is zero, print that we are skipping this section. Otherwise, download the files from the downloadList.
if (${downloadFileCount} -eq 0) {
    Write-Host "There are no files to download. Skipping to the next step...`n"
} else {
    Write-Host "Downloading ${downloadFileCount} file(s) from the X Labs master server...`n"

    # Initialize a counter.
    ${counter} = 0

    # Iterate over each file in the download list.
    foreach (${fileEntry} in ${downloadList}) {
        # Each file entry contains 3 objects representing the file name, file size, and file hash. Pull out these objects.
        ${entryName} = ${fileEntry}[0]
        ${entrySize} = ${fileEntry}[1]
        ${entryHash} = ${fileEntry}[2]

        # Increment the current file counter.
        $counter += 1

        # Initialize a variable containing the full file path. We will store the
        # xlabs.exe file in the current directory.
        if (${entryName} -eq "xlabs.exe") {
            ${file} = "${CurrentDirectory}\${entryName}"
        } else {
            ${file} = "${CurrentDirectory}\xlabs\data\${entryName}"
        }

        # Store a nice file size that we can display to the user in the console.
        if (${entrySize} -lt 1024) {
            ${displaySize} = "${entrySize} bytes"
        } elseif ((${entrySize} / 1KB) -lt 1024) {
            ${displaySize} = [math]::Round((${entrySize} / 1KB), 2).ToString() + " KB"
        } elseif ((${entrySize} / 1MB) -lt 1024) {
            ${displaySize} = [math]::Round((${entrySize} / 1MB), 2).ToString() + " MB"
        } else {
            ${displaySize} = [math]::Round((${entrySize} / 1GB), 2).ToString() + " GB"
        }

        # Output the current file counter.
        Write-Host "[${counter}/${downloadFileCount}] " -ForegroundColor White -NoNewLine
        Write-Host "Downloading: " -ForegroundColor Cyan -NoNewLine
        Write-Host "${entryName} " -ForegroundColor Yellow -NoNewLine
        Write-Host "(${displaySize})..." 

        # Download the file from the X Labs master server, storing the file at the full file path specified above. The
        # -Force flag is used to force the creation of subdirectories if they do not exist.
        try {
            Invoke-WebRequest -Uri "https://master.xlabs.dev/data/${entryName}" -OutFile (New-Item -Path ${file} -Force)
        } catch {
            # If an error is encountered when downloading a specific file, write the error to the console and exit.
            Write-Error "The following error was encountered when downloading the file ${entryName}: ${_}`n"
            Write-Host "The error above has occurred. Press any key on your keyboard to exit the script..." -NoNewLine
            Read-Host
            throw "The following error was encountered when downloading the file ${entryName}: ${_}"
        }
    }

    # Write a message indicating that the files have finished downloading.
    Write-Host "`nFinished downloading ${downloadFileCount} file(s).`n"
}

########################################################################################################################
# Step 4/4: Verify that all X Labs files match the expected file size and file hash.
########################################################################################################################

# Print visual section header.
Write-Host "###################################################################" -ForegroundColor Cyan
Write-Host "#                " -NoNewLine -ForegroundColor Cyan
Write-Host "Step 4/4 - Verify All X Labs Files" -NoNewline
Write-Host "               #" -ForegroundColor Cyan
Write-Host "###################################################################`n" -ForegroundColor Cyan

Write-Host "Verifying ${numFiles} file(s) from the file listing in: ${CurrentDirectory}...`n"

# Initialize a counter.
${counter} = 0

# Iterate over each file in the file listing.
foreach (${fileEntry} in ${fileListing}) {
    # Each file entry contains 3 objects representing the file name, file size, and file hash. Pull out these objects.
    ${entryName} = ${fileEntry}[0]
    ${entrySize} = ${fileEntry}[1]
    ${entryHash} = ${fileEntry}[2]

    # Increment the current file counter.
    $counter += 1

    # Initialize a variable containing the full file path. We will store the
    # xlabs.exe file in the current directory.
    if (${entryName} -eq "xlabs.exe") {
        ${file} = "${CurrentDirectory}\${entryName}"
    } else {
        ${file} = "${CurrentDirectory}\xlabs\data\${entryName}"
    }
    
    # Output the current file counter.
    Write-Host "[${counter}/${numFiles}] " -ForegroundColor White -NoNewLine
    Write-Host "File Verify: " -ForegroundColor Red -NoNewLine
    Write-Host "${file}" -NoNewLine -ForegroundColor Yellow
    Write-Host ": " -NoNewLine

    # Verify if the path for the file is a valid path before continuing.
    if (Test-Path -Path ${file} -IsValid) {
        # Check if the file exists.
        if (Test-Path -Path ${file} -PathType Leaf) {
            # Check if the file size of the downloaded file matches the expected file size for the entry.
            ${fileSize} = (Get-Item -Path ${file}).Length
            if (${fileSize} -ne ${entrySize}) {
                Write-Error "File size of ${entryName} does not match the expected file size.`nCalculated File Size: ${fileSize}`nExpected File Size: ${entrySize}`n"
                Write-Host "The error above has occurred. Press any key on your keyboard to exit the script..." -NoNewLine
                Read-Host
                throw "File size of ${entryName} does not match the expected file size.`nCalculated File Size: ${fileSize}`nExpected File Size: ${entrySize}"
            }

            # Verify that the SHA1 hash of the downloaded file matches the expected hash for the entry.
            ${fileHash} = (Get-FileHash -Path ${file} -Algorithm SHA1).Hash
            if (${fileHash} -ne ${entryHash}) {
                # Write an error message to the console, and then exit the script with the same error message when any key is pressed.
                Write-Error "Calculated SHA1 hash of file ${entryName} does not match the expected hash.`nCalculated Hash: ${fileHash}`nExpected Hash: ${entryHash}`n"
                Write-Host "The error above has occurred. Press any key on your keyboard to exit the script..." -NoNewLine
                Read-Host
                throw "Calculated SHA1 hash of file ${entryName} does not match the expected hash.`nCalculated Hash: ${fileHash}`nExpected Hash: ${entryHash}"
            }
        } else {
            # The file was not found. At this stage the file should be downloaded, so it may have been quarantined by
            # an anti-virus program. Write an error to the console and exit.
            Write-Error "File was not found but should be present. Try restarting the script. File: ${file}`n"
            Write-Host "The error above has occurred. Press any key on your keyboard to exit the script..." -NoNewLine
            Read-Host
            throw "File was not found but should be present. Try restarting the script. File: ${file}"
        }
    } else {
        # The path for this file is invalid. Write an error to the console and exit.
        Write-Error "Invalid file path: ${file}`n"
        Write-Host "The error above has occurred. Press any key on your keyboard to exit the script..." -NoNewLine
        Read-Host
        throw "Invalid file path: ${file}"
    }

    # Append a "Verified" message at the end of the file, because at this stage
    # we have verified the file name, file size, and file hash all match.
     Write-Host "Verified" -ForegroundColor Green
}

# Write a message to the console indicating that all files have been verified.
Write-Host "`nFinished verifying ${numFiles} file(s).`n"

########################################################################################################################
# Display end-of-script messages and exit on keypress.
########################################################################################################################

Write-Host "###################################################################`n" -ForegroundColor Cyan

Write-Host "The script has completed. Files can be found in: " -NoNewLine
Write-Host "${CurrentDirectory}\xlabs`n" -ForegroundColor Yellow

Write-Host "A copy of the stable X Labs Launcher has also been downloaded to: " -NoNewline
Write-Host "${CurrentDirectory}\xlabs.exe`n" -ForegroundColor Yellow

Write-Host "You can now move the `"xlabs`" folder to local AppData and run the X Labs Launcher."
Write-Host "Your local AppData folder can be found at: " -NoNewline
Write-Host "${env:LOCALAPPDATA}`n" -ForegroundColor Red

Write-Host "NOTE: The AppData folder is a hidden folder by default.`n      Unhide it in File Explorer by selecting: View -> Show -> Hidden items`n" -ForegroundColor Yellow

Write-Host "Press any key on your keyboard to exit the script..." -ForegroundColor Green
Read-Host