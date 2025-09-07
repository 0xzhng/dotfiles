(require 'package)

(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)

(setq use-package-always-ensure t)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-message t)

(use-package obsidian
  :custom
  (obsidian-directory "~/notes")
  :config
  (global-obsidian-mode t))

(define-key global-map (kbd "C-c o f") 'obsidian-follow-link-at-point)
(define-key global-map (kbd "C-c o l") 'obsidian-insert-link)
(define-key global-map (kbd "C-c o n") 'obsidian-new-note)
(define-key global-map (kbd "C-c o s") 'obsidian-search)

(use-package vertico
  :init
  (vertico-mode))

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode))

(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles basic)))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
