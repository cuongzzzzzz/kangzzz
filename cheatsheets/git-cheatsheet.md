# Git Cheatsheet - Hướng Dẫn Lệnh Chi Tiết

## 📋 Mục Lục
1. [Cài đặt và Cấu hình](#cài-đặt-và-cấu-hình)
2. [Khởi tạo Repository](#khởi-tạo-repository)
3. [Các lệnh cơ bản](#các-lệnh-cơ-bản)
4. [Quản lý Branch](#quản-lý-branch)
5. [Merge và Rebase](#merge-và-rebase)
6. [Quản lý Remote](#quản-lý-remote)
7. [Stash và Clean](#stash-và-clean)
8. [Git Hooks](#git-hooks)
9. [Git Submodules](#git-submodules)
10. [Git LFS](#git-lfs)
11. [Troubleshooting](#troubleshooting)
12. [Git Workflows](#git-workflows)
13. [Git Tools và Integrations](#git-tools-và-integrations)
14. [Best Practices](#best-practices)

---

## 🚀 Cài đặt và Cấu hình

### Cài đặt Git
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install git

# CentOS/RHEL
sudo yum install git
# hoặc
sudo dnf install git

# macOS
brew install git

# Windows
# Tải từ https://git-scm.com/download/win

# Kiểm tra cài đặt
git --version
```

### Cấu hình Git
```bash
# Cấu hình user global
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Cấu hình user cho repository cụ thể
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Cấu hình editor mặc định
git config --global core.editor "vim"
git config --global core.editor "code --wait"  # VS Code

# Cấu hình line ending
git config --global core.autocrlf true    # Windows
git config --global core.autocrlf input   # macOS/Linux

# Xem cấu hình
git config --list
git config --global --list
git config user.name
```

### Cấu hình SSH
```bash
# Tạo SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"
ssh-keygen -t rsa -b 4096 -C "your.email@example.com"

# Thêm SSH key vào ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key để thêm vào GitHub/GitLab
cat ~/.ssh/id_ed25519.pub
# hoặc
clip < ~/.ssh/id_ed25519.pub  # Windows
pbcopy < ~/.ssh/id_ed25519.pub  # macOS

# Test SSH connection
ssh -T git@github.com
ssh -T git@gitlab.com
```

---

## 📁 Khởi tạo Repository

### Tạo repository mới
```bash
# Tạo repository local
git init
git init <directory-name>

# Clone repository từ remote
git clone <repository-url>
git clone <repository-url> <directory-name>
git clone --depth 1 <repository-url>  # Shallow clone

# Clone với SSH
git clone git@github.com:username/repository.git
git clone git@gitlab.com:username/repository.git
```

### Cấu hình repository
```bash
# Thêm remote origin
git remote add origin <repository-url>
git remote add origin git@github.com:username/repository.git

# Xem remote
git remote -v
git remote show origin

# Thay đổi remote URL
git remote set-url origin <new-url>
git remote set-url --push origin <new-url>

# Xóa remote
git remote remove origin
```

---

## 📝 Các lệnh cơ bản

### Kiểm tra trạng thái
```bash
# Xem trạng thái repository
git status
git status --short
git status --porcelain

# Xem lịch sử commit
git log
git log --oneline
git log --graph --oneline --all
git log --since="2 weeks ago"
git log --author="John Doe"
git log --grep="bug fix"

# Xem thay đổi
git diff
git diff --staged
git diff HEAD~1
git diff <commit1> <commit2>
```

### Thêm và commit
```bash
# Thêm file vào staging area
git add <file>
git add .                    # Thêm tất cả file
git add *.js                 # Thêm file theo pattern
git add -A                   # Thêm tất cả (bao gồm file đã xóa)

# Commit
git commit -m "Commit message"
git commit -am "Add and commit"  # Add và commit cùng lúc
git commit --amend               # Sửa commit cuối cùng
git commit --amend -m "New message"

# Xem thông tin commit
git show
git show <commit-hash>
```

### Undo và Reset
```bash
# Unstage file
git reset HEAD <file>
git reset HEAD .              # Unstage tất cả

# Undo commit (giữ thay đổi)
git reset --soft HEAD~1
git reset --mixed HEAD~1      # Mặc định

# Undo commit (xóa thay đổi)
git reset --hard HEAD~1
git reset --hard <commit-hash>

# Undo file về trạng thái trước đó
git checkout -- <file>
git restore <file>            # Git 2.23+
git restore --staged <file>   # Unstage file
```

---

## 🌿 Quản lý Branch

### Tạo và chuyển đổi branch
```bash
# Xem branch
git branch
git branch -a                 # Bao gồm remote branch
git branch -r                 # Chỉ remote branch

# Tạo branch mới
git branch <branch-name>
git checkout -b <branch-name> # Tạo và chuyển sang branch
git switch -c <branch-name>   # Git 2.23+

# Chuyển đổi branch
git checkout <branch-name>
git switch <branch-name>      # Git 2.23+

# Xóa branch
git branch -d <branch-name>   # Xóa local branch
git branch -D <branch-name>   # Force delete
git push origin --delete <branch-name>  # Xóa remote branch
```

### Merge branch
```bash
# Merge branch vào current branch
git merge <branch-name>
git merge --no-ff <branch-name>  # Tạo merge commit
git merge --squash <branch-name> # Squash tất cả commit thành 1

# Xem merge conflict
git status
git diff
git mergetool

# Giải quyết conflict
# 1. Sửa file conflict
# 2. git add <file>
# 3. git commit
```

### Rebase
```bash
# Rebase current branch lên branch khác
git rebase <branch-name>
git rebase -i HEAD~3          # Interactive rebase 3 commit cuối

# Rebase với conflict
git rebase --continue         # Tiếp tục sau khi giải quyết conflict
git rebase --abort            # Hủy rebase

# Rebase interactive
git rebase -i <commit-hash>
# pick: giữ commit
# reword: sửa message
# edit: sửa commit
# squash: gộp với commit trước
# drop: xóa commit
```

---

## 🔄 Merge và Rebase

### Merge strategies
```bash
# Fast-forward merge (mặc định)
git merge <branch-name>

# No-fast-forward merge
git merge --no-ff <branch-name>

# Squash merge
git merge --squash <branch-name>

# Merge với strategy
git merge -X ours <branch-name>    # Ưu tiên changes của chúng ta
git merge -X theirs <branch-name>  # Ưu tiên changes của branch kia
```

### Rebase strategies
```bash
# Rebase current branch
git rebase <base-branch>

# Rebase interactive
git rebase -i <start-commit>

# Rebase onto
git rebase --onto <new-base> <old-base> <branch>

# Rebase với preserve merges
git rebase --preserve-merges <branch>
```

---

## 🌐 Quản lý Remote

### Remote operations
```bash
# Xem remote
git remote -v
git remote show origin

# Thêm remote
git remote add <name> <url>
git remote add upstream <url>

# Fetch từ remote
git fetch
git fetch origin
git fetch <remote-name>

# Pull từ remote
git pull
git pull origin <branch-name>
git pull --rebase origin <branch-name>

# Push lên remote
git push
git push origin <branch-name>
git push -u origin <branch-name>  # Set upstream
git push --all origin             # Push tất cả branch
git push --tags origin            # Push tags
```

### Tracking branches
```bash
# Set upstream branch
git branch --set-upstream-to=origin/<branch> <local-branch>
git push -u origin <branch-name>

# Xem tracking info
git branch -vv

# Pull với rebase
git pull --rebase origin <branch-name>
```

---

## 💾 Stash và Clean

### Stash operations
```bash
# Stash changes
git stash
git stash push -m "Stash message"
git stash push <file>         # Stash specific file

# Xem stash list
git stash list

# Apply stash
git stash apply               # Apply stash cuối cùng
git stash apply stash@{0}     # Apply specific stash
git stash pop                 # Apply và xóa stash

# Xóa stash
git stash drop stash@{0}
git stash clear               # Xóa tất cả stash

# Tạo branch từ stash
git stash branch <branch-name> stash@{0}
```

### Clean operations
```bash
# Xem file sẽ bị xóa
git clean -n

# Xóa untracked files
git clean -f                  # Xóa files
git clean -fd                 # Xóa files và directories
git clean -fX                 # Xóa ignored files
git clean -fx                 # Xóa ignored files và untracked files
```

---

## 🪝 Git Hooks

### Pre-commit hooks
```bash
# Tạo pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# Chạy tests trước khi commit
npm test
EOF

chmod +x .git/hooks/pre-commit

# Pre-commit hook với linting
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# Lint code trước khi commit
npm run lint
if [ $? -ne 0 ]; then
    echo "Linting failed. Commit aborted."
    exit 1
fi
EOF
```

### Post-commit hooks
```bash
# Post-commit hook
cat > .git/hooks/post-commit << 'EOF'
#!/bin/sh
# Gửi notification sau khi commit
echo "Commit successful: $(git log -1 --pretty=format:'%h - %s')"
EOF

chmod +x .git/hooks/post-commit
```

### Client-side hooks
```bash
# Pre-push hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/sh
# Chạy tests trước khi push
npm run test:ci
if [ $? -ne 0 ]; then
    echo "Tests failed. Push aborted."
    exit 1
fi
EOF

chmod +x .git/hooks/pre-push
```

---

## 📦 Git Submodules

### Quản lý submodules
```bash
# Thêm submodule
git submodule add <repository-url> <path>
git submodule add https://github.com/user/repo.git lib/repo

# Clone repository với submodules
git clone --recursive <repository-url>
git clone <repository-url>
git submodule init
git submodule update

# Update submodules
git submodule update --remote
git submodule update --remote --merge

# Xóa submodule
git submodule deinit <path>
git rm <path>
rm -rf .git/modules/<path>
```

### Submodule commands
```bash
# Xem submodule status
git submodule status
git submodule foreach git status

# Update submodule
git submodule update --init --recursive

# Sync submodule URL
git submodule sync
```

---

## 📁 Git LFS (Large File Storage)

### Cài đặt và cấu hình
```bash
# Cài đặt Git LFS
# Ubuntu/Debian
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt-get install git-lfs

# macOS
brew install git-lfs

# Khởi tạo Git LFS
git lfs install

# Track file types
git lfs track "*.psd"
git lfs track "*.zip"
git lfs track "*.mp4"

# Xem tracked files
git lfs track
```

### LFS operations
```bash
# Migrate existing files
git lfs migrate import --include="*.psd"

# Xem LFS files
git lfs ls-files

# Pull LFS files
git lfs pull

# Prune LFS files
git lfs prune
```

---

## 🔧 Troubleshooting

### Common issues
```bash
# Xóa file khỏi Git nhưng giữ local
git rm --cached <file>
git rm --cached -r <directory>

# Xóa file đã commit
git filter-branch --force --index-filter \
'git rm --cached --ignore-unmatch <file>' \
--prune-empty --tag-name-filter cat -- --all

# Reset về commit cụ thể
git reset --hard <commit-hash>
git push --force-with-lease origin <branch-name>

# Recover deleted branch
git reflog
git checkout -b <branch-name> <commit-hash>

# Xóa commit cuối cùng (chưa push)
git reset --soft HEAD~1

# Undo merge
git reset --hard HEAD~1
```

### Debug commands
```bash
# Xem reflog
git reflog
git reflog show <branch-name>

# Xem commit details
git show <commit-hash>
git show --stat <commit-hash>

# Xem file history
git log --follow <file>
git log -p <file>

# Tìm commit theo message
git log --grep="bug fix"
git log --grep="feature" --oneline

# Tìm commit theo author
git log --author="John Doe"
git shortlog -sn  # Xem commit count theo author
```

### Conflict resolution
```bash
# Xem conflict files
git status

# Sử dụng merge tool
git mergetool

# Xem conflict markers
git diff

# Abort merge
git merge --abort

# Continue merge sau khi resolve
git add <resolved-files>
git commit
```

---

## 🔄 Git Workflows

### GitFlow
```bash
# Khởi tạo GitFlow
git flow init

# Feature branch
git flow feature start <feature-name>
git flow feature finish <feature-name>

# Release branch
git flow release start <version>
git flow release finish <version>

# Hotfix branch
git flow hotfix start <version>
git flow hotfix finish <version>
```

### GitHub Flow
```bash
# Tạo feature branch
git checkout -b feature/new-feature

# Work on feature
git add .
git commit -m "Add new feature"

# Push và tạo PR
git push origin feature/new-feature

# Merge PR trên GitHub
# Sau đó xóa local branch
git checkout main
git pull origin main
git branch -d feature/new-feature
```

### GitLab Flow
```bash
# Tương tự GitHub Flow nhưng với GitLab
git checkout -b feature/new-feature
git add .
git commit -m "Add new feature"
git push origin feature/new-feature

# Tạo Merge Request trên GitLab
# Merge MR trên GitLab
git checkout main
git pull origin main
git branch -d feature/new-feature
```

---

## 🛠️ Git Tools và Integrations

### Git GUI tools
```bash
# GitKraken
# Tải từ https://www.gitkraken.com/

# SourceTree
# Tải từ https://www.sourcetreeapp.com/

# VS Code Git integration
# Cài đặt GitLens extension

# Command line tools
git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
```

### CI/CD Integration
```bash
# GitHub Actions
# Tạo .github/workflows/ci.yml

# GitLab CI
# Tạo .gitlab-ci.yml

# Jenkins
# Cấu hình webhook từ Git repository

# Travis CI
# Tạo .travis.yml
```

### Git aliases
```bash
# Tạo aliases hữu ích
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'

# Aliases nâng cao
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
git config --global alias.amend 'commit --amend --no-edit'
git config --global alias.wip '!git add -A && git commit -m "WIP"'
```

---

## ✅ Best Practices

### Commit messages
```bash
# Format: type(scope): description
# Types: feat, fix, docs, style, refactor, test, chore

# Examples:
git commit -m "feat(auth): add OAuth2 login"
git commit -m "fix(api): resolve CORS issue"
git commit -m "docs(readme): update installation guide"
git commit -m "refactor(utils): simplify validation logic"
```

### Branch naming
```bash
# Feature branches
feature/user-authentication
feature/payment-integration

# Bug fix branches
bugfix/login-error
hotfix/security-patch

# Release branches
release/v1.2.0
release/v2.0.0-beta

# Hotfix branches
hotfix/critical-security-fix
```

### Repository structure
```bash
# .gitignore examples
# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/

# Java
*.class
*.jar
*.war
*.ear
target/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
```

### Security best practices
```bash
# Không commit sensitive data
git config --global core.autocrlf true
git config --global core.safecrlf true

# Sử dụng .gitignore
echo "config/secrets.json" >> .gitignore
echo "*.env" >> .gitignore

# Xóa sensitive data từ history
git filter-branch --force --index-filter \
'git rm --cached --ignore-unmatch config/secrets.json' \
--prune-empty --tag-name-filter cat -- --all
```

---

## 📚 Tài liệu tham khảo

- [Git Official Documentation](https://git-scm.com/doc)
- [Pro Git Book](https://git-scm.com/book)
- [GitHub Git Handbook](https://guides.github.com/introduction/git-handbook/)
- [GitLab Git Documentation](https://docs.gitlab.com/ee/gitlab-basics/)
- [Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials)

---

## 🎯 Quick Reference

### Most used commands
```bash
git status                    # Xem trạng thái
git add .                     # Thêm tất cả file
git commit -m "message"       # Commit với message
git push                      # Push lên remote
git pull                      # Pull từ remote
git checkout -b <branch>      # Tạo branch mới
git merge <branch>            # Merge branch
git log --oneline            # Xem lịch sử ngắn gọn
git diff                      # Xem thay đổi
git stash                     # Lưu tạm thời
```

### Emergency commands
```bash
git reset --hard HEAD         # Reset về commit cuối
git checkout -- <file>        # Undo file changes
git stash pop                 # Khôi phục stash
git reflog                    # Xem lịch sử hoạt động
git cherry-pick <commit>      # Copy commit từ branch khác
```

---

*Cập nhật lần cuối: $(date)*
