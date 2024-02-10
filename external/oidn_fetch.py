# Zhenyi, Stanford, 2024
import subprocess
import sys
import os
def install(package):
    subprocess.check_call([sys.executable, "-m", "pip", "install", package,"--user"])

# Check and install 'requests' if necessary
try:
    import requests
except ImportError:
    print("Package 'requests' not found. Installing...")
    install("requests")
    install("chardet")
    import requests

# Check and install 'tqdm' if necessary
try:
    from tqdm import tqdm
except ImportError:
    print("Package 'tqdm' not found. Installing...")
    install("tqdm")
    from tqdm import tqdm

try:
    import tarfile
except ImportError:
    print("Package 'tarfile' not found. Installing...")
    install("tarfile")
    import tarfile

try:
    import platform
except ImportError:
    print("Package 'platform' not found. Installing...")
    install("platform")
    import platform
    
def download_latest_release(repo_owner, repo_name):
    # GitHub API URL for the latest release
    api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases/latest"
    
    # Fetch the latest release data
    response = requests.get(api_url)
    response.raise_for_status()  # Check for errors
    release_data = response.json()
    
    # Assuming you want to download the first asset from the latest release
    asset = release_data['assets'][0]
   
    platform_name = platform.system()
    if 'windows' in platform_name:
        platform_name = 'windows'
    elif 'Darwin' in platform_name:
        platform_name = 'macos'
    elif 'Linux' in platform_name:
        platform_name = 'linux'
        
    for asset in release_data['assets']:
        if platform_name in asset['name']:
            
            download_url = asset['browser_download_url']
            file_name = asset['name']
            folder_name = file_name.replace('.tar.gz','')
            if os.path.exists(folder_name):
                return folder_name
            # Download the file with a progress bar
            response = requests.get(download_url, stream=True)
            total_size_in_bytes = int(response.headers.get('content-length', 0))
            block_size = 1024  # 1 Kibibyte
            progress_bar = tqdm(total=total_size_in_bytes, unit='iB', unit_scale=True)
            
            with open(file_name, 'wb') as file:
                for data in response.iter_content(block_size):
                    progress_bar.update(len(data))
                    file.write(data)
            progress_bar.close()

            if total_size_in_bytes != 0 and progress_bar.n != total_size_in_bytes:
                print("ERROR, something went wrong")
            else:
                print(f"Download completed: {file_name}")
            
            unzip_tar_file(file_name)
            os.remove(file_name)
            return folder_name
        
def unzip_tar_file(file_name):
    folder_name = set()  # Use a set to avoid duplicate folder names

    if file_name.endswith('.tar') or file_name.endswith('.tar.gz') or file_name.endswith('.tgz'):
        with tarfile.open(file_name) as tar:
            # Extract all the contents into the current directory
            tar.extractall()
            
            # Iterate through the tar archive members
            for member in tar.getmembers():
                # Check if the member is a directory
                if member.isdir():
                    # Extract the top-level directory name from the member's name
                    top_level_dir = member.name.split('/')[0]
                    folder_name.add(top_level_dir)

        print(f"Extracted {file_name} into folders: {', '.join(folder_name)}")
    else:
        print("The file is not a .tar, .tar.gz, or .tgz file and cannot be extracted.")
        return []

def main():
    folder_name = download_latest_release('OpenImageDenoise', 'oidn')
    return folder_name