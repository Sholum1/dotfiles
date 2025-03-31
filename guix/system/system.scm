;; This is an operating system configuration generated
;; by the graphical installer.
;;
;; Once installation is complete, you can learn and modify
;; this file to tweak the system configuration, and pass it
;; to the 'guix system reconfigure' command to effect your
;; changes.


;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu)
	     (gnu    system   shadow)
	     (gnu    system   accounts)
	     (gnu    services virtualization)
	     (nongnu system   linux-initrd)
	     (nongnu packages linux))
	     
(use-service-modules containers cups desktop networking ssh xorg)

(operating-system
  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware))
  (locale "en_US.utf8")
  (timezone "America/Sao_Paulo")
  (keyboard-layout (keyboard-layout "br" "abnt2"))
  (host-name "Sholum")

  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "Sholum")
                  (comment "Wallysson")
                  (group "users")
                  (home-directory "/home/Sholum")
                  (supplementary-groups '("wheel" "netdev" "audio" "video" "cgroup" "kvm" "libvirt")))
                %base-user-accounts))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages (append (list (specification->package "emacs")
			  (specification->package "efibootmgr"))
		    %base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (append (list

                 ;; To configure OpenSSH, pass an 'openssh-configuration'
                 ;; record as a second argument to 'service' below.
                 (service openssh-service-type)
                 (service tor-service-type)
                 (service cups-service-type)
		 (service iptables-service-type)
		 (service rootless-podman-service-type
			  (rootless-podman-configuration
			   (subgids
			    (list (subid-range (name "Sholum"))))
			   (subuids
			    (list (subid-range (name "Sholum"))))))
		 (simple-service 'podman-subuid-subgid
				 subids-service-type
				 (subids-extension
				  (subgids
				   (list (subid-range (name "Sholum"))))
				  (subuids
				   (list (subid-range (name "Sholum"))))))
		 (service libvirt-service-type)
		 (set-xorg-configuration
		  (xorg-configuration (keyboard-layout keyboard-layout))))

           ;; This is the default list of services we
           ;; are appending to.
           (modify-services %desktop-services
			    (guix-service-type config =>
					       (guix-configuration
						(inherit config)
						(substitute-urls
						 (append (list "https://substitutes.nonguix.org")
							 %default-substitute-urls))
						(authorized-keys
						 (append (list (local-file "./signing-key.pub"))
							 %default-authorized-guix-keys)))))))
  (bootloader (bootloader-configuration
                (bootloader grub-efi-removable-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/home")
                         (device (uuid
                                  "72267a24-e934-46d8-8a17-5c89ab622c7f"
                                  'ext4))
                         (type "ext4")
			 (flags '(no-atime)))
                       (file-system
                         (mount-point "/")
                         (device (uuid
                                  "4079f732-9855-4a4a-893e-2642664fb301"
                                  'ext4))
                         (type "ext4")
			 (flags '(no-atime)))
                       (file-system
                         (mount-point "/home/Sholum/sata")
                         (device (uuid
                                  "f8b62d74-b863-48fa-a048-374ed0a67e5a"
                                  'ext4))
                         (type "ext4")
			 (flags '(no-atime)))
		       (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "55CD-33E5"
                                       'fat32))
                         (type "vfat"))
		       %base-file-systems)))
