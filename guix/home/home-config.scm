(use-modules (gnu)
	     (gnu home)
	     (gnu home services shells)
	     (gnu home services dotfiles)
	     (gnu packages gnupg)
	     (gnu home services gnupg))

(home-environment
 (services (list (service home-dotfiles-service-type
			  (home-dotfiles-configuration
			   (directories '("../../files"))))
		 (service home-gpg-agent-service-type
			  (home-gpg-agent-configuration
			   (pinentry-program
			    (file-append pinentry-emacs "/bin/pinentry-emacs"))
			   (ssh-support? #t))))))
